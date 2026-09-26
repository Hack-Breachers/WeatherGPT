from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database.postgres_dependencies import get_postgres_db
from app.database.rescue_member_model import RescueMember


router = APIRouter(
    prefix="/api/rescue-community",
    tags=["Rescue Community"]
)


@router.post("/register")
def register_rescue_member(
    full_name: str,
    mobile_number: str,
    blood_group: str,
    latitude: float,
    longitude: float,
    skills: str = "",
    db: Session = Depends(get_postgres_db)
):
    existing_member = (
        db.query(RescueMember)
        .filter(RescueMember.mobile_number == mobile_number)
        .first()
    )

    if existing_member:
        return {
            "success": False,
            "message": "This mobile number is already registered."
        }

    member = RescueMember(
        full_name=full_name,
        mobile_number=mobile_number,
        blood_group=blood_group,
        latitude=latitude,
        longitude=longitude,
        skills=skills,
        mobile_verified=0
    )

    db.add(member)
    db.commit()
    db.refresh(member)

    return {
        "success": True,
        "message": "Rescue Community member registered successfully.",
        "member_id": member.id
    }