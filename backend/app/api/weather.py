from fastapi import APIRouter

from app.providers.weather_provider import OpenMeteoProvider


router = APIRouter(
    prefix="/api/weather",
    tags=["Weather"]
)


@router.get("/")
def get_weather(
    latitude: float,
    longitude: float
):
    provider = OpenMeteoProvider()

    weather = provider.get_weather(
        latitude,
        longitude
    )

    return weather
