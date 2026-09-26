from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from argon2 import PasswordHasher
from argon2.exceptions import VerifyMismatchError

from app.database.postgres_dependencies import get_postgres_db
from app.database.officer_model import Officer


router = APIRouter(
    prefix="/api/officer",
    tags=["Officer Authentication"]
)

password_hasher = PasswordHasher()


class OfficerLoginRequest(BaseModel):
    username: str
    password: str


@router.post("/login")
def officer_login(
    login_data: OfficerLoginRequest,
    db: Session = Depends(get_postgres_db)
):
    officer = (
        db.query(Officer)
        .filter(Officer.username == login_data.username)
        .first()
    )

    if officer is None:
        raise HTTPException(
            status_code=401,
            detail="Invalid username or password."
        )

    try:
        password_hasher.verify(
            officer.password_hash,
            login_data.password
        )
    except VerifyMismatchError:
        raise HTTPException(
            status_code=401,
            detail="Invalid username or password."
        )

    return {
        "success": True,
        "message": "Officer login successful.",
        "username": officer.username
    }