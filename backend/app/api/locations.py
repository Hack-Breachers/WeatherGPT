from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database.dependencies import get_db
from app.models.location import Location
from app.schemas.location import LocationCreate, LocationResponse

router = APIRouter(
    prefix="/api/locations",
    tags=["Locations"]
)


@router.get("/", response_model=list[LocationResponse])
def get_locations(db: Session = Depends(get_db)):
    locations = db.query(Location).all()

    return locations


@router.post("/", response_model=LocationResponse)
def create_location(
    location: LocationCreate,
    db: Session = Depends(get_db)
):
    new_location = Location(
        name=location.name,
        latitude=location.latitude,
        longitude=location.longitude
    )

    db.add(new_location)
    db.commit()
    db.refresh(new_location)

    return new_location
