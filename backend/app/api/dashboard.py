from typing import cast

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database.dependencies import get_db
from app.database.models import Location, DisasterEvent

from app.providers.weather_provider import OpenMeteoProvider

from app.services.geo_service import calculate_distance
from app.services.risk_service import calculate_risk


router = APIRouter(
    prefix="/api/dashboard",
    tags=["Dashboard"]
)


@router.get("/{location_id}")
def get_dashboard(
    location_id: int,
    db: Session = Depends(get_db)
):
    # Find location
    location = (
        db.query(Location)
        .filter(Location.id == location_id)
        .first()
    )

    if not location:
        return {
            "error": "Location not found"
        }

    # Get weather
    weather_provider = OpenMeteoProvider()

    weather = weather_provider.get_weather(
        cast(float, location.latitude),
        cast(float, location.longitude)
    )

    # Get all disaster events
    events = db.query(DisasterEvent).all()

    nearby_disasters = []

    for event in events:

        distance_km = calculate_distance(
            cast(float, event.latitude),
            cast(float, event.longitude),
            cast(float, location.latitude),
            cast(float, location.longitude)
        )

        # Only consider disasters within 250 km
        if distance_km > 250:
            continue

        risk = calculate_risk(
            event,
            distance_km
        )

        nearby_disasters.append({
            "event_id": event.id,
            "title": event.title,
            "hazard_type": event.hazard_type,
            "severity": event.severity,
            "distance_km": distance_km,
            "risk_score": risk["risk_score"],
            "risk_level": risk["risk_level"],
            "factors": risk["factors"]
        })

    # Highest risk first
    nearby_disasters.sort(
        key=lambda x: x["risk_score"],
        reverse=True
    )

    # Overall risk
    if nearby_disasters:
        highest_risk = nearby_disasters[0]
        overall_risk_score = highest_risk["risk_score"]
        overall_risk_level = highest_risk["risk_level"]
    else:
        overall_risk_score = 0
        overall_risk_level = "LOW"

    return {
        "location": {
            "id": location.id,
            "name": location.name,
            "latitude": location.latitude,
            "longitude": location.longitude
        },
        "weather": weather,
        "risk": {
            "risk_score": overall_risk_score,
            "risk_level": overall_risk_level
        },
        "nearby_disasters": nearby_disasters
    }
