import json

import requests

from app.config import settings
from app.schemas.profile import StructuredProfile


class ProfileParser:
    def parse_to_profile(self, extracted_text: str) -> StructuredProfile:
        if not settings.openai_api_key:
            raise RuntimeError("OPENAI_API_KEY is not configured.")

        schema = StructuredProfile.model_json_schema()
        payload = {
            "model": settings.openai_model,
            "input": [
                {
                    "role": "system",
                    "content": [
                        {
                            "type": "input_text",
                            "text": (
                                "Extract a structured professional profile from the CV text. "
                                "Return only data grounded in the CV. "
                                "Use empty strings or empty arrays when information is missing."
                            ),
                        }
                    ],
                },
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "input_text",
                            "text": f"CV text:\n{extracted_text}",
                        }
                    ],
                },
            ],
            "text": {
                "format": {
                    "type": "json_schema",
                    "name": "structured_profile",
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
        response.raise_for_status()
        response_json = response.json()

        parsed_json = self._extract_output_json(response_json)
        return StructuredProfile.model_validate(parsed_json)

    def _extract_output_json(self, response_json: dict) -> dict:
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
