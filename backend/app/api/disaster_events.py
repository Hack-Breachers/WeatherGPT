from typing import cast
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.models.location import Location
from app.services.geo_service import calculate_distance
from app.database.dependencies import get_db
from app.models.disaster_event import DisasterEvent
from app.providers.factory import get_disaster_provider
from app.services.disaster_service import save_disaster_events
from app.services.risk_service import calculate_risk
from app.schemas.risk import RiskSummaryItem
from app.schemas.disaster_event import (
    DisasterEventCreate,
    DisasterEventResponse
)

router = APIRouter(
    prefix="/api/disaster-events",
    tags=["Disaster Events"]
)


@router.get("/", response_model=list[DisasterEventResponse])
def get_disaster_events(db: Session = Depends(get_db)):
    events = db.query(DisasterEvent).all()

    return events

@router.post("/", response_model=DisasterEventResponse)
def create_disaster_event(
    event: DisasterEventCreate,
    db: Session = Depends(get_db)
):
    existing_event = (
        db.query(DisasterEvent)
        .filter(DisasterEvent.event_id == event.event_id)
        .first()
    )

    if existing_event:
        return existing_event

    new_event = DisasterEvent(
        event_id=event.event_id,
        hazard_type=event.hazard_type,
        title=event.title,
        description=event.description,
        latitude=event.latitude,
        longitude=event.longitude,
        severity=event.severity,
        source=event.source,
        event_time=event.event_time
    )

    db.add(new_event)
    db.commit()
    db.refresh(new_event)

    return new_event


@router.post("/sync")
def sync_disaster_events(db: Session = Depends(get_db)):
    provider = get_disaster_provider()

    events = provider.get_disaster_events()

    saved_events, updated_events = save_disaster_events(
    db,
    events
)

    return {
    "message": "Disaster events synchronized successfully",
    "events_received": len(events),
    "new_events_saved": len(saved_events),
    "existing_events_updated": len(updated_events)
}
    
    
@router.get("/summary/{location_id}", response_model=list[RiskSummaryItem])
def get_risk_summary(
    location_id: int,
    db: Session = Depends(get_db)
):
    location = (
        db.query(Location)
        .filter(Location.id == location_id)
        .first()
    )

    if not location:
        return []
    
    events = db.query(DisasterEvent).all()

    results = []

    for event in events:
        distance_km = calculate_distance(
            cast(float, event.latitude),
            cast(float, event.longitude),
            cast(float, location.latitude),
            cast(float, location.longitude)
        )

        if distance_km> 250:
            continue
        
        risk = calculate_risk(
            event,
            distance_km
        )

        results.append({
            "event_id": event.id,
            "title": event.title,
            "hazard_type": event.hazard_type,
            "distance_km": distance_km,
            "risk_score": risk["risk_score"],
            "risk_level": risk["risk_level"],
            "factors": risk["factors"]
        })


    results.sort(key=lambda x: x["risk_score"], reverse=True)

    return results


@router.get("/{event_id}/risk")
def get_event_risk(
    event_id: int,
    location_id: int,
    db: Session = Depends(get_db)
):
    event = (
        db.query(DisasterEvent)
        .filter(DisasterEvent.id == event_id)
        .first()
    )

    if not event:
        return {
            "error": "Disaster event not found"
        }

    location = (
        db.query(Location)
        .filter(Location.id == location_id)
        .first()
    )

    if not location:
        return {
            "error": "Location not found"
        }

    distance_km = calculate_distance(
    cast(float, event.latitude),
    cast(float, event.longitude),
    cast(float, location.latitude),
    cast(float, location.longitude)
)

    risk = calculate_risk(
        event,
        distance_km
    )

    return {
        "event_id": event.id,
        "location_id": location.id,
        "distance_km": distance_km,
        **risk
    }


