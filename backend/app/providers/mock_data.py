from datetime import datetime, timedelta
MOCK_DISASTER_EVENTS = [
    {
        "event_id": "MOCK-FLOOD-001",
        "hazard_type": "Flood",
        "title": "Heavy Flooding in Kolkata",
        "description": "Heavy rainfall has caused flooding in several low-lying areas.",
        "latitude": 22.5726,
        "longitude": 88.3639,
        "severity": "High",
        "source": "MOCK",
        "event_time": datetime.utcnow() - timedelta(minutes=30)
    },
    {
        "event_id": "MOCK-CYCLONE-001",
        "hazard_type": "Cyclone",
        "title": "Cyclone Alert Near Bay of Bengal",
        "description": "A developing weather system may produce strong winds and heavy rainfall.",
        "latitude": 21.5,
        "longitude": 88.0,
        "severity": "Medium",
        "source": "MOCK",
        "event_time": datetime.utcnow() - timedelta(hours=2)
    }
]
