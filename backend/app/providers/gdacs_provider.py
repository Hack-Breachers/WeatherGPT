import urllib.request
import json
from datetime import datetime, timedelta, timezone
from typing import Any

from app.providers.base import DisasterProvider


class GDACSProvider(DisasterProvider):

    def get_disaster_events(self) -> list[dict[str, Any]]:

        # Get today's date automatically
        today = datetime.now(timezone.utc).date()

        # Get events from the previous 7 days
        from_date = today - timedelta(days=7)

        from_date_str = from_date.isoformat()
        to_date_str = today.isoformat()

        url = (
            "https://www.gdacs.org/gdacsapi/api/events/"
            "geteventlist/SEARCH"
            "?eventlist=EQ%3BTC%3BFL%3BVO%3BWF%3BDR"
            f"&fromdate={from_date_str}"
            f"&todate={to_date_str}"
            "&alertlevel=green%3Borange%3Bred"
        )

        with urllib.request.urlopen(url) as response:
            data = json.loads(
                response.read().decode("utf-8")
            )

        events = []

        for feature in data.get("features", []):

            properties = feature.get("properties", {})
            geometry = feature.get("geometry", {})

            coordinates = geometry.get("coordinates", [])

            if len(coordinates) < 2:
                continue

            longitude = coordinates[0]
            latitude = coordinates[1]

            event_time = None

            if properties.get("fromdate"):
                event_time = datetime.fromisoformat(
                    properties["fromdate"]
                )

            # GDACS alert level
            alert_level = properties.get(
                "alertlevel",
                "Unknown"
            )

            # Convert GDACS alert level to our internal severity
            severity_map = {
                "Green": "Low",
                "Orange": "Medium",
                "Red": "High",
            }

            severity = severity_map.get(
                alert_level,
                "Low"
            )

            # Convert GDACS event type to our internal hazard type
            hazard_map = {
                "EQ": "Earthquake",
                "TC": "Cyclone",
                "FL": "Flood",
                "VO": "Volcano",
                "WF": "Wildfire",
                "DR": "Drought",
            }

            hazard_type = hazard_map.get(
                properties.get("eventtype"),
                "Other"
            )

            event = {
                "event_id": f"GDACS-{properties.get('eventid')}",
                "hazard_type": hazard_type,
                "title": properties.get("name", ""),
                "description": properties.get("description", ""),
                "latitude": latitude,
                "longitude": longitude,
                "severity": severity,
                "source": "GDACS",
                "event_time": event_time,
            }

            events.append(event)

        return events
