from app.schemas.profile import StructuredProfile
from app.services.openai_structured_client import OpenAIStructuredClient


class ProfileParser:
    def __init__(self, client: OpenAIStructuredClient | None = None):
        self._client = client or OpenAIStructuredClient()

    def parse_to_profile(self, extracted_text: str) -> StructuredProfile:
        parsed_json = self._client.parse(
            schema=StructuredProfile.model_json_schema(),
            schema_name="structured_profile",
            system_prompt=(
                "Extract a structured professional profile from the CV text. "
                "Return only data grounded in the CV. "
                "Use empty strings or empty arrays when information is missing."
            ),
            user_prompt=f"CV text:\n{extracted_text}",
            error_prefix="OpenAI responses API error",
        )
        return StructuredProfile.model_validate(parsed_json)
