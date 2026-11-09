"""
app_routes.py — Mobile app integration endpoints.

These routes are called by the Flutter mobile app (not the ONDC network).
They form the bridge between the artisan's device and the BPP catalog store.

Endpoints:
  POST   /api/v1/bpp/publish             — Flutter publishes a completed listing
  GET    /api/v1/bpp/listings            — Fetch all active listings (admin / Workbench)
  GET    /api/v1/bpp/listings/{catalog_id} — Fetch a single listing by ID
  DELETE /api/v1/bpp/listings/{catalog_id} — Remove a listing from ONDC and DB
  POST   /api/v1/bpp/listings/{catalog_id}/unlist — Revert listing to draft/unlisted
  GET    /api/v1/bpp/health              — Quick count for monitoring
"""
import os
import re
from typing import Optional
from uuid import uuid4

from fastapi import APIRouter, File, Form, HTTPException, Request, UploadFile, status

from app.catalog_store import (
    delete_listing_async,
    get_all_listings,
    get_listing_by_id,
    listing_count,
    save_active_listing_async,
    unlist_listing_async,
)
from app.db import upload_image_to_storage
from app.schemas import ArtisanListingPayload

router = APIRouter(prefix="/api/v1/bpp", tags=["Artisan App"])


# ─────────────────────────────────────────────────────────────────────────────
# Image Upload (Supabase Storage + CDN)
# ─────────────────────────────────────────────────────────────────────────────


@router.post("/upload-image", status_code=status.HTTP_200_OK)
async def upload_image(
    request: Request,
    file: UploadFile = File(...),
    catalog_id: Optional[str] = Form(None),
    image_type: str = Form("studio"),
) -> dict:
    """
    Upload craft photos (raw camera photo or AI studio image) to Supabase Storage.
    Returns the public HTTPS CDN URL needed for ONDC Buyer Apps.
    Falls back to local static file serving if Supabase Storage is not configured.
    """
    content = await file.read()
    content_type = file.content_type or "image/jpeg"
    ext = "jpg"
    if "png" in content_type:
        ext = "png"
    elif "webp" in content_type:
        ext = "webp"

    cid = re.sub(r"[^a-zA-Z0-9_-]", "", catalog_id) if catalog_id else f"craft_{uuid4().hex[:10]}"
    if not cid:
        cid = f"craft_{uuid4().hex[:10]}"
    safe_type = re.sub(r"[^a-zA-Z0-9_-]", "", image_type)
    if not safe_type:
        safe_type = "studio"
    filename = f"{cid}_{safe_type}.{ext}"

    # 1. Try Supabase Storage CDN
    public_url = await upload_image_to_storage(content, filename, content_type)
    storage_type = "supabase"

    # 2. Fallback to local /uploads/ directory with strict path sanitization
    if not public_url:
        upload_dir = os.path.abspath("uploads")
        os.makedirs(upload_dir, exist_ok=True)
        safe_basename = os.path.basename(filename)
        local_path = os.path.abspath(os.path.join(upload_dir, safe_basename))
        if not local_path.startswith(upload_dir + os.sep):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid filename path",
            )
        with open(local_path, "wb") as f:
            f.write(content)

        base_url = str(request.base_url).rstrip("/")
        public_url = f"{base_url}/uploads/{safe_basename}"
        storage_type = "local"

    return {
        "status": "UPLOADED",
        "url": public_url,
        "filename": filename,
        "image_type": image_type,
        "storage": storage_type,
    }


# ─────────────────────────────────────────────────────────────────────────────
# Publish
# ─────────────────────────────────────────────────────────────────────────────


@router.post("/publish", status_code=status.HTTP_200_OK)
async def publish_listing(listing: ArtisanListingPayload) -> dict:
    """
    Receive a finalized artisan listing from the Flutter app, persist it to
    the database (Supabase / SQLite) and stage it in the catalog store so it
    is served on the next ONDC ``/search`` request.
    """
    await save_active_listing_async(listing, status="PUBLISHED")
    return {
        "status": "PUBLISHED",
        "message": (
            f"Listing '{listing.title_en}' is now active on ONDC rails. "
            f"It will appear in the next /on_search callback."
        ),
        "catalog_id": listing.catalog_id,
        "artisan": listing.artisan_name,
        "fair_price_inr": listing.fair_price,
    }


# ─────────────────────────────────────────────────────────────────────────────
# Listings
# ─────────────────────────────────────────────────────────────────────────────


@router.get("/listings", status_code=status.HTTP_200_OK)
async def fetch_all_listings() -> dict:
    """Return all currently active listings in the catalog store."""
    listings = get_all_listings()
    return {
        "count": len(listings),
        "listings": [lst.model_dump() for lst in listings],
    }


@router.get("/listings/{catalog_id}", status_code=status.HTTP_200_OK)
async def fetch_listing(catalog_id: str) -> dict:
    """Fetch a single listing by its catalog_id."""
    listing = get_listing_by_id(catalog_id)
    if listing is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Listing '{catalog_id}' not found.",
        )
    return listing.model_dump()


@router.delete("/listings/{catalog_id}", status_code=status.HTTP_200_OK)
async def remove_listing(catalog_id: str) -> dict:
    """Remove a listing permanently from the catalog store and database."""
    removed = await delete_listing_async(catalog_id)
    if not removed:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Listing '{catalog_id}' not found.",
        )
    return {"status": "REMOVED", "catalog_id": catalog_id}


@router.post("/listings/{catalog_id}/unlist", status_code=status.HTTP_200_OK)
async def unlist_listing(catalog_id: str) -> dict:
    """Revert an active ONDC listing to UNLISTED / Draft mode."""
    success = await unlist_listing_async(catalog_id)
    return {
        "status": "UNLISTED",
        "catalog_id": catalog_id,
        "message": "Listing unlisted from ONDC network. Reverted to draft.",
    }


# ─────────────────────────────────────────────────────────────────────────────
# Health
# ─────────────────────────────────────────────────────────────────────────────


@router.get("/health", status_code=status.HTTP_200_OK)
async def app_health() -> dict:
    """Quick health check — returns active listing count."""
    return {"status": "ok", "active_listings": listing_count()}
