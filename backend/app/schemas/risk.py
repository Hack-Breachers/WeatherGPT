from pydantic import BaseModel

class RiskResponse(BaseModel):
    risk_score: int
    risk_level: str
    factors: list[str]


class RiskSummaryItem(BaseModel):
    event_id: int
    title: str
    hazard_type: str
    distance_km: float
    risk_score: int
    risk_level: str
    factors: list[str]
