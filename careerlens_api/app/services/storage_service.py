from urllib.parse import quote

import requests

from app.config import settings


class StorageService:
    def download_file(self, *, bucket: str, storage_path: str) -> bytes:
        if not settings.supabase_url or not settings.supabase_service_role_key:
            raise RuntimeError(
                "SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY must be configured."
            )

        encoded_path = "/".join(quote(part, safe="") for part in storage_path.split("/"))
        url = f"{settings.supabase_url}/storage/v1/object/{bucket}/{encoded_path}"
        headers = {
            "Authorization": f"Bearer {settings.supabase_service_role_key}",
            "apikey": settings.supabase_service_role_key,
        }

        response = requests.get(url, headers=headers, timeout=30)
        response.raise_for_status()
        return response.content
