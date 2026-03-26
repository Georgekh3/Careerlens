from sqlalchemy import text

from app.db import SessionLocal


class CvUploadRepository:
    def mark_extracting(self, *, cv_upload_id: str) -> None:
        with SessionLocal.begin() as session:
            session.execute(
                text(
                    """
                    update public.cv_uploads
                    set extraction_status = 'extracting',
                        parsing_error = null,
                        updated_at = now()
                    where id = :cv_upload_id
                    """
                ),
                {"cv_upload_id": cv_upload_id},
            )

    def mark_failed(self, *, cv_upload_id: str, error_message: str) -> None:
        with SessionLocal.begin() as session:
            session.execute(
                text(
                    """
                    update public.cv_uploads
                    set extraction_status = 'failed',
                        parsing_error = :parsing_error,
                        updated_at = now()
                    where id = :cv_upload_id
                    """
                ),
                {
                    "cv_upload_id": cv_upload_id,
                    "parsing_error": error_message[:2000],
                },
            )

    def mark_parsed(
        self,
        *,
        cv_upload_id: str,
        extracted_text: str,
        parser_engine: str,
    ) -> None:
        with SessionLocal.begin() as session:
            session.execute(
                text(
                    """
                    update public.cv_uploads
                    set extraction_status = 'parsed',
                        extracted_text = :extracted_text,
                        parser_engine = :parser_engine,
                        parsing_error = null,
                        updated_at = now()
                    where id = :cv_upload_id
                    """
                ),
                {
                    "cv_upload_id": cv_upload_id,
                    "extracted_text": extracted_text,
                    "parser_engine": parser_engine,
                },
            )
