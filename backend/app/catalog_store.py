"""
catalog_store.py — Catalog store for active artisan listings with persistent DB backing.

Design:
  - An in-memory dict keyed by catalog_id provides instantaneous, zero-latency
    response times (<1ms) for high-concurrency Beckn discovery /search requests.
  - Automatically backed by PostgreSQL (Supabase) or SQLite via app.db.
  - Pre-loads default Chanderi Silk Dupatta entry if DB is empty so Workbench
    and curl tests work out-of-the-box.
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
# Default demo listing — Chanderi Silk Dupatta
# Pre-loaded so Workbench / curl tests work out-of-the-box.
# ─────────────────────────────────────────────────────────────────────────────

_DEFAULT_LISTING = ArtisanListingPayload(
    catalog_id="cat_chanderi_001",
    artisan_name="Ramesh Kumar",
    cluster_name="Chanderi Handloom Cluster",
    gps_coordinates="24.7118,78.1098",
    area_code="473446",
    title_en="Handwoven Chanderi Silk Dupatta with Gold Zari Border",
    title_hi="हाथ से बुनी चंदेरी सिल्क दुपट्टा, सोने की ज़री बॉर्डर के साथ",
    description_en=(
        "Exquisite authentic Chanderi dupatta handwoven on traditional pit looms "
        "using pure mulberry silk and 24-carat gold Zari thread. Each piece "
        "takes 5 days of skilled artisan labour and represents a 500-year-old "
        "weaving heritage from Chanderi, Madhya Pradesh. The lightweight, "
        "semi-translucent fabric with characteristic Chanderi butti motifs makes "
        "it ideal for festive occasions and formal wear."
    ),
    description_hi=(
        "पारंपरिक गड्ढा करघे पर बुनी गई उत्कृष्ट चंदेरी सिल्क दुपट्टा। "
        "शुद्ध मलबेरी सिल्क और 24 कैरेट सोने की ज़री धागे से बनी इस दुपट्टा में "
        "500 साल पुरानी बुनाई की परंपरा झलकती है।"
    ),
    craft_category="Handloom Silk",
    category_id="ONDC:RET12",
    materials=["Pure Mulberry Silk", "Gold Zari"],
    dimensions="6.2 meters",
    floor_price=1760.0,
    fair_price=2640.0,
    premium_price=3168.0,
    studio_image_url="https://images.unsplash.com/photo-1610030469983-98e550d6193c",
    available_qty=4,
)

# ─────────────────────────────────────────────────────────────────────────────
# In-memory store — dict[catalog_id → ArtisanListingPayload]
# ─────────────────────────────────────────────────────────────────────────────

_ACTIVE_LISTINGS: Dict[str, ArtisanListingPayload] = {
    _DEFAULT_LISTING.catalog_id: _DEFAULT_LISTING,
}


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
            # Seed the default demo item if database has no records yet
            _ACTIVE_LISTINGS = {_DEFAULT_LISTING.catalog_id: _DEFAULT_LISTING}
            await save_listing_db(_DEFAULT_LISTING, status="PUBLISHED")
            logger.info("Database was empty; seeded default demo listing into DB and memory.")
    except Exception as e:
        logger.warning("Could not populate listings from DB: %s. Using default listing.", e)
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
    """
    Return the most recently added listing.

    Falls back to the pre-loaded Chanderi Silk entry if the store is
    empty.
    """
    if not _ACTIVE_LISTINGS:
        return _DEFAULT_LISTING
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
