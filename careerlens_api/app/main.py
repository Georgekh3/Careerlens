from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.schemas.interview_preparation import (
    InterviewPrepareRequest,
    InterviewPrepareResponse,
)
from app.schemas.interview_coaching import (
    InterviewSessionStartRequest,
    InterviewSessionStartResponse,
    InterviewTurnAnswerRequest,
    InterviewTurnAnswerResponse,
    InterviewSessionView,
)
from app.schemas.job_analysis import JobAnalyzeRequest, JobAnalyzeResponse
from app.config import settings
from app.schemas.profile import CvProcessRequest, CvProcessResponse
from app.services.interview_coaching_parser import InterviewCoachingParser
from app.services.interview_coaching_repository import InterviewCoachingRepository
from app.services.cv_text_extractor import CvTextExtractor
from app.services.interview_preparation_parser import InterviewPreparationParser
from app.services.interview_preparation_repository import (
    InterviewPreparationRepository,
)
from app.services.job_analysis_parser import JobAnalysisParser
from app.services.job_analysis_repository import JobAnalysisRepository
from app.services.cv_upload_repository import CvUploadRepository
from app.services.profile_parser import ProfileParser
from app.services.profile_repository import ProfileRepository
from app.services.storage_service import StorageService

app = FastAPI(title=settings.app_name)

