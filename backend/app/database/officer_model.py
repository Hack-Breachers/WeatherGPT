from sqlalchemy import Column, Integer, String, DateTime
from datetime import datetime

from app.database.database_postgres import PostgresBase


class Officer(PostgresBase):
    __tablename__ = "officer_accounts"

    id = Column(Integer, primary_key=True, index=True)

    username = Column(
        String(100),
        unique=True,
        nullable=False,
        index=True
    )

    password_hash = Column(
        String(255),
        nullable=False
    )

    created_at = Column(
        DateTime,
        default=datetime.utcnow,
        nullable=False
    )