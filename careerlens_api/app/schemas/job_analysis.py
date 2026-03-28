from typing import List

from pydantic import Field

from app.schemas.profile import StrictSchemaModel


class ScoreExplanation(StrictSchemaModel):
    overall_summary: str
    strengths: List[str]
    risks: List[str]


class JobAnalysisResult(StrictSchemaModel):
    overall_fit_score: int = Field(..., ge=1, le=100)
    skills_match_score: int = Field(..., ge=0, le=40)
    experience_match_score: int = Field(..., ge=0, le=35)
    education_cert_score: int = Field(..., ge=0, le=15)
    domain_relevance_score: int = Field(..., ge=0, le=10)
    matched_skills: List[str]
    missing_skills: List[str]
    missing_requirements: List[str]
    recommendations: List[str]
    score_explanation: ScoreExplanation


class JobAnalyzeRequest(StrictSchemaModel):
    user_id: str = Field(..., min_length=1)
    raw_text: str = Field(..., min_length=20)
    title: str = ""
    company: str = ""
    location: str = ""
    source: str = "pasted"


class JobAnalyzeResponse(StrictSchemaModel):
    message: str
    job_description_id: str
    job_analysis_id: str
    analysis: JobAnalysisResult
