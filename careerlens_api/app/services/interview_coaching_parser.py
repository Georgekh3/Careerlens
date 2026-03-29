import json

import requests

from app.config import settings
from app.schemas.interview_coaching import (
    CoachingKickoffResult,
    TurnCoachingResult,
)
from app.schemas.profile import StructuredProfile


class InterviewCoachingParser:
    def generate_kickoff(
        self,
        *,
        profile: StructuredProfile,
        raw_job_text: str,
        location: str,
    ) -> CoachingKickoffResult:
        system_prompt = (
            "You are an AI interview coach. Create the start of a mock interview session "
            "based on the candidate profile and target job description. "
            "Return only structured JSON matching the schema. "
            "The first question should be tailored, realistic, and useful for assessing fit."
        )
        user_prompt = (
            f"Candidate profile:\n{profile.model_dump_json(indent=2)}\n\n"
            f"Location: {location}\n\n"
            f"Job description:\n{raw_job_text}"
        )
        parsed_json = self._call_openai(
            schema=CoachingKickoffResult.model_json_schema(),
            schema_name="interview_coaching_kickoff",
            system_prompt=system_prompt,
            user_prompt=user_prompt,
            error_prefix="OpenAI interview kickoff error",
        )
        return CoachingKickoffResult.model_validate(parsed_json)

    def evaluate_turn(
        self,
        *,
        profile: StructuredProfile,
        raw_job_text: str,
        location: str,
        session_summary: str,
        prior_turns: list[dict],
        current_question: dict,
        answer_text: str,
        answered_turn_count: int,
    ) -> TurnCoachingResult:
        system_prompt = (
            "You are an AI interview coach evaluating a candidate answer in a mock interview. "
            "Score the answer for relevance, clarity, technical depth, communication quality, "
            "and logical structure. Return only structured JSON matching the schema. "
            "Provide concrete feedback and practical improvement suggestions. "
            "If the session has covered enough ground after this answer, mark it complete; "
            "otherwise provide the next best tailored question."
        )
        user_prompt = (
            f"Candidate profile:\n{profile.model_dump_json(indent=2)}\n\n"
            f"Current session summary:\n{session_summary}\n\n"
            f"Location: {location}\n\n"
            f"Job description:\n{raw_job_text}\n\n"
            f"Answered turns so far: {answered_turn_count}\n"
            f"Prior turns:\n{json.dumps(prior_turns, indent=2)}\n\n"
            f"Current question:\n{json.dumps(current_question, indent=2)}\n\n"
            f"Candidate answer:\n{answer_text}\n\n"
            "Prefer a 4-turn interview unless the coverage is already strong or very weak."
        )
        parsed_json = self._call_openai(
            schema=TurnCoachingResult.model_json_schema(),
            schema_name="interview_turn_coaching",
            system_prompt=system_prompt,
            user_prompt=user_prompt,
            error_prefix="OpenAI interview turn error",
        )
        return TurnCoachingResult.model_validate(parsed_json)

    def _call_openai(
        self,
        *,
        schema: dict,
        schema_name: str,
        system_prompt: str,
        user_prompt: str,
        error_prefix: str,
    ) -> dict:
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

        response_json = response.json()
        return self._extract_output_json(response_json)

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
