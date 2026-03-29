from sqlalchemy import text

from app.db import SessionLocal
from app.schemas.profile import StructuredProfile


class InterviewPreparationRepository:
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

            return StructuredProfile.model_validate(row["authoritative_profile"])
