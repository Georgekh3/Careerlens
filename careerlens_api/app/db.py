from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.config import settings


if not settings.database_url:
    raise RuntimeError("DATABASE_URL is not configured.")


engine = create_engine(settings.database_url, future=True)
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False, future=True)
