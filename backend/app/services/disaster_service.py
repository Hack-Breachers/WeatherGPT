from sqlalchemy.orm import Session

from app.models.disaster_event import DisasterEvent


def save_disaster_events(db: Session, events: list[dict]):
    saved_events = []
    updated_events = []

    for event in events:

        existing_event = (
            db.query(DisasterEvent)
            .filter(
                DisasterEvent.event_id == event["event_id"]
            )
            .first()
        )

        # Existing event → update it
        if existing_event:

            existing_event.hazard_type = str(event["hazard_type"])  # type: ignore
            existing_event.title = str(event["title"])  # type: ignore
            existing_event.description = str(event.get("description", ""))  # type: ignore
            existing_event.latitude = float(event["latitude"])  # type: ignore
            existing_event.longitude = float(event["longitude"])  # type: ignore
            existing_event.severity = str(event.get("severity", "Low"))  # type: ignore
            existing_event.source = str(event["source"])  # type: ignore
            existing_event.event_time = event.get("event_time")  # type: ignore

            updated_events.append(existing_event)

        # New event → create it
        else:

            disaster_event = DisasterEvent(
                event_id=str(event["event_id"]),
                hazard_type=str(event["hazard_type"]),
                title=str(event["title"]),
                description=str(event.get("description", "")),
                latitude=float(event["latitude"]),
                longitude=float(event["longitude"]),
                severity=str(event.get("severity", "Low")),
                source=str(event["source"]),
                event_time=event.get("event_time"),
            )

            db.add(disaster_event)
            saved_events.append(disaster_event)

    db.commit()

    return saved_events, updated_events
