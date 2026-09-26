from sqlalchemy import Column, Integer, String, DateTime
from datetime import datetime

from app.database.database_postgres import PostgresBase


class OTPVerification(PostgresBase):
    __tablename__ = "otp_verifications"

    id = Column(Integer, primary_key=True, index=True)

    mobile_number = Column(
        String(20),
        nullable=False,
        index=True
    )

    otp_code = Column(
        String(10),
        nullable=False
    )

    expires_at = Column(
        DateTime,
        nullable=False
    )

    verified = Column(
        Integer,
        nullable=False,
        default=0
    )

    created_at = Column(
        DateTime,
        default=datetime.utcnow,
        nullable=False
    )