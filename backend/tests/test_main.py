import os
import sys
import unittest

# Ensure backend directory is in sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

# Ensure test mode settings before importing app (hermetic: never hit real Supabase in unit tests)
os.environ["BPP_SUBSCRIBER_ID"] = "test.bazaarsetu.bpp"
os.environ["BPP_PUBLIC_URI"] = "https://test.bazaarsetu.bpp"
os.environ["BPP_SIGNING_PRIVATE_KEY"] = ""
os.environ["DATABASE_URL"] = "sqlite:///./test_bazaarsetu.db"
os.environ["SUPABASE_URL"] = ""
os.environ["SUPABASE_KEY"] = ""

from fastapi.testclient import TestClient  # noqa: E402
from main import app  # noqa: E402


class TestBazaarSetuBPP(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.client = TestClient(app)

    @classmethod
    def tearDownClass(cls):
        for fname in ("test_bazaarsetu.db",):
            if os.path.exists(fname):
                os.remove(fname)

    def test_root_health_check(self):
        """Verify BPP health check returns status ok and service identity."""
        response = self.client.get("/")
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["status"], "ok")
        self.assertEqual(data["service"], "BazaarSetu BPP")
        self.assertIn("active_listings", data)
        self.assertEqual(data["docs"], "/docs")

    def test_openapi_docs_accessible(self):
        """Verify OpenAPI schema is generated and accessible."""
        response = self.client.get("/openapi.json")
        self.assertEqual(response.status_code, 200)
        schema = response.json()
        self.assertEqual(schema["info"]["title"], "BazaarSetu BPP")

    def test_dual_bucket_resolution_and_upload_separation(self):
        """Verify raw and processed images route to separate buckets/paths."""
        from app.db import resolve_storage_bucket

        self.assertEqual(resolve_storage_bucket("raw"), "raw-craft-images")
        self.assertEqual(resolve_storage_bucket("studio"), "processed-craft-images")
        self.assertEqual(resolve_storage_bucket("marketplace"), "processed-craft-images")

        raw_res = self.client.post(
            "/api/v1/bpp/upload-image",
            data={"catalog_id": "test_cat_1", "image_type": "raw"},
            files={"file": ("raw.jpg", b"fake-raw-bytes", "image/jpeg")},
        )
        self.assertEqual(raw_res.status_code, 200)
        raw_data = raw_res.json()
        self.assertIsNotNone(raw_data["raw_image_url"])
        self.assertIsNone(raw_data["studio_image_url"])
        self.assertEqual(raw_data["bucket"], "raw")

        studio_res = self.client.post(
            "/api/v1/bpp/upload-image",
            data={"catalog_id": "test_cat_1", "image_type": "studio"},
            files={"file": ("studio.jpg", b"fake-studio-bytes", "image/jpeg")},
        )
        self.assertEqual(studio_res.status_code, 200)
        studio_data = studio_res.json()
        self.assertIsNone(studio_data["raw_image_url"])
        self.assertIsNotNone(studio_data["studio_image_url"])
        self.assertEqual(studio_data["bucket"], "processed")

    def test_ondc_mapper_excludes_raw_images(self):
        """Verify ONDC on_search payload sends only AI-processed images, never raw."""
        from app.ondc_mapper import build_on_search_catalog
        from app.schemas import ArtisanListingPayload

        item = ArtisanListingPayload(
            catalog_id="cat_ondc_img_test",
            title_en="Brass Lamp",
            description_en="Handcrafted brass diya",
            floor_price=200.0,
            fair_price=350.0,
            premium_price=450.0,
            raw_image_url="https://example.com/raw-craft-images/lamp_raw.jpg",
            studio_image_url="https://example.com/processed-craft-images/lamp_studio.jpg",
            gallery_images=[
                "https://example.com/raw-craft-images/lamp_raw.jpg",
                "https://example.com/processed-craft-images/lamp_angle2.jpg",
            ],
        )

        payload = build_on_search_catalog(
            transaction_id="txn_1",
            message_id="msg_1",
            bpp_id="test.bazaarsetu.bpp",
            bpp_uri="https://test.bazaarsetu.bpp",
            item=item,
        )
        provider = payload["message"]["catalog"]["bpp/providers"][0]
        ondc_item = provider["items"][0]
        images = ondc_item["descriptor"]["images"]
        self.assertIn("https://example.com/processed-craft-images/lamp_studio.jpg", images)
        self.assertIn("https://example.com/processed-craft-images/lamp_angle2.jpg", images)
        self.assertNotIn("https://example.com/raw-craft-images/lamp_raw.jpg", images)
        self.assertNotIn(
            "https://example.com/raw-craft-images/lamp_raw.jpg",
            provider["descriptor"]["images"],
        )

    def test_draft_and_listing_update_endpoints(self):
        """Verify draft save and full listing update endpoints persist all fields."""
        base_payload = {
            "catalog_id": "cat_sync_001",
            "title_en": "Clay Pot",
            "description_en": "Handmade clay pot",
            "floor_price": 150.0,
            "fair_price": 300.0,
            "premium_price": 400.0,
            "raw_material_cost": 80.0,
            "labor_days": 2,
            "available_qty": 3,
            "raw_image_url": "https://example.com/raw.jpg",
            "studio_image_url": "https://example.com/studio.jpg",
        }
        draft_res = self.client.post("/api/v1/bpp/draft", json=base_payload)
        self.assertEqual(draft_res.status_code, 200)
        self.assertEqual(draft_res.json()["status"], "DRAFT")

        updated_payload = {**base_payload, "fair_price": 375.0, "available_qty": 8}
        put_res = self.client.put(
            "/api/v1/bpp/listings/cat_sync_001?listing_status=PUBLISHED",
            json=updated_payload,
        )
        self.assertEqual(put_res.status_code, 200)
        self.assertEqual(put_res.json()["fair_price_inr"], 375.0)

        fetched = self.client.get("/api/v1/bpp/listings/cat_sync_001")
        self.assertEqual(fetched.status_code, 200)
        self.assertEqual(fetched.json()["fair_price"], 375.0)
        self.assertEqual(fetched.json()["available_qty"], 8)

    def test_storage_url_parsing_and_delete_cleanup(self):
        """Verify Supabase object path extraction and local image cleanup on delete."""
        from app.db import extract_storage_object

        self.assertEqual(
            extract_storage_object(
                "https://abc.supabase.co/storage/v1/object/public/raw-craft-images/id_1_raw.jpg"
            ),
            ("raw-craft-images", "id_1_raw.jpg"),
        )
        self.assertIsNone(extract_storage_object("https://example.com/other.jpg"))

        self.client.post(
            "/api/v1/bpp/upload-image",
            data={"catalog_id": "del_cat_1", "image_type": "raw"},
            files={"file": ("raw.jpg", b"raw-bytes", "image/jpeg")},
        )
        self.client.post(
            "/api/v1/bpp/publish",
            json={
                "catalog_id": "del_cat_1",
                "title_en": "Temp Craft",
                "description_en": "Temp desc",
                "floor_price": 100.0,
                "fair_price": 200.0,
                "premium_price": 250.0,
                "raw_image_url": "/uploads/raw/del_cat_1_raw.jpg",
            },
        )
        self.assertTrue(os.path.exists(os.path.join("uploads", "raw", "del_cat_1_raw.jpg")))

        del_res = self.client.delete("/api/v1/bpp/listings/del_cat_1")
        self.assertEqual(del_res.status_code, 200)
        self.assertFalse(os.path.exists(os.path.join("uploads", "raw", "del_cat_1_raw.jpg")))


if __name__ == "__main__":
    unittest.main()
