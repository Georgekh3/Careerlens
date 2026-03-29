from app.schemas.job_analysis import JobAnalysisResult
from app.schemas.profile import StructuredProfile
from app.services.openai_structured_client import OpenAIStructuredClient


class JobAnalysisParser:
    def __init__(self, client: OpenAIStructuredClient | None = None):
        self._client = client or OpenAIStructuredClient()

    def analyze(
        self,
        *,
        profile: StructuredProfile,
        raw_job_text: str,
        title: str,
        company: str,
        location: str,
    ) -> JobAnalysisResult:
        parsed_json = self._client.parse(
            schema=JobAnalysisResult.model_json_schema(),
            schema_name="job_analysis_result",
            system_prompt=(
                "You are a strict hiring evaluator analyzing how well a candidate "
                "profile matches a job description. Return only structured JSON that "
                "matches the schema.\n\n"
                "Use only explicit evidence from the provided profile and job "
                "description. Do not invent qualifications. Do not assume the "
                "candidate has a skill, tool, domain background, or experience unless "
                "it is clearly supported by the profile.\n\n"
                "Scoring rubric:\n"
                "- skills_match_score is 0 to 40 and must reflect only explicit skill "
                "evidence. Interest, potential, education alone, or generic computer "
                "literacy do not count as full skill matches.\n"
                "- experience_match_score is 0 to 35 and must reflect only direct, "
                "relevant hands-on experience from work, internships, projects, labs, "
                "or clearly described practical experience.\n"
                "- education_cert_score is 0 to 15 and should reflect degree alignment, "
                "coursework evidence, and certifications.\n"
                "- domain_relevance_score is 0 to 10 and should reflect how close the "
                "candidate's demonstrated background is to the target domain.\n\n"
                "Hard constraints:\n"
                "- Being a computer science student does not equal direct experience in "
                "a specialized field such as cybersecurity, data science, product, or "
                "business.\n"
                "- Stated interest in a domain does not count as domain experience.\n"
                "- Transferable problem-solving ability can help domain relevance, but "
                "must not by itself produce a high experience score.\n"
                "- If the profile lacks direct evidence, hands-on exposure, or relevant "
                "projects for the role, experience_match_score must stay low.\n"
                "- Near-perfect scores are allowed only when the profile explicitly "
                "demonstrates strong evidence for most of the role's requirements.\n"
                "- The numeric scores must be consistent with the written explanation, "
                "strengths, risks, missing_skills, and missing_requirements.\n\n"
                "Conservative bands for experience_match_score:\n"
                "- 0-8: no direct relevant experience; mostly interest, coursework, or "
                "generic background.\n"
                "- 9-18: limited relevant academic or project exposure; still missing "
                "direct practical depth.\n"
                "- 19-27: clear relevant projects, labs, internships, or some practical "
                "hands-on work.\n"
                "- 28-35: substantial direct and clearly relevant experience.\n\n"
                "Conservative bands for skills_match_score:\n"
                "- 0-10: minimal explicit overlap.\n"
                "- 11-20: some transferable or foundational overlap.\n"
                "- 21-30: several explicitly matched required skills.\n"
                "- 31-40: most required skills are explicitly supported by evidence.\n\n"
                "Before finalizing, check for contradictions. For example, if you say "
                "the profile lacks direct evidence or lacks hands-on experience, do not "
                "return a high experience_match_score. If many core skills are missing, "
                "do not return a near-perfect skills_match_score."
            ),
            user_prompt=(
                f"Candidate profile:\n{profile.model_dump_json(indent=2)}\n\n"
                f"Job title: {title}\n"
                f"Company: {company}\n"
                f"Location: {location}\n\n"
                f"Job description:\n{raw_job_text}"
            ),
            error_prefix="OpenAI job analysis error",
        )
        analysis = JobAnalysisResult.model_validate(parsed_json)
        return self._normalize_analysis(profile=profile, analysis=analysis)

    def _normalize_analysis(
        self,
        *,
        profile: StructuredProfile,
        analysis: JobAnalysisResult,
    ) -> JobAnalysisResult:
        skills_score = analysis.skills_match_score
        experience_score = analysis.experience_match_score
        education_score = analysis.education_cert_score
        domain_score = analysis.domain_relevance_score

        explanation_text = " ".join(
            [
                analysis.score_explanation.overall_summary,
                *analysis.score_explanation.strengths,
                *analysis.score_explanation.risks,
                *analysis.missing_skills,
                *analysis.missing_requirements,
            ]
        ).lower()

        direct_evidence_gap_phrases = (
            "lacks direct evidence",
            "no direct evidence",
            "missing direct evidence",
            "lacks hands-on",
            "no hands-on",
            "missing hands-on",
            "lacks relevant experience",
            "no relevant experience",
            "missing relevant experience",
            "lacks practical experience",
            "no practical experience",
        )
        if any(phrase in explanation_text for phrase in direct_evidence_gap_phrases):
            experience_score = min(experience_score, 12)

        if not profile.experience:
            experience_score = min(experience_score, 8)

        if len(analysis.missing_requirements) >= 4:
            experience_score = min(experience_score, 18)

        if len(analysis.missing_skills) >= 5:
            skills_score = min(skills_score, 22)
        elif len(analysis.missing_skills) >= 3:
            skills_score = min(skills_score, 28)

        core_skill_gap_phrases = (
            "missing core",
            "lacks core",
            "missing fundamentals",
            "lacks foundational",
            "lacks required skills",
            "missing required skills",
        )
        if any(phrase in explanation_text for phrase in core_skill_gap_phrases):
            skills_score = min(skills_score, 24)

        overall_score = skills_score + experience_score + education_score + domain_score

        return analysis.model_copy(
            update={
                "skills_match_score": skills_score,
                "experience_match_score": experience_score,
                "overall_fit_score": max(1, min(100, overall_score)),
            }
        )
