from sqlalchemy import Column, Integer, String, Float, DateTime, Text
from datetime import datetime

from app.database.database_postgres import PostgresBase


class RescueMember(PostgresBase):
    __tablename__ = "rescue_members"

    id = Column(Integer, primary_key=True, index=True)

    full_name = Column(String(150), nullable=False)

    mobile_number = Column(String(20), unique=True, nullable=False, index=True)

    blood_group = Column(String(10), nullable=False)

    latitude = Column(Float, nullable=False)

    longitude = Column(Float, nullable=False)

    skills = Column(Text, nullable=True)

    mobile_verified = Column(
        Integer,
        nullable=False,
        default=0
    )

    created_at = Column(
        DateTime,
        default=datetime.utcnow,
        nullable=False
    )