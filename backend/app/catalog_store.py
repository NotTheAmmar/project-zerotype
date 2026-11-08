"""
catalog_store.py — Catalog store for active artisan listings with persistent DB backing.

Design:
  - An in-memory dict keyed by catalog_id provides instantaneous, zero-latency
    response times (<1ms) for high-concurrency Beckn discovery /search requests.
  - Automatically backed by PostgreSQL (Supabase) or SQLite via app.db.
  - Loads active artisan listings from database on startup.
"""
import logging
from typing import Dict, List, Optional

from app.db import (
    delete_listing_db,
    load_all_listings_db,
    save_listing_db,
    update_listing_status_db,
)
from app.schemas import ArtisanListingPayload

logger = logging.getLogger("bazaarsetu_bpp.catalog_store")


# ─────────────────────────────────────────────────────────────────────────────
# In-memory store — dict[catalog_id → ArtisanListingPayload]
# ─────────────────────────────────────────────────────────────────────────────

_ACTIVE_LISTINGS: Dict[str, ArtisanListingPayload] = {}


# ─────────────────────────────────────────────────────────────────────────────
# Public API
# ─────────────────────────────────────────────────────────────────────────────


async def populate_from_db() -> int:
    """
    Load all active listings from the persistent database into the memory store.
    Called once during FastAPI lifespan startup.
    """
    global _ACTIVE_LISTINGS
    try:
        listings = await load_all_listings_db()
        if listings:
            _ACTIVE_LISTINGS = {item.catalog_id: item for item in listings}
            logger.info("Loaded %d listing(s) from persistent database into memory.", len(listings))
        else:
            _ACTIVE_LISTINGS = {}
            logger.info("Database has no listings yet. Ready for artisan uploads.")
    except Exception as e:
        logger.warning("Could not populate listings from DB: %s", e)
        _ACTIVE_LISTINGS = {}
    return len(_ACTIVE_LISTINGS)


def save_active_listing(payload: ArtisanListingPayload) -> None:
    """Synchronous memory cache update (preserves backwards-compat)."""
    _ACTIVE_LISTINGS[payload.catalog_id] = payload


async def save_active_listing_async(
    payload: ArtisanListingPayload,
    status: str = "PUBLISHED",
) -> None:
    """Upsert a listing in both the memory cache and persistent database."""
    _ACTIVE_LISTINGS[payload.catalog_id] = payload
    try:
        await save_listing_db(payload, status=status)
    except Exception as e:
        logger.error("Failed to persist listing %s to DB: %s", payload.catalog_id, e)


def get_latest_listing() -> Optional[ArtisanListingPayload]:
    """Return the most recently added listing, or None if store is empty."""
    if not _ACTIVE_LISTINGS:
        return None
    return list(_ACTIVE_LISTINGS.values())[-1]


def get_all_listings() -> List[ArtisanListingPayload]:
    """Return all active listings (newest last)."""
    return list(_ACTIVE_LISTINGS.values())


def get_listing_by_id(catalog_id: str) -> Optional[ArtisanListingPayload]:
    """Look up a specific listing by its catalog_id."""
    return _ACTIVE_LISTINGS.get(catalog_id)


def delete_listing(catalog_id: str) -> bool:
    """Remove a listing from memory cache synchronously."""
    if catalog_id in _ACTIVE_LISTINGS:
        del _ACTIVE_LISTINGS[catalog_id]
        return True
    return False


async def delete_listing_async(catalog_id: str) -> bool:
    """Remove a listing from both memory cache and persistent database."""
    in_mem = delete_listing(catalog_id)
    in_db = False
    try:
        in_db = await delete_listing_db(catalog_id)
    except Exception as e:
        logger.error("Failed to delete listing %s from DB: %s", catalog_id, e)
    return in_mem or in_db


async def unlist_listing_async(catalog_id: str) -> bool:
    """Mark a listing as UNLISTED/DRAFT in DB and remove from active Beckn search."""
    delete_listing(catalog_id)
    try:
        return await update_listing_status_db(catalog_id, "UNLISTED")
    except Exception as e:
        logger.error("Failed to unlist %s in DB: %s", catalog_id, e)
        return False


def listing_count() -> int:
    """Return the number of active listings (useful for health checks)."""
    return len(_ACTIVE_LISTINGS)
