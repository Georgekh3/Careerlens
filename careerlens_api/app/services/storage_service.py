import requests
from supabase import Client, create_client

from app.config import settings


class StorageService:
    def __init__(self) -> None:
        if not settings.supabase_url or not settings.supabase_service_role_key:
            raise RuntimeError(
                "SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY must be configured."
            )

        self._client: Client = create_client(
            settings.supabase_url,
            settings.supabase_service_role_key,
        )

    def download_file(self, *, bucket: str, storage_path: str) -> bytes:
        signed_payload = self._client.storage.from_(bucket).create_signed_url(
            storage_path,
            60,
        )

        signed_path = ""
        if isinstance(signed_payload, dict):
            signed_path = (
                signed_payload.get("signedURL")
                or signed_payload.get("signedUrl")
                or signed_payload.get("signed_url")
                or ""
            )

        if not signed_path:
            raise RuntimeError("Supabase Storage did not return a signed URL.")

        signed_url = (
            signed_path
            if signed_path.startswith("http")
            else f"{settings.supabase_url}/storage/v1{signed_path}"
        )

        response = requests.get(signed_url, timeout=60)
        response.raise_for_status()

        if not response.content:
            raise RuntimeError("Supabase Storage returned an empty file response.")

        return response.content
