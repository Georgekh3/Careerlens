import json

from app.schemas.interview_coaching import (
    CoachingKickoffResult,
    TurnCoachingResult,
)
from app.schemas.profile import StructuredProfile
from app.services.openai_structured_client import OpenAIStructuredClient


class InterviewCoachingParser:
    def __init__(self, client: OpenAIStructuredClient | None = None):
        self._client = client or OpenAIStructuredClient()

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
        parsed_json = self._client.parse(
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
        parsed_json = self._client.parse(
            schema=TurnCoachingResult.model_json_schema(),
            schema_name="interview_turn_coaching",
            system_prompt=system_prompt,
            user_prompt=user_prompt,
            error_prefix="OpenAI interview turn error",
        )
        return TurnCoachingResult.model_validate(parsed_json)
