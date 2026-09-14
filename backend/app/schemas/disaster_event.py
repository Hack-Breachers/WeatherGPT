from datetime import datetime

from pydantic import BaseModel


class DisasterEventCreate(BaseModel):
    event_id: str
    hazard_type: str
    title: str
    description: str | None = None
    latitude: float
    longitude: float
    severity: str | None = None
    source: str
    event_time: datetime | None = None


class DisasterEventResponse(BaseModel):
    id: int
    event_id: str
    hazard_type: str
    title: str
    description: str | None
    latitude: float
    longitude: float
    severity: str | None
    source: str
    event_time: datetime | None
    created_at: datetime | None

    class Config:
        from_attributes = True
