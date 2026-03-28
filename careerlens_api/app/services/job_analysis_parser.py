import json

import requests

from app.config import settings
from app.schemas.job_analysis import JobAnalysisResult
from app.schemas.profile import StructuredProfile


class JobAnalysisParser:
    def analyze(
        self,
        *,
        profile: StructuredProfile,
        raw_job_text: str,
        title: str,
        company: str,
        location: str,
    ) -> JobAnalysisResult:
        if not settings.openai_api_key:
            raise RuntimeError("OPENAI_API_KEY is not configured.")

        schema = JobAnalysisResult.model_json_schema()
        payload = {
            "model": settings.openai_model,
            "input": [
                {
                    "role": "system",
                    "content": [
                        {
                            "type": "input_text",
                            "text": (
                                "You are analyzing how well a candidate profile matches a job "
                                "description. Return only structured JSON that matches the schema. "
                                "Use evidence from the provided profile and job description. "
                                "Do not invent qualifications."
                            ),
                        }
                    ],
                },
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "input_text",
                            "text": (
                                f"Candidate profile:\n{profile.model_dump_json(indent=2)}\n\n"
                                f"Job title: {title}\n"
                                f"Company: {company}\n"
                                f"Location: {location}\n\n"
                                f"Job description:\n{raw_job_text}"
                            ),
                        }
                    ],
                },
            ],
            "text": {
                "format": {
                    "type": "json_schema",
                    "name": "job_analysis_result",
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
            raise RuntimeError(
                f"OpenAI job analysis error {response.status_code}: {response.text}"
            )

        response_json = response.json()
        parsed_json = self._extract_output_json(response_json)
        return JobAnalysisResult.model_validate(parsed_json)

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
