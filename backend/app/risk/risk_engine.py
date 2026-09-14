def calculate_risk(
    rain_probability: float,
    precipitation: float,
    temperature: float,
    humidity: float,
    hourly: dict | None = None,
    current_time: str | None = None,
):
    """
    Weather-condition risk engine.

    Uses current weather plus the next few hours of forecast
    when hourly forecast data is available.
    """

    hazards = []
    
    forecast_probabilities = []
    forecast_precipitation = []
    forecast_codes = []

    max_rain_probability = 0
    total_forecast_rain = 0
    high_probability_hours = 0
    # ---------------------------------------------------------
    # CURRENT WEATHER
    # ---------------------------------------------------------

    if rain_probability >= 80 and precipitation >= 10:
        hazards.append({
            "type": "HEAVY_RAIN",
            "level": "HIGH",
            "timing": "CURRENT",
            "reason": "Heavy rainfall is currently being observed."
        })

    elif rain_probability >= 60:
        hazards.append({
            "type": "HEAVY_RAIN",
            "level": "MEDIUM",
            "timing": "CURRENT",
            "reason": "Moderate-to-high probability of rainfall is currently present."
        })

    # ---------------------------------------------------------
    # FORECAST ANALYSIS
    # ---------------------------------------------------------

    if hourly:
        probabilities = hourly.get("precipitation_probability", [])
        precipitation_values = hourly.get("precipitation", [])
        weather_codes = hourly.get("weather_code", [])
        times = hourly.get("time", [])

# ---------------------------------------------------------
# Find the current forecast hour
# ---------------------------------------------------------

        start_index = 0

        if current_time and times:
            current_hour = current_time[:13]

            for index, forecast_time in enumerate(times):
                if forecast_time[:13] >= current_hour:
                    start_index = index
                    break

# Analyse the current hour + next 5 hours.
        forecast_probabilities = probabilities[
            start_index:start_index + 6
        ]

        forecast_precipitation = precipitation_values[
            start_index:start_index + 6
        ]

        forecast_codes = weather_codes[
            start_index:start_index + 6
        ]

        max_rain_probability = (
            max(forecast_probabilities)
            if forecast_probabilities
            else 0
        )

        total_forecast_rain = sum(forecast_precipitation)

        high_probability_hours = sum(
            1 for value in forecast_probabilities
            if value >= 70
        )

        # -----------------------------------------------------
        # FORECAST HEAVY RAIN
        # -----------------------------------------------------

        if (
            max_rain_probability >= 80
            and total_forecast_rain >= 10
        ):
            hazards.append({
                "type": "FORECAST_HEAVY_RAIN",
                "level": "HIGH",
                "timing": "UPCOMING",
                "reason": (
                    "High rainfall probability with significant "
                    "forecast precipitation in the next 6 hours."
                )
        })

        elif high_probability_hours >= 3:
            hazards.append({
                "type": "FORECAST_HEAVY_RAIN",
                "level": "MEDIUM",
                "timing": "UPCOMING",
                "reason": (
                    "Rainfall is likely across multiple upcoming "
                    "hours."
                )
        })

        # -----------------------------------------------------
        # POTENTIAL URBAN WATERLOGGING
        # -----------------------------------------------------

        if total_forecast_rain >= 30:
            hazards.append({
                "type": "URBAN_FLOOD",
                "level": "HIGH",
                "timing": "UPCOMING",
                "reason": (
                    "Forecast precipitation exceeds 30 mm over "
                    "the next 6 hours and may cause urban "
                    "waterlogging."
                )
        })

        elif total_forecast_rain >= 15:
            hazards.append({
                "type": "URBAN_FLOOD",
                "level": "MEDIUM",
                "timing": "UPCOMING",
                "reason": (
                    "Forecast rainfall may cause localized "
                    "urban waterlogging."
                )
            })

        # -----------------------------------------------------
        # THUNDERSTORM
        # -----------------------------------------------------

        # Open-Meteo WMO codes:
        # 95 = thunderstorm
        # 96 = thunderstorm with hail
        # 99 = thunderstorm with heavy hail

        thunderstorm_codes = [95, 96, 99]

        thunderstorm_detected = any(
            code in thunderstorm_codes
            for code in forecast_codes
        )

        if thunderstorm_detected:

            max_thunderstorm_precipitation = 0

            for index, code in enumerate(forecast_codes):
                if code in thunderstorm_codes:
                    if index < len(forecast_precipitation):
                        max_thunderstorm_precipitation = max(
                            max_thunderstorm_precipitation,
                            forecast_precipitation[index]
                        )

            hail_detected = any(
                code in [96, 99]
                for code in forecast_codes
            )

            if (
                hail_detected
                or max_thunderstorm_precipitation >= 10
            ):
                thunderstorm_level = "HIGH"
                thunderstorm_reason = (
                    "Strong thunderstorm conditions, including "
                    "hail or significant precipitation, are "
                    "present in the upcoming 6-hour forecast."
                )

            else:
                thunderstorm_level = "MEDIUM"
                thunderstorm_reason = (
                    "Thunderstorm conditions are present in "
                    "the upcoming 6-hour forecast."
                )

            hazards.append({
                "type": "THUNDERSTORM",
                "level": thunderstorm_level,
                "timing": "UPCOMING",
                "reason": thunderstorm_reason
            })

    # ---------------------------------------------------------
    # HEAT RISK
    # ---------------------------------------------------------

    if temperature >= 40 and humidity >= 40:
        hazards.append({
            "type": "HEATWAVE",
            "level": "HIGH",
            "timing": "CURRENT",
            "reason": (
                "High temperature combined with elevated "
                "humidity may create heat stress."
            )
        })

    elif temperature >= 37:
        hazards.append({
            "type": "HEATWAVE",
            "level": "MEDIUM",
            "timing": "CURRENT",
            "reason": (
                "Elevated temperature may create heat stress."
            )
        })

    # ---------------------------------------------------------
    # OVERALL RISK
    # ---------------------------------------------------------

    levels = [hazard["level"] for hazard in hazards]

    if "HIGH" in levels:
        overall_risk = "HIGH"

    elif "MEDIUM" in levels:
        overall_risk = "MEDIUM"

    else:
        overall_risk = "LOW"

    forecast_summary = {
    "window_hours": 6,
    "max_rain_probability": 0,
    "total_precipitation": 0,
    "high_probability_hours": 0,
}

    if hourly:
        forecast_summary = {
            "window_hours": len(forecast_probabilities),
            "max_rain_probability": max_rain_probability,
            "total_precipitation": round(total_forecast_rain, 1),
            "high_probability_hours": high_probability_hours,
    }

    return {
        "overall_risk": overall_risk,
        "hazards": hazards,
        "forecast_summary": forecast_summary,
    }