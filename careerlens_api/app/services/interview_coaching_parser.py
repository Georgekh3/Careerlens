import json

from app.schemas.interview_coaching import (
    CoachingKickoffResult,
    TurnCoachingResult,
)
from app.schemas.profile import StructuredProfile
from app.services.openai_structured_client import OpenAIStructuredClient


class InterviewCoachingParser:
    _MAX_JOB_TEXT_CHARS = 5000
    _MAX_TURN_TEXT_CHARS = 700
    _MAX_FEEDBACK_CHARS = 300
    _MAX_RECENT_TURNS = 4

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
            "You are an experienced HR interviewer conducting a realistic mock interview for a specific job. "
            "Use the candidate profile and the job description to start the interview in a natural, professional way. "
            "Return only structured JSON matching the schema. "
            "The interview stage is intro. "
            "The first question must be a warm introductory question that helps the candidate present their background, "
            "experience, and fit at a high level. "
            "Do not begin with a highly technical, narrow, or overly difficult question. "
            "Even though the opening should be general, it should still be subtly aligned with the target role and job description. "
            "Make the question sound like something a real HR interviewer would ask in the opening minutes of an interview. "
            "Set first_question.stage to 'intro'."
        )
        user_prompt = (
            f"Candidate profile:\n{json.dumps(self._build_profile_context(profile), indent=2)}\n\n"
            f"Location: {location}\n\n"
            f"Job description:\n{self._clip(raw_job_text, self._MAX_JOB_TEXT_CHARS)}\n\n"
            "Generate the opening interview question for this candidate. "
            "The question should be broad, natural, and easy to answer, while still helping assess overall fit for the role."
        )
        parsed_json = self._client.parse(
            schema=CoachingKickoffResult.model_json_schema(),
            schema_name="interview_coaching_kickoff",
            system_prompt=system_prompt,
            user_prompt=user_prompt,
            error_prefix="OpenAI interview kickoff error",
        )
        result = CoachingKickoffResult.model_validate(parsed_json)
        if result.first_question.stage is None:
            result = result.model_copy(
                update={
                    "first_question": result.first_question.model_copy(
                        update={"stage": "intro"}
                    )
                }
            )
        return result

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
        current_stage: str,
        next_stage: str,
        ready_to_finish: bool,
    ) -> TurnCoachingResult:
        system_prompt = (
            "You are an experienced HR interviewer evaluating a candidate answer in a realistic mock interview for a specific job. "
            "Score the answer for relevance, clarity, technical depth, communication quality, and logical structure. "
            "Return only structured JSON matching the schema. "
            "Provide concrete feedback and practical improvement suggestions. "
            "This product uses backend-controlled interview stages. You must respect the current and next stage provided by the user prompt. "
            "Do not ask multiple questions at once. "
            "Each next question should feel like a logical follow-up based on the candidate's previous answers and the target job. "
            "For intro and motivation stages, do not over-penalize technical depth if the answer is appropriately non-technical. "
            "Behavioral questions should prioritize structure, specificity, and outcomes. "
            "Role-fit and technical stages should tie feedback directly to the job requirements. "
            "The session is user-controlled, so set is_session_complete to false unless the prompt explicitly says the session is ending. "
            "Always return a valid next_question. "
            "Set evaluation.stage to the current stage and set next_question.stage to the next stage."
        )
        user_prompt = (
            f"Candidate profile:\n{json.dumps(self._build_profile_context(profile), indent=2)}\n\n"
            f"Current session summary:\n{session_summary}\n\n"
            f"Current interview stage: {current_stage}\n"
            f"Next interview stage to ask: {next_stage}\n"
            f"Ready to finish after this turn: {str(ready_to_finish).lower()}\n\n"
            f"Location: {location}\n\n"
            f"Job description:\n{self._clip(raw_job_text, self._MAX_JOB_TEXT_CHARS)}\n\n"
            f"Answered turns so far: {answered_turn_count}\n"
            f"Prior turns:\n{json.dumps(self._build_prior_turns_context(prior_turns), indent=2)}\n\n"
            f"Current question:\n{json.dumps(current_question, indent=2)}\n\n"
            f"Candidate answer:\n{self._clip(answer_text, self._MAX_TURN_TEXT_CHARS)}\n\n"
            "Ask one clear next question only. "
            "Avoid repeating topics that were already covered unless a deeper follow-up is genuinely useful. "
            "Keep the interview aligned with the responsibilities and requirements in the job description. "
            "If ready_to_finish is true, the next question should feel like a strong wrap-up or deeper follow-up that still adds value."
        )
        parsed_json = self._client.parse(
            schema=TurnCoachingResult.model_json_schema(),
            schema_name="interview_turn_coaching",
            system_prompt=system_prompt,
            user_prompt=user_prompt,
            error_prefix="OpenAI interview turn error",
        )
        result = TurnCoachingResult.model_validate(parsed_json)
        evaluation = result.evaluation
        if evaluation.stage is None:
            evaluation = evaluation.model_copy(update={"stage": current_stage})
        next_question = result.next_question
        if next_question is not None and next_question.stage is None:
            next_question = next_question.model_copy(update={"stage": next_stage})
        return result.model_copy(
            update={
                "evaluation": evaluation,
                "next_question": next_question,
                "is_session_complete": False,
            }
        )

    def _build_profile_context(self, profile: StructuredProfile) -> dict:
        return {
            "headline": self._clip(profile.basics.headline, 160),
            "location": self._clip(profile.basics.location, 120),
            "summary": self._clip(profile.basics.summary, 600),
            "skills": [self._clip(item.name, 60) for item in profile.skills[:10]],
            "experience": [
                {
                    "title": self._clip(item.title, 80),
                    "company": self._clip(item.company, 80),
                    "description": self._clip(item.description, 260),
                }
                for item in profile.experience[:4]
            ],
            "education": [
                {
                    "degree": self._clip(item.degree, 100),
                    "institution": self._clip(item.institution, 100),
                }
                for item in profile.education[:2]
            ],
            "certifications": [
                self._clip(item.name, 100) for item in profile.certifications[:3]
            ],
        }

    def _build_prior_turns_context(self, prior_turns: list[dict]) -> dict:
        recent_turns = prior_turns[-self._MAX_RECENT_TURNS :]
        older_count = max(0, len(prior_turns) - len(recent_turns))
        return {
            "older_turn_count": older_count,
            "recent_turns": [
                {
                    "turn_no": turn.get("turn_no"),
                    "question": self._clip(
                        str((turn.get("question") or {}).get("question", "")),
                        220,
                    ),
                    "stage": (turn.get("question") or {}).get("stage"),
                    "answer": self._clip(str(turn.get("answer", "")), self._MAX_TURN_TEXT_CHARS),
                    "feedback": self._clip(
                        str((turn.get("evaluation") or {}).get("structured_feedback", "")),
                        self._MAX_FEEDBACK_CHARS,
                    ),
                }
                for turn in recent_turns
            ],
        }

    def _clip(self, value: str, max_chars: int) -> str:
        normalized = " ".join((value or "").split())
        if len(normalized) <= max_chars:
            return normalized
        return f"{normalized[: max_chars - 3].rstrip()}..."