app.add_middleware(
    CORSMiddleware,
    allow_origins=[],
    allow_origin_regex=r"http://(localhost|127\.0\.0\.1)(:\d+)?",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

cv_text_extractor = CvTextExtractor()
cv_upload_repository = CvUploadRepository()
interview_coaching_parser = InterviewCoachingParser()
interview_coaching_repository = InterviewCoachingRepository()
interview_preparation_parser = InterviewPreparationParser()
interview_preparation_repository = InterviewPreparationRepository()
job_analysis_parser = JobAnalysisParser()
job_analysis_repository = JobAnalysisRepository()
profile_parser = ProfileParser()
profile_repository = ProfileRepository()
storage_service = StorageService()


@app.get("/")
def root():
    return {
        "message": "CareerLens backend is running",
        "environment": settings.app_env,
        "openai_configured": settings.is_openai_configured,
    }


@app.post("/cv/process", response_model=CvProcessResponse)
def process_cv(payload: CvProcessRequest) -> CvProcessResponse:
    if payload.cv_upload_id:
        cv_upload_repository.mark_extracting(cv_upload_id=payload.cv_upload_id)

    try:
        file_bytes = storage_service.download_file(
            bucket="cvs",
            storage_path=payload.storage_path,
        )
        extracted_text, parser_engine = cv_text_extractor.extract_text(
            file_bytes=file_bytes,
            original_filename=payload.original_filename,
        )
        if payload.cv_upload_id:
            cv_upload_repository.mark_parsed(
                cv_upload_id=payload.cv_upload_id,
                extracted_text=extracted_text,
                parser_engine=parser_engine,
                parsed_successfully=False,
            )
    except Exception as error:
        if payload.cv_upload_id:
            cv_upload_repository.mark_failed(
                cv_upload_id=payload.cv_upload_id,
                error_message=str(error),
            )
        raise

    try:
        if payload.cv_upload_id:
            cv_upload_repository.mark_ai_processing(cv_upload_id=payload.cv_upload_id)

        structured_profile = profile_parser.parse_to_profile(extracted_text)
        save_result = profile_repository.save_structured_profile(
            user_id=payload.user_id,
            cv_upload_id=payload.cv_upload_id,
            structured_profile=structured_profile,
        )

        if payload.cv_upload_id:
            cv_upload_repository.mark_parsed(
                cv_upload_id=payload.cv_upload_id,
                extracted_text=extracted_text,
                parser_engine=parser_engine,
                parsed_successfully=True,
            )
    except Exception as error:
        if payload.cv_upload_id:
            cv_upload_repository.mark_failed(
                cv_upload_id=payload.cv_upload_id,
                error_message=str(error),
            )
        raise

    return CvProcessResponse(
        message="CV processing scaffold completed.",
        structured_profile=structured_profile,
        profile_saved=save_result["profile_saved"],
        version_created=save_result["version_created"],
    )


@app.post("/job/analyze", response_model=JobAnalyzeResponse)
def analyze_job(payload: JobAnalyzeRequest) -> JobAnalyzeResponse:
    profile = job_analysis_repository.fetch_current_profile(user_id=payload.user_id)
    analysis = job_analysis_parser.analyze(
        profile=profile,
        raw_job_text=payload.raw_text,
        title=payload.title,
        company=payload.company,
        location=payload.location,
    )
    save_result = job_analysis_repository.save_job_analysis(
        user_id=payload.user_id,
        raw_text=payload.raw_text,
        title=payload.title,
        company=payload.company,
        location=payload.location,
        source=payload.source,
        profile=profile,
        analysis=analysis,
    )

    return JobAnalyzeResponse(
        message="Job description analyzed successfully.",
        job_description_id=str(save_result["job_description_id"]),
        job_analysis_id=str(save_result["job_analysis_id"]),
        analysis=analysis,
    )


@app.post("/interview/prepare", response_model=InterviewPrepareResponse)
def prepare_interview(payload: InterviewPrepareRequest) -> InterviewPrepareResponse:
    profile = interview_preparation_repository.fetch_current_profile(
        user_id=payload.user_id
    )
    preparation = interview_preparation_parser.prepare(
        profile=profile,
        raw_job_text=payload.raw_text,
        title=payload.title,
        company=payload.company,
        location=payload.location,
    )

    return InterviewPrepareResponse(
        message="Interview preparation generated successfully.",
        preparation=preparation,
    )


@app.post(
    "/interview/session/start",
    response_model=InterviewSessionStartResponse,
)
def start_interview_session(
    payload: InterviewSessionStartRequest,
) -> InterviewSessionStartResponse:
    profile = interview_coaching_repository.fetch_current_profile(user_id=payload.user_id)
    kickoff = interview_coaching_parser.generate_kickoff(
        profile=profile,
        raw_job_text=payload.raw_text,
        location=payload.location,
    )
    session_view = interview_coaching_repository.create_session(
        user_id=payload.user_id,
        raw_job_text=payload.raw_text,
        location=payload.location,
        kickoff=kickoff,
    )

    return InterviewSessionStartResponse(
        message="Interview coaching session started successfully.",
        session=session_view,
    )


@app.post(
    "/interview/session/answer",
    response_model=InterviewTurnAnswerResponse,
)
def answer_interview_turn(
    payload: InterviewTurnAnswerRequest,
) -> InterviewTurnAnswerResponse:
    profile = interview_coaching_repository.fetch_current_profile(user_id=payload.user_id)
    turn_context = interview_coaching_repository.fetch_turn_context(
        user_id=payload.user_id,
        session_id=payload.session_id,
    )
    turn_result = interview_coaching_parser.evaluate_turn(
        profile=profile,
        raw_job_text=turn_context["raw_job_text"],
        location=turn_context["location"],
        session_summary=turn_context["session_summary"],
        prior_turns=turn_context["prior_turns"],
        current_question=turn_context["current_question"],
        answer_text=payload.answer,
        answered_turn_count=turn_context["answered_turn_count"],
    )
    session_view = interview_coaching_repository.save_turn_result(
        user_id=payload.user_id,
        session_id=payload.session_id,
        answer_text=payload.answer,
        result=turn_result,
    )

    return InterviewTurnAnswerResponse(
        message="Interview answer evaluated successfully.",
        session=session_view,
    )


@app.get(
    "/interview/session/{session_id}",
    response_model=InterviewSessionView,
)
def get_interview_session(session_id: str, user_id: str) -> InterviewSessionView:
    return interview_coaching_repository.fetch_session_state(
        user_id=user_id,
        session_id=session_id,
    )
