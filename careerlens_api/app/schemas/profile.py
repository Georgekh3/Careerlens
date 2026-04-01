from typing import List, Optional

from pydantic import BaseModel, ConfigDict, Field


class StrictSchemaModel(BaseModel):
    model_config = ConfigDict(extra="forbid")


class Basics(StrictSchemaModel):
    headline: str
    location: str
    summary: str


class Skill(StrictSchemaModel):
    name: str = Field(..., min_length=1)
    evidence: Optional[str] = None
    confidence: Optional[float] = Field(None, ge=0, le=1)


class ExperienceItem(StrictSchemaModel):
    title: str
    company: str
    start_date: str
    end_date: str
    description: str
    evidence: str
    confidence: Optional[float] = Field(..., ge=0, le=1)


class EducationItem(StrictSchemaModel):
    degree: str
    institution: str
    year: str
    evidence: str
    confidence: Optional[float] = Field(..., ge=0, le=1)


class CertificationItem(StrictSchemaModel):
    name: str
    issuer: str
    year: str
    evidence: str
    confidence: Optional[float] = Field(..., ge=0, le=1)


class StructuredProfile(StrictSchemaModel):
    basics: Basics
    skills: List[Skill]
    experience: List[ExperienceItem]
    education: List[EducationItem]
    certifications: List[CertificationItem]


class CvProcessRequest(StrictSchemaModel):
    user_id: str = Field(..., min_length=1)
    cv_upload_id: Optional[str] = None
    storage_path: str = Field(..., min_length=1)
    original_filename: str = Field(..., min_length=1)


class CvProcessResponse(StrictSchemaModel):
    message: str
    structured_profile: StructuredProfile
    profile_saved: bool = False
    version_created: bool = False
