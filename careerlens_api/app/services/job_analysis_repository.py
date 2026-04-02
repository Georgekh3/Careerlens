from sqlalchemy import text

from app.db import SessionLocal
from app.schemas.job_analysis import JobAnalysisResult
from app.schemas.profile import StructuredProfile, normalize_stored_profile


class JobAnalysisRepository:
    def fetch_current_profile(self, *, user_id: str) -> StructuredProfile:
        with SessionLocal.begin() as session:
            row = session.execute(
                text(
                    """
                    select authoritative_profile
                    from public.profiles
                    where id = :user_id
                    """
                ),
                {"user_id": user_id},
            ).mappings().first()

            if row is None:
                raise ValueError(f"Profile not found for user_id={user_id}")

            return StructuredProfile.model_validate(
                normalize_stored_profile(row["authoritative_profile"])
            )

    def save_job_analysis(
        self,
        *,
        user_id: str,
        raw_text: str,
        title: str,
        company: str,
        location: str,
        source: str,
        profile: StructuredProfile,
        analysis: JobAnalysisResult,
    ) -> dict:
        with SessionLocal.begin() as session:
            profile_version_row = session.execute(
                text(
                    """
                    select id
                    from public.profile_versions
                    where user_id = :user_id
                    order by version_no desc
                    limit 1
                    """
                ),
                {"user_id": user_id},
            ).mappings().first()

            job_description_row = session.execute(
                text(
                    """
                    insert into public.job_descriptions (
                        user_id,
                        title,
                        company,
                        location,
                        source,
                        raw_text,
                        normalized_json
                    )
                    values (
                        :user_id,
                        :title,
                        :company,
                        :location,
                        :source,
                        :raw_text,
                        cast(:normalized_json as jsonb)
                    )
                    returning id
                    """
                ),
                {
                    "user_id": user_id,
                    "title": title or None,
                    "company": company or None,
                    "location": location or None,
                    "source": source,
                    "raw_text": raw_text,
                    "normalized_json": "{}",
                },
            ).mappings().one()

            job_analysis_row = session.execute(
                text(
                    """
                    insert into public.job_analyses (
                        user_id,
                        job_description_id,
                        profile_version_id,
                        overall_fit_score,
                        skills_match_score,
                        experience_match_score,
                        education_cert_score,
                        domain_relevance_score,
                        matched_skills,
                        missing_skills,
                        missing_requirements,
                        recommendations,
                        score_explanation,
                        raw_result,
                        ai_model
                    )
                    values (
                        :user_id,
                        :job_description_id,
                        :profile_version_id,
                        :overall_fit_score,
                        :skills_match_score,
                        :experience_match_score,
                        :education_cert_score,
                        :domain_relevance_score,
                        cast(:matched_skills as jsonb),
                        cast(:missing_skills as jsonb),
                        cast(:missing_requirements as jsonb),
                        cast(:recommendations as jsonb),
                        cast(:score_explanation as jsonb),
                        cast(:raw_result as jsonb),
                        :ai_model
                    )
                    returning id
                    """
                ),
                {
                    "user_id": user_id,
                    "job_description_id": job_description_row["id"],
                    "profile_version_id": (
                        profile_version_row["id"] if profile_version_row else None
                    ),
                    "overall_fit_score": analysis.overall_fit_score,
                    "skills_match_score": analysis.skills_match_score,
                    "experience_match_score": analysis.experience_match_score,
                    "education_cert_score": analysis.education_cert_score,
                    "domain_relevance_score": analysis.domain_relevance_score,
                    "matched_skills": json_dumps(analysis.matched_skills),
                    "missing_skills": json_dumps(analysis.missing_skills),
                    "missing_requirements": json_dumps(analysis.missing_requirements),
                    "recommendations": json_dumps(analysis.recommendations),
                    "score_explanation": json_dumps(
                        analysis.score_explanation.model_dump()
                    ),
                    "raw_result": analysis.model_dump_json(),
                    "ai_model": "openai",
                },
            ).mappings().one()

        return {
            "job_description_id": job_description_row["id"],
            "job_analysis_id": job_analysis_row["id"],
            "analysis": analysis.model_dump(),
        }


def json_dumps(value) -> str:
    import json

    return json.dumps(value)
