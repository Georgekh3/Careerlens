import unittest

from fastapi.testclient import TestClient

from app.main import app


class RootEndpointTests(unittest.TestCase):
    def test_root_reports_backend_status(self):
        client = TestClient(app)
        response = client.get("/")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["message"], "CareerLens backend is running")
