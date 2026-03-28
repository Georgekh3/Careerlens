from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.schemas.job_analysis import JobAnalyzeRequest, JobAnalyzeResponse
from app.config import settings
from app.schemas.profile import CvProcessRequest, CvProcessResponse
from app.services.cv_text_extractor import CvTextExtractor
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
        job_description_id=save_result["job_description_id"],
        job_analysis_id=save_result["job_analysis_id"],
        analysis=analysis,
    )
