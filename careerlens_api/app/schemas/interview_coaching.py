from typing import List, Optional

from pydantic import Field

from app.schemas.profile import StrictSchemaModel


class CoachingQuestion(StrictSchemaModel):
    question: str
    category: str
    intent: str


class CoachingKickoffResult(StrictSchemaModel):
    session_summary: str
    focus_areas: List[str]
    readiness_score: int = Field(..., ge=1, le=100)
    first_question: CoachingQuestion


class EvaluationScores(StrictSchemaModel):
    relevance: int = Field(..., ge=1, le=10)
    clarity: int = Field(..., ge=1, le=10)
    technical_depth: int = Field(..., ge=1, le=10)
    communication_quality: int = Field(..., ge=1, le=10)
    logical_structure: int = Field(..., ge=1, le=10)


class TurnEvaluation(StrictSchemaModel):
    structured_feedback: str
    improvement_suggestions: List[str]
    performance_rating: str
    readiness_score: int = Field(..., ge=1, le=100)
    scores: EvaluationScores


class TurnCoachingResult(StrictSchemaModel):
    evaluation: TurnEvaluation
    next_question: Optional[CoachingQuestion]
    is_session_complete: bool
    session_summary: str


class InterviewTurnView(StrictSchemaModel):
    turn_id: str
    turn_no: int
    question: CoachingQuestion
    answer: str
    evaluation: Optional[TurnEvaluation]


class InterviewSessionView(StrictSchemaModel):
    session_id: str
    readiness_score: int = Field(..., ge=1, le=100)
    performance_trend: List[int]
    session_summary: str
    focus_areas: List[str]
    current_question: Optional[CoachingQuestion]
    turns: List[InterviewTurnView]
    is_session_complete: bool
    current_stage: Optional[str] = None
    ready_to_finish: bool = False
    completion_reason: Optional[str] = None


class InterviewSessionStartRequest(StrictSchemaModel):
    user_id: str = Field(..., min_length=1)
    raw_text: str = Field(..., min_length=20)
    location: str = ""


class InterviewSessionStartResponse(StrictSchemaModel):
    message: str
    session: InterviewSessionView


class InterviewTurnAnswerRequest(StrictSchemaModel):
    user_id: str = Field(..., min_length=1)
    session_id: str = Field(..., min_length=1)
    answer: str = Field(..., min_length=5)
    turn_id: Optional[str] = None


class InterviewTurnAnswerResponse(StrictSchemaModel):
    message: str
    session: InterviewSessionView


class InterviewSessionFinishRequest(StrictSchemaModel):
    user_id: str = Field(..., min_length=1)
    session_id: str = Field(..., min_length=1)


class InterviewSessionFinishResponse(StrictSchemaModel):
    message: str
    session: InterviewSessionView
