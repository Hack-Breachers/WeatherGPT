import os
from pathlib import Path

from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker
from dotenv import load_dotenv


BASE_DIR = Path(__file__).resolve().parents[2]
ENV_FILE = BASE_DIR / ".env"

load_dotenv(ENV_FILE)

POSTGRES_DATABASE_URL = os.getenv("POSTGRES_DATABASE_URL")

if not POSTGRES_DATABASE_URL:
    raise RuntimeError(
        f"POSTGRES_DATABASE_URL is not set. Checked: {ENV_FILE}"
    )

postgres_engine = create_engine(
    POSTGRES_DATABASE_URL,
    pool_pre_ping=True
)

PostgresSessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=postgres_engine
)

PostgresBase = declarative_base()