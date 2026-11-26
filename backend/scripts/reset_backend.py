#!/usr/bin/env python3
"""
reset_backend.py — Standalone testing utility to reset Supabase DB, SQLite DB,
Supabase Storage buckets, and local uploads without exposing reset controls in
the mobile app.

Usage (from backend/ directory):
    python scripts/reset_backend.py --yes
    python scripts/reset_backend.py --db-only --yes
    python scripts/reset_backend.py --storage-only --yes
"""
import argparse
import asyncio
import os
import shutil
import sqlite3
import sys
from pathlib import Path

import httpx

# Allow running from repo root or backend/
BACKEND_DIR = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(BACKEND_DIR))

from app.config import get_settings  # noqa: E402
from app.db import _clean_postgres_url  # noqa: E402


async def reset_postgres(database_url: str) -> None:
    """Truncate artisan_listings and sellers in PostgreSQL (Supabase)."""
    import asyncpg

    clean_url = _clean_postgres_url(database_url)
    conn = await asyncpg.connect(clean_url, statement_cache_size=0)
    try:
        await conn.execute("DELETE FROM artisan_listings;")
        await conn.execute("DELETE FROM sellers;")
        print("✓ Cleared PostgreSQL tables (artisan_listings, sellers)")
    finally:
        await conn.close()


def reset_sqlite(db_path: Path) -> None:
    """Clear local SQLite database tables if the file exists."""
    if not db_path.exists():
        print(f"- SQLite file not found at {db_path}, skipping")
        return
    conn = sqlite3.connect(str(db_path))
    try:
        with conn:
            conn.execute("DELETE FROM artisan_listings;")
            conn.execute("DELETE FROM sellers;")
        print(f"✓ Cleared SQLite database at {db_path}")
    finally:
        conn.close()


async def empty_supabase_bucket(
    client: httpx.AsyncClient,
    base_url: str,
    api_key: str,
    bucket: str,
) -> None:
    """List and delete all objects inside a Supabase Storage bucket."""
    headers = {
        "Authorization": f"Bearer {api_key}",
        "apiKey": api_key,
        "Content-Type": "application/json",
    }
    list_url = f"{base_url}/storage/v1/object/list/{bucket}"
    res = await client.post(list_url, json={"prefix": "", "limit": 1000}, headers=headers)
    if res.status_code != 200:
        print(f"- Bucket '{bucket}' skipped (HTTP {res.status_code}: {res.text})")
        return

    items = res.json()
    if not isinstance(items, list) or not items:
        print(f"✓ Bucket '{bucket}' is already empty")
        return

    paths = [item["name"] for item in items if isinstance(item, dict) and item.get("name")]
    if not paths:
        print(f"✓ Bucket '{bucket}' has no removable objects")
        return

    del_url = f"{base_url}/storage/v1/object/{bucket}"
    del_res = await client.request("DELETE", del_url, json={"prefixes": paths}, headers=headers)
    if del_res.status_code in (200, 204):
        print(f"✓ Emptied {len(paths)} object(s) from bucket '{bucket}'")
    else:
        print(f"! Failed clearing bucket '{bucket}' (HTTP {del_res.status_code}: {del_res.text})")


async def reset_storage(supabase_url: str, supabase_key: str, buckets: list[str]) -> None:
    """Empty configured Supabase Storage buckets and local uploads directory."""
    if supabase_url and supabase_key:
        base = supabase_url.rstrip("/")
        async with httpx.AsyncClient(timeout=20.0) as client:
            for bucket in dict.fromkeys(buckets):
                await empty_supabase_bucket(client, base, supabase_key, bucket)
    else:
        print("- SUPABASE_URL / SUPABASE_KEY not configured, skipping remote storage")

    uploads_dir = BACKEND_DIR / "uploads"
    if uploads_dir.exists():
        for entry in uploads_dir.iterdir():
            if entry.is_dir():
                shutil.rmtree(entry)
            else:
                entry.unlink()
        print(f"✓ Cleared local uploads directory at {uploads_dir}")


async def main() -> None:
    parser = argparse.ArgumentParser(description="Reset BazaarSetu Supabase & backend test state.")
    parser.add_argument("--db-only", action="store_true", help="Only reset database tables.")
    parser.add_argument("--storage-only", action="store_true", help="Only clear storage buckets and uploads.")
    parser.add_argument("-y", "--yes", action="store_true", help="Skip confirmation prompt.")
    args = parser.parse_args()

    os.chdir(BACKEND_DIR)
    settings = get_settings()

    if not args.yes:
        ans = input("This will DELETE all listings and images in Supabase/backend. Continue? [y/N]: ")
        if ans.strip().lower() not in ("y", "yes"):
            print("Aborted.")
            return

    do_db = not args.storage_only
    do_storage = not args.db_only

    if do_db:
        db_url = (settings.database_url or "").strip()
        if db_url.startswith("postgres://") or db_url.startswith("postgresql"):
            await reset_postgres(db_url)
        reset_sqlite(BACKEND_DIR / "bazaarsetu.db")

    if do_storage:
        buckets = [
            settings.supabase_raw_bucket,
            settings.supabase_processed_bucket,
            settings.supabase_storage_bucket,
        ]
        await reset_storage(settings.supabase_url, settings.supabase_key, buckets)

    print("Done. Note: Restart uvicorn if running so the in-memory catalog cache reloads.")


if __name__ == "__main__":
    asyncio.run(main())
