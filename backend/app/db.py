"""
db.py — Persistent database layer for BazaarSetu BPP.

Supports:
  1. PostgreSQL (Supabase / Render / Neon) via asyncpg (high concurrency)
  2. Local SQLite fallback via standard Python sqlite3 (zero-dependency)
  3. Supabase Storage for raw and studio craft images
  4. Seamless in-memory sync for instant Beckn response times (< 1s)
"""
import json
import logging
import os
import re
from typing import List, Optional
from urllib.parse import urlparse

import httpx

from app.config import get_settings
from app.schemas import ArtisanListingPayload

logger = logging.getLogger("bazaarsetu_bpp.db")

# Flag for asyncpg availability
try:
    import asyncpg
    HAS_ASYNCPG = True
except ImportError:
    asyncpg = None
    HAS_ASYNCPG = False

import sqlite3

_pool = None
_sqlite_path = None
_db_type = "memory"  # 'postgres', 'sqlite', or 'memory'


def _clean_postgres_url(raw_url: str) -> str:
    """Normalize postgresql+asyncpg:// or postgres:// to standard postgresql://."""
    url = raw_url.strip()
    url = re.sub(r"^postgres://", "postgresql://", url)
    url = re.sub(r"^postgresql\+asyncpg://", "postgresql://", url)
    return url


async def init_db() -> str:
    """
    Initialize database connection, provision tables, and apply migrations.
    Returns the active database type ('postgres', 'sqlite', or 'memory').
    """
    global _pool, _sqlite_path, _db_type
    settings = get_settings()
    db_url = (settings.database_url or "").strip()

    # Case 1: Supabase / PostgreSQL
    if (db_url.startswith("postgres://") or db_url.startswith("postgresql")) and HAS_ASYNCPG:
        clean_url = _clean_postgres_url(db_url)
        try:
            logger.info("Connecting to PostgreSQL database at %s...", clean_url.split("@")[-1])
            parsed_db_url = urlparse(clean_url)
            db_hostname = (parsed_db_url.hostname or "").lower()
            # Require SSL for any remote database host (Supabase, Render, Neon, AWS, etc.)
            ssl_mode = "require" if db_hostname and db_hostname not in ("localhost", "127.0.0.1") else None
            _pool = await asyncpg.create_pool(
                clean_url,
                min_size=1,
                max_size=5,
                timeout=20.0,
                ssl=ssl_mode,
                statement_cache_size=0,
            )
            async with _pool.acquire() as conn:
                # 1. Sellers table (ready for future seller profiles)
                await conn.execute("""
                    CREATE TABLE IF NOT EXISTS sellers (
                        seller_id TEXT PRIMARY KEY,
                        name TEXT NOT NULL,
                        phone TEXT,
                        cluster_name TEXT,
                        state TEXT,
                        upi_vpa TEXT,
                        created_at TIMESTAMPTZ DEFAULT NOW(),
                        updated_at TIMESTAMPTZ DEFAULT NOW()
                    );
                """)

                # 2. Main Artisan Listings table
                await conn.execute("""
                    CREATE TABLE IF NOT EXISTS artisan_listings (
                        catalog_id TEXT PRIMARY KEY,
                        seller_id TEXT DEFAULT 'default_artisan',
                        artisan_name TEXT NOT NULL,
                        cluster_name TEXT,
                        title_en TEXT NOT NULL,
                        title_hi TEXT,
                        description_en TEXT,
                        description_hi TEXT,
                        craft_category TEXT,
                        category_id TEXT,
                        dimensions TEXT,
                        floor_price DOUBLE PRECISION,
                        fair_price DOUBLE PRECISION,
                        premium_price DOUBLE PRECISION,
                        raw_image_url TEXT,
                        studio_image_url TEXT,
                        gallery_images JSONB DEFAULT '[]'::jsonb,
                        available_qty INTEGER DEFAULT 1,
                        status TEXT DEFAULT 'PUBLISHED',
                        payload JSONB NOT NULL,
                        created_at TIMESTAMPTZ DEFAULT NOW(),
                        updated_at TIMESTAMPTZ DEFAULT NOW()
                    );
                """)

                # 3. Non-destructive column additions for backwards compatibility
                await conn.execute("""
                    DO $$ 
                    BEGIN 
                        BEGIN
                            ALTER TABLE artisan_listings ADD COLUMN IF NOT EXISTS seller_id TEXT DEFAULT 'default_artisan';
                            ALTER TABLE artisan_listings ADD COLUMN IF NOT EXISTS raw_image_url TEXT;
                            ALTER TABLE artisan_listings ADD COLUMN IF NOT EXISTS gallery_images JSONB DEFAULT '[]'::jsonb;
                        EXCEPTION
                            WHEN duplicate_column THEN null;
                        END;
                    END $$;
                """)

            _db_type = "postgres"
            logger.info("✓ PostgreSQL schema and migrations verified on Supabase")
            return _db_type
        except Exception as e:
            logger.error(
                "Failed to connect to PostgreSQL (%s: %s). Falling back to SQLite.",
                type(e).__name__,
                e,
            )
            parsed = urlparse(clean_url)
            host = (parsed.hostname or "").lower()
            if host.startswith("db.") and host.endswith(".supabase.co"):
                logger.warning(
                    "💡 Render / Cloud Notice: Host '%s' uses IPv6-only routing. "
                    "Render free instances cannot reach IPv6 endpoints. "
                    "Please use the Supabase Connection Pooler (IPv4) URI instead: "
                    "e.g. postgresql://postgres.[YOUR-PROJECT-REF]:[PASSWORD]@aws-0-[REGION].pooler.supabase.com:6543/postgres",
                    host,
                )

    # Case 2: SQLite
    try:
        if db_url.startswith("sqlite"):
            path = re.sub(r"^sqlite:\/{2,3}", "", db_url)
            if not path or path == ".":
                path = "bazaarsetu.db"
        else:
            path = "bazaarsetu.db"

        _sqlite_path = path
        conn = sqlite3.connect(_sqlite_path)
        with conn:
            conn.execute("""
                CREATE TABLE IF NOT EXISTS sellers (
                    seller_id TEXT PRIMARY KEY,
                    name TEXT NOT NULL,
                    phone TEXT,
                    cluster_name TEXT,
                    state TEXT,
                    upi_vpa TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                );
            """)
            conn.execute("""
                CREATE TABLE IF NOT EXISTS artisan_listings (
                    catalog_id TEXT PRIMARY KEY,
                    seller_id TEXT DEFAULT 'default_artisan',
                    artisan_name TEXT NOT NULL,
                    cluster_name TEXT,
                    title_en TEXT NOT NULL,
                    title_hi TEXT,
                    description_en TEXT,
                    description_hi TEXT,
                    craft_category TEXT,
                    category_id TEXT,
                    dimensions TEXT,
                    floor_price REAL,
                    fair_price REAL,
                    premium_price REAL,
                    raw_image_url TEXT,
                    studio_image_url TEXT,
                    gallery_images TEXT DEFAULT '[]',
                    available_qty INTEGER DEFAULT 1,
                    status TEXT DEFAULT 'PUBLISHED',
                    payload TEXT NOT NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                );
            """)
        conn.close()
        _db_type = "sqlite"
        logger.info("✓ SQLite database initialized at %s", _sqlite_path)
        return _db_type
    except Exception as e:
        logger.error("Failed to initialize SQLite (%s). Falling back to memory-only.", e)
        _db_type = "memory"
        return _db_type


async def save_listing_db(listing: ArtisanListingPayload, status: str = "PUBLISHED") -> None:
    """Persist listing payload to the active database (Postgres or SQLite)."""
    global _pool, _sqlite_path, _db_type
    payload_dict = listing.model_dump()
    payload_json = json.dumps(payload_dict)
    gallery_json = json.dumps(listing.gallery_images)

    if _db_type == "postgres" and _pool:
        try:
            async with _pool.acquire() as conn:
                await conn.execute("""
                    INSERT INTO artisan_listings (
                        catalog_id, seller_id, artisan_name, cluster_name, title_en, title_hi,
                        description_en, description_hi, craft_category, category_id,
                        dimensions, floor_price, fair_price, premium_price,
                        raw_image_url, studio_image_url, gallery_images, available_qty, status, payload, updated_at
                    ) VALUES (
                        $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17::jsonb, $18, $19, $20::jsonb, NOW()
                    )
                    ON CONFLICT (catalog_id) DO UPDATE SET
                        seller_id = EXCLUDED.seller_id,
                        artisan_name = EXCLUDED.artisan_name,
                        cluster_name = EXCLUDED.cluster_name,
                        title_en = EXCLUDED.title_en,
                        title_hi = EXCLUDED.title_hi,
                        description_en = EXCLUDED.description_en,
                        description_hi = EXCLUDED.description_hi,
                        craft_category = EXCLUDED.craft_category,
                        category_id = EXCLUDED.category_id,
                        dimensions = EXCLUDED.dimensions,
                        floor_price = EXCLUDED.floor_price,
                        fair_price = EXCLUDED.fair_price,
                        premium_price = EXCLUDED.premium_price,
                        raw_image_url = EXCLUDED.raw_image_url,
                        studio_image_url = EXCLUDED.studio_image_url,
                        gallery_images = EXCLUDED.gallery_images,
                        available_qty = EXCLUDED.available_qty,
                        status = EXCLUDED.status,
                        payload = EXCLUDED.payload,
                        updated_at = NOW();
                """,
                    listing.catalog_id,
                    listing.seller_id,
                    listing.artisan_name,
                    listing.cluster_name,
                    listing.title_en,
                    listing.title_hi,
                    listing.description_en,
                    listing.description_hi,
                    listing.craft_category,
                    listing.category_id,
                    listing.dimensions,
                    float(listing.floor_price),
                    float(listing.fair_price),
                    float(listing.premium_price),
                    listing.raw_image_url,
                    listing.studio_image_url,
                    gallery_json,
                    int(listing.available_qty),
                    status,
                    payload_json,
                )
            logger.info("Saved listing %s to PostgreSQL (Supabase)", listing.catalog_id)
            return
        except Exception as e:
            logger.error("PostgreSQL save failed for %s: %s", listing.catalog_id, e)

    if _db_type == "sqlite" and _sqlite_path:
        try:
            conn = sqlite3.connect(_sqlite_path)
            with conn:
                conn.execute("""
                    INSERT INTO artisan_listings (
                        catalog_id, seller_id, artisan_name, cluster_name, title_en, title_hi,
                        description_en, description_hi, craft_category, category_id,
                        dimensions, floor_price, fair_price, premium_price,
                        raw_image_url, studio_image_url, gallery_images, available_qty, status, payload, updated_at
                    ) VALUES (
                        ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP
                    )
                    ON CONFLICT (catalog_id) DO UPDATE SET
                        seller_id = excluded.seller_id,
                        artisan_name = excluded.artisan_name,
                        cluster_name = excluded.cluster_name,
                        title_en = excluded.title_en,
                        title_hi = excluded.title_hi,
                        description_en = excluded.description_en,
                        description_hi = excluded.description_hi,
                        craft_category = excluded.craft_category,
                        category_id = excluded.category_id,
                        dimensions = excluded.dimensions,
                        floor_price = excluded.floor_price,
                        fair_price = excluded.fair_price,
                        premium_price = excluded.premium_price,
                        raw_image_url = excluded.raw_image_url,
                        studio_image_url = excluded.studio_image_url,
                        gallery_images = excluded.gallery_images,
                        available_qty = excluded.available_qty,
                        status = excluded.status,
                        payload = excluded.payload,
                        updated_at = CURRENT_TIMESTAMP;
                """, (
                    listing.catalog_id,
                    listing.seller_id,
                    listing.artisan_name,
                    listing.cluster_name,
                    listing.title_en,
                    listing.title_hi,
                    listing.description_en,
                    listing.description_hi,
                    listing.craft_category,
                    listing.category_id,
                    listing.dimensions,
                    float(listing.floor_price),
                    float(listing.fair_price),
                    float(listing.premium_price),
                    listing.raw_image_url,
                    listing.studio_image_url,
                    gallery_json,
                    int(listing.available_qty),
                    status,
                    payload_json,
                ))
            conn.close()
            logger.info("Saved listing %s to SQLite", listing.catalog_id)
            return
        except Exception as e:
            logger.error("SQLite save failed for %s: %s", listing.catalog_id, e)


async def load_all_listings_db() -> List[ArtisanListingPayload]:
    """Retrieve all published listings from the database."""
    rows = await load_listings_with_status_db(include_drafts=False)
    return [ArtisanListingPayload(**row["payload"]) for row in rows]


async def load_listings_with_status_db(include_drafts: bool = False) -> List[dict]:
    """Retrieve listings from the database along with status and timestamps."""
    global _pool, _sqlite_path, _db_type
    results: List[dict] = []
    status_filter = "" if include_drafts else "WHERE status = 'PUBLISHED'"

    if _db_type == "postgres" and _pool:
        try:
            async with _pool.acquire() as conn:
                rows = await conn.fetch(f"""
                    SELECT payload, status, created_at, updated_at
                    FROM artisan_listings
                    {status_filter}
                    ORDER BY updated_at ASC;
                """)
                for row in rows:
                    raw_payload = row["payload"]
                    data = json.loads(raw_payload) if isinstance(raw_payload, str) else raw_payload
                    results.append({
                        "payload": data,
                        "status": row["status"],
                        "created_at": row["created_at"].isoformat() if row["created_at"] else None,
                        "updated_at": row["updated_at"].isoformat() if row["updated_at"] else None,
                    })
            return results
        except Exception as e:
            logger.error("PostgreSQL fetch failed: %s", e)

    if _db_type == "sqlite" and _sqlite_path:
        try:
            conn = sqlite3.connect(_sqlite_path)
            cursor = conn.cursor()
            cursor.execute(f"""
                SELECT payload, status, created_at, updated_at
                FROM artisan_listings
                {status_filter}
                ORDER BY updated_at ASC;
            """)
            for row in cursor.fetchall():
                data = json.loads(row[0])
                results.append({
                    "payload": data,
                    "status": row[1],
                    "created_at": row[2],
                    "updated_at": row[3],
                })
            conn.close()
            return results
        except Exception as e:
            logger.error("SQLite fetch failed: %s", e)

    return results


async def get_listing_media_db(catalog_id: str) -> Optional[dict]:
    """Fetch image URLs for a listing before deleting its row."""
    global _pool, _sqlite_path, _db_type

    if _db_type == "postgres" and _pool:
        try:
            async with _pool.acquire() as conn:
                row = await conn.fetchrow(
                    """
                    SELECT raw_image_url, studio_image_url, gallery_images
                    FROM artisan_listings WHERE catalog_id = $1;
                    """,
                    catalog_id,
                )
                if not row:
                    return None
                gallery = row["gallery_images"]
                if isinstance(gallery, str):
                    gallery = json.loads(gallery)
                return {
                    "raw_image_url": row["raw_image_url"],
                    "studio_image_url": row["studio_image_url"],
                    "gallery_images": gallery or [],
                }
        except Exception as e:
            logger.error("PostgreSQL media lookup failed for %s: %s", catalog_id, e)

    if _db_type == "sqlite" and _sqlite_path:
        try:
            conn = sqlite3.connect(_sqlite_path)
            cur = conn.execute(
                """
                SELECT raw_image_url, studio_image_url, gallery_images
                FROM artisan_listings WHERE catalog_id = ?;
                """,
                (catalog_id,),
            )
            row = cur.fetchone()
            conn.close()
            if not row:
                return None
            gallery = json.loads(row[2]) if isinstance(row[2], str) and row[2] else []
            return {
                "raw_image_url": row[0],
                "studio_image_url": row[1],
                "gallery_images": gallery,
            }
        except Exception as e:
            logger.error("SQLite media lookup failed for %s: %s", catalog_id, e)

    return None


def extract_storage_object(public_url: Optional[str]) -> Optional[tuple[str, str]]:
    """Extract (bucket, object_path) from a Supabase Storage public URL."""
    if not public_url or "/storage/v1/object/public/" not in public_url:
        return None
    tail = public_url.split("/storage/v1/object/public/", 1)[1]
    parts = tail.split("/", 1)
    if len(parts) != 2 or not parts[0] or not parts[1]:
        return None
    return parts[0], parts[1].split("?", 1)[0]


async def delete_listing_storage_objects(
    catalog_id: str,
    media: Optional[dict] = None,
) -> int:
    """
    Remove all raw, studio, and gallery images associated with [catalog_id]
    from Supabase Storage buckets and local /uploads fallback directories.
    """
    removed_count = 0

    # 1. Remove local fallback files if present
    for sub_dir in ("raw", "processed"):
        folder = os.path.join("uploads", sub_dir)
        if os.path.isdir(folder):
            for fname in os.listdir(folder):
                if fname.startswith(f"{catalog_id}_"):
                    try:
                        os.remove(os.path.join(folder, fname))
                        removed_count += 1
                    except OSError:
                        pass

    settings = get_settings()
    if not settings.supabase_url or not settings.supabase_key:
        return removed_count

    base = settings.supabase_url.rstrip("/")
    headers = {
        "Authorization": f"Bearer {settings.supabase_key}",
        "apiKey": settings.supabase_key,
        "Content-Type": "application/json",
    }

    bucket_objects: dict[str, set[str]] = {
        settings.supabase_raw_bucket: set(),
        settings.supabase_processed_bucket: set(),
    }

    if media:
        urls = [
            media.get("raw_image_url"),
            media.get("studio_image_url"),
            *(media.get("raw_gallery_images") or []),
            *(media.get("gallery_images") or []),
        ]
        for u in urls:
            parsed = extract_storage_object(u)
            if parsed:
                bucket_objects.setdefault(parsed[0], set()).add(parsed[1])

    try:
        async with httpx.AsyncClient(timeout=15.0) as client:
            # Also find any objects prefixed with catalog_id in both buckets
            for bucket in list(bucket_objects.keys()):
                try:
                    list_res = await client.post(
                        f"{base}/storage/v1/object/list/{bucket}",
                        json={"prefix": f"{catalog_id}_", "limit": 100},
                        headers=headers,
                    )
                    if list_res.status_code == 200:
                        for entry in list_res.json():
                            name = entry.get("name")
                            if name:
                                bucket_objects[bucket].add(name)
                except Exception as e:
                    logger.warning("Storage list skipped for %s/%s: %s", bucket, catalog_id, e)

            # Delete collected objects per bucket
            for bucket, prefixes in bucket_objects.items():
                if not prefixes:
                    continue
                try:
                    del_res = await client.request(
                        "DELETE",
                        f"{base}/storage/v1/object/{bucket}",
                        json={"prefixes": sorted(prefixes)},
                        headers=headers,
                    )
                    if del_res.status_code in (200, 204):
                        removed_count += len(prefixes)
                        logger.info(
                            "Deleted %d storage object(s) from bucket '%s' for %s",
                            len(prefixes),
                            bucket,
                            catalog_id,
                        )
                except Exception as e:
                    logger.warning("Storage delete failed for %s/%s: %s", bucket, catalog_id, e)
    except Exception as e:
        logger.error("Failed to clean Supabase Storage for %s: %s", catalog_id, e)

    return removed_count


async def delete_listing_db(catalog_id: str) -> bool:
    """Delete a listing from the database by catalog_id."""
    global _pool, _sqlite_path, _db_type

    if _db_type == "postgres" and _pool:
        try:
            async with _pool.acquire() as conn:
                res = await conn.execute(
                    "DELETE FROM artisan_listings WHERE catalog_id = $1;",
                    catalog_id,
                )
                return "DELETE 1" in res
        except Exception as e:
            logger.error("PostgreSQL delete failed for %s: %s", catalog_id, e)

    if _db_type == "sqlite" and _sqlite_path:
        try:
            conn = sqlite3.connect(_sqlite_path)
            with conn:
                cur = conn.execute(
                    "DELETE FROM artisan_listings WHERE catalog_id = ?;",
                    (catalog_id,),
                )
                affected = cur.rowcount
            conn.close()
            return affected > 0
        except Exception as e:
            logger.error("SQLite delete failed for %s: %s", catalog_id, e)

    return False


async def update_listing_status_db(catalog_id: str, new_status: str) -> bool:
    """Update listing status (e.g. 'DRAFT', 'UNLISTED', 'PUBLISHED')."""
    global _pool, _sqlite_path, _db_type

    if _db_type == "postgres" and _pool:
        try:
            async with _pool.acquire() as conn:
                res = await conn.execute(
                    "UPDATE artisan_listings SET status = $1, updated_at = NOW() WHERE catalog_id = $2;",
                    new_status, catalog_id,
                )
                return "UPDATE 1" in res
        except Exception as e:
            logger.error("PostgreSQL status update failed for %s: %s", catalog_id, e)

    if _db_type == "sqlite" and _sqlite_path:
        try:
            conn = sqlite3.connect(_sqlite_path)
            with conn:
                cur = conn.execute(
                    "UPDATE artisan_listings SET status = ?, updated_at = CURRENT_TIMESTAMP WHERE catalog_id = ?;",
                    (new_status, catalog_id),
                )
                affected = cur.rowcount
            conn.close()
            return affected > 0
        except Exception as e:
            logger.error("SQLite status update failed for %s: %s", catalog_id, e)

    return False


def resolve_storage_bucket(image_type: str = "studio", bucket: Optional[str] = None) -> str:
    """Resolve target Supabase Storage bucket: raw vs AI-processed."""
    if bucket:
        return bucket
    settings = get_settings()
    normalized = (image_type or "").strip().lower()
    if normalized == "raw" or normalized.startswith("raw_"):
        return settings.supabase_raw_bucket
    return settings.supabase_processed_bucket


async def _ensure_bucket_exists(
    client: httpx.AsyncClient,
    supabase_url: str,
    supabase_key: str,
    bucket: str,
) -> bool:
    """Attempt to create a public Supabase Storage bucket if it does not exist."""
    create_url = f"{supabase_url.rstrip('/')}/storage/v1/bucket"
    headers = {
        "Authorization": f"Bearer {supabase_key}",
        "apiKey": supabase_key,
        "Content-Type": "application/json",
    }
    try:
        res = await client.post(
            create_url,
            json={"id": bucket, "name": bucket, "public": True},
            headers=headers,
        )
        return res.status_code in (200, 201, 409)
    except Exception as e:
        logger.warning("Could not auto-create Supabase bucket %s: %s", bucket, e)
        return False


async def upload_image_to_storage(
    content: bytes,
    filename: str,
    content_type: str = "image/jpeg",
    bucket: Optional[str] = None,
    image_type: str = "studio",
) -> Optional[str]:
    """
    Upload image directly to the appropriate Supabase Storage bucket
    (raw-craft-images vs processed-craft-images) and return its public CDN URL.
    Returns None if Supabase Storage is not configured.
    """
    settings = get_settings()
    if not settings.supabase_url or not settings.supabase_key:
        return None

    target_bucket = resolve_storage_bucket(image_type=image_type, bucket=bucket)
    base = settings.supabase_url.rstrip("/")
    upload_url = f"{base}/storage/v1/object/{target_bucket}/{filename}"
    headers = {
        "Authorization": f"Bearer {settings.supabase_key}",
        "apiKey": settings.supabase_key,
        "Content-Type": content_type,
        "x-upsert": "true",
    }

    try:
        async with httpx.AsyncClient(timeout=15.0) as client:
            res = await client.post(upload_url, content=content, headers=headers)
            if res.status_code in (400, 404) and "not found" in res.text.lower():
                if await _ensure_bucket_exists(client, base, settings.supabase_key, target_bucket):
                    res = await client.post(upload_url, content=content, headers=headers)

            if res.status_code in (200, 201):
                public_url = f"{base}/storage/v1/object/public/{target_bucket}/{filename}"
                logger.info(
                    "Uploaded %s to Supabase Storage bucket '%s': %s",
                    filename,
                    target_bucket,
                    public_url,
                )
                return public_url
            else:
                logger.warning(
                    "Supabase Storage upload to '%s' returned HTTP %d: %s",
                    target_bucket,
                    res.status_code,
                    res.text,
                )
                return None
    except Exception as e:
        logger.error("Failed to upload image to Supabase Storage: %s", e)
        return None


async def close_db() -> None:
    """Gracefully close database connection pools."""
    global _pool
    if _pool:
        await _pool.close()
        logger.info("Closed PostgreSQL pool")
