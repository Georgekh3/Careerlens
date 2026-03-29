from typing import List

from pydantic import Field

from app.schemas.profile import StrictSchemaModel


class InterviewQuestion(StrictSchemaModel):
    question: str
    why_it_matters: str
    suggested_talking_points: List[str]


class InterviewPreparationResult(StrictSchemaModel):
    interview_readiness_summary: str
    personal_pitch: str
    focus_areas: List[str]
    likely_topics: List[str]
    tailored_questions: List[InterviewQuestion]
    final_tips: List[str]


class InterviewPrepareRequest(StrictSchemaModel):
    user_id: str = Field(..., min_length=1)
    raw_text: str = Field(..., min_length=20)
    title: str = ""
    company: str = ""
    location: str = ""


class InterviewPrepareResponse(StrictSchemaModel):
    message: str
    preparation: InterviewPreparationResult
