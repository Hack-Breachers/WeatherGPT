import urllib.request
import json
from typing import Any


class OpenMeteoProvider:

    def get_weather(self, latitude: float, longitude: float) -> dict[str, Any]:

        url = (
            "https://api.open-meteo.com/v1/forecast"
            f"?latitude={latitude}"
            f"&longitude={longitude}"

            # Current weather
            "&current=temperature_2m,"
            "relative_humidity_2m,"
            "apparent_temperature,"
            "precipitation,"
            "precipitation_probability,"
            "weather_code,"
            "wind_speed_10m"

            # Hourly forecast
            "&hourly=temperature_2m,"
            "relative_humidity_2m,"
            "apparent_temperature,"
            "precipitation_probability,"
            "precipitation,"
            "weather_code,"
            "wind_speed_10m"

            # Daily forecast
            "&daily=temperature_2m_max,"
            "temperature_2m_min,"
            "precipitation_sum,"
            "precipitation_probability_max,"
            "weather_code"

            "&forecast_days=7"
            "&timezone=auto"
        )

        with urllib.request.urlopen(url) as response:
            data = json.loads(response.read().decode("utf-8"))

        return {
            "latitude": data["latitude"],
            "longitude": data["longitude"],
            "timezone": data["timezone"],
            "current": data["current"],
            "hourly": data["hourly"],
            "daily": data["daily"],
        }