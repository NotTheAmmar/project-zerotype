import os
import sys
import unittest

# Ensure backend directory is in sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

# Ensure test mode settings before importing app
os.environ["BPP_SUBSCRIBER_ID"] = "test.bazaarsetu.bpp"
os.environ["BPP_PUBLIC_URI"] = "https://test.bazaarsetu.bpp"
os.environ["BPP_SIGNING_PRIVATE_KEY"] = ""

from fastapi.testclient import TestClient  # noqa: E402
from main import app  # noqa: E402


class TestBazaarSetuBPP(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.client = TestClient(app)

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


if __name__ == "__main__":
    unittest.main()
