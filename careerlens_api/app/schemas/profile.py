from typing import List, Optional

from pydantic import BaseModel, Field


class Basics(BaseModel):
    headline: str = ""
    location: str = ""
    summary: str = ""


class Skill(BaseModel):
    name: str = Field(..., min_length=1)
    evidence: str = ""
    confidence: Optional[float] = Field(default=None, ge=0, le=1)


class ExperienceItem(BaseModel):
    title: str = ""
    company: str = ""
    start_date: str = ""
    end_date: str = ""
    description: str = ""
    evidence: str = ""
    confidence: Optional[float] = Field(default=None, ge=0, le=1)


class EducationItem(BaseModel):
    degree: str = ""
    institution: str = ""
    year: str = ""
    evidence: str = ""
    confidence: Optional[float] = Field(default=None, ge=0, le=1)


class CertificationItem(BaseModel):
    name: str = ""
    issuer: str = ""
    year: str = ""
    evidence: str = ""
    confidence: Optional[float] = Field(default=None, ge=0, le=1)


class StructuredProfile(BaseModel):
    basics: Basics = Field(default_factory=Basics)
    skills: List[Skill] = Field(default_factory=list)
    experience: List[ExperienceItem] = Field(default_factory=list)
    education: List[EducationItem] = Field(default_factory=list)
    certifications: List[CertificationItem] = Field(default_factory=list)


class CvProcessRequest(BaseModel):
    user_id: str = Field(..., min_length=1)
    cv_upload_id: Optional[str] = None
    storage_path: str = Field(..., min_length=1)
    original_filename: str = Field(..., min_length=1)


class CvProcessResponse(BaseModel):
    message: str
    structured_profile: StructuredProfile
    profile_saved: bool = False
    version_created: bool = False
