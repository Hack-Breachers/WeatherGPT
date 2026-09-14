from datetime import datetime, timezone

def calculate_risk(event, distance_km=None):
    score = 0
    factors = []

    # Recency-based scoring
    if event.event_time is not None:

        now = datetime.now(timezone.utc)

        event_time = event.event_time

        if event_time.tzinfo is None:
            event_time = event_time.replace(tzinfo=timezone.utc)

        age_hours = (
            now - event_time
        ).total_seconds() / 3600

        if age_hours <= 1:
            score += 10
            factors.append("Event occurred within the last hour")

        elif age_hours <= 6:
            score += 7
            factors.append("Event occurred within the last 6 hours")

        elif age_hours <= 24:
            score += 4
            factors.append("Event occurred within the last 24 hours")

    # Severity-based scoring
    if event.severity == "High":
        score += 40
        factors.append("High severity event")

    elif event.severity == "Medium":
        score += 25
        factors.append("Medium severity event")

    elif event.severity == "Low":
        score += 10
        factors.append("Low severity event")

    # Hazard-based scoring
    if event.hazard_type.lower() == "flood":
        score += 20
        factors.append("Flood hazard detected")

    elif event.hazard_type.lower() == "cyclone":
        score += 30
        factors.append("Cyclone hazard detected")

    elif event.hazard_type.lower() == "earthquake":
        score += 35
        factors.append("Earthquake hazard detected")

    # Distance-based scoring
    if distance_km is not None:

        if distance_km <= 25:
            score += 30
            factors.append("Disaster is within 25 km")

        elif distance_km <= 100:
            score += 20
            factors.append("Disaster is within 100 km")

        elif distance_km <= 250:
            score += 10
            factors.append("Disaster is within 250 km")

        else:
            factors.append("Disaster is more than 250 km away")

    # Maximum score
    score = min(score, 100)

    # Risk level
    if score >= 80:
        risk_level = "CRITICAL"

    elif score >= 60:
        risk_level = "HIGH"

    elif score >= 30:
        risk_level = "MEDIUM"

    else:
        risk_level = "LOW"

    return {
        "risk_score": score,
        "risk_level": risk_level,
        "factors": factors
    }
