import json
from typing import Any

import requests

from app.config import settings


class OpenAIStructuredClient:
    def parse(
        self,
        *,
        schema: dict[str, Any],
        schema_name: str,
        system_prompt: str,
        user_prompt: str,
        error_prefix: str,
    ) -> dict[str, Any]:
        if not settings.openai_api_key:
            raise RuntimeError("OPENAI_API_KEY is not configured.")

        payload = {
            "model": settings.openai_model,
            "input": [
                {
                    "role": "system",
                    "content": [{"type": "input_text", "text": system_prompt}],
                },
                {
                    "role": "user",
                    "content": [{"type": "input_text", "text": user_prompt}],
                },
            ],
            "text": {
                "format": {
                    "type": "json_schema",
                    "name": schema_name,
                    "schema": schema,
                    "strict": True,
                }
            },
        }

        response = requests.post(
            "https://api.openai.com/v1/responses",
            headers={
                "Authorization": f"Bearer {settings.openai_api_key}",
                "Content-Type": "application/json",
            },
            json=payload,
            timeout=90,
        )
        if not response.ok:
            raise RuntimeError(f"{error_prefix} {response.status_code}: {response.text}")

        return self.extract_output_json(response.json())

    @staticmethod
    def extract_output_json(response_json: dict[str, Any]) -> dict[str, Any]:
        if isinstance(response_json.get("output_parsed"), dict):
            return response_json["output_parsed"]

        for output_item in response_json.get("output", []):
            for content_item in output_item.get("content", []):
                if isinstance(content_item.get("parsed"), dict):
                    return content_item["parsed"]

                text_value = content_item.get("text")
                if isinstance(text_value, str) and text_value.strip():
                    return json.loads(text_value)

        raise ValueError("OpenAI response did not include structured JSON output.")
