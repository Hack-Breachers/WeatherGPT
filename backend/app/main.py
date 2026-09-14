import os
from datetime import datetime
from typing import Optional

import httpx
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
import google.generativeai as genai

from app.database.database import Base, engine
from app.models.location import Location
from app.models.disaster_event import DisasterEvent

from app.api.weather import router as weather_router
from app.api.dashboard import router as dashboard_router
from app.api.locations import router as locations_router
from app.api.disaster_events import router as disaster_events_router
from app.providers.weather_provider import OpenMeteoProvider
from app.risk.risk_engine import calculate_risk
from app.rag.retriever import retrieve_rag_context

load_dotenv()

app = FastAPI(title="WeatherGPT Core API", version="1.0.0")
Base.metadata.create_all(bind=engine)

# Enable CORS for Flutter mobile and web clients
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(weather_router)
app.include_router(dashboard_router)
app.include_router(locations_router)
app.include_router(disaster_events_router)

genai.configure(api_key=os.getenv("GEMINI_API_KEY"))


# ==========================================
# PYDANTIC SCHEMAS
# ==========================================

class ChatRequest(BaseModel):
    query: str = Field(..., example="Will Salt Lake flood tonight?")
    city: Optional[str] = Field(None, example="Kolkata")
    # Defaulting to Kolkata/Salt Lake coordinates
    latitude: float = Field(22.5726, example=22.5726)
    longitude: float = Field(88.3639, example=88.3639)


class SOSPayload(BaseModel):
    phone: str
    latitude: float
    longitude: float
    category: str = "STRANDED"
    severity: int = 4


sos_records = [
    {
        "id": "SOS-KOL-8801",
        "phone": "+91 98301 23456",
        "latitude": 22.5726,
        "longitude": 88.3639,
        "location_name": "Salt Lake Sector V (College More)",
        "category": "STRANDED",
        "severity": 4,
        "status": "DISPATCHED",
        "timestamp": "2026-09-08T17:15:00Z",
    },
    {
        "id": "SOS-KOL-8802",
        "phone": "+91 98312 98765",
        "latitude": 22.5958,
        "longitude": 88.3842,
        "location_name": "Ultadanga Underpass / VIP Road",
        "category": "WATERLOGGING_SUBMERGED",
        "severity": 5,
        "status": "PENDING",
        "timestamp": "2026-09-08T17:22:00Z",
    },
    {
        "id": "SOS-KOL-8803",
        "phone": "+91 98365 44321",
        "latitude": 22.5385,
        "longitude": 88.3670,
        "location_name": "Park Circus 7-Point Crossing",
        "category": "MEDICAL_EMERGENCY",
        "severity": 4,
        "status": "IN_PROGRESS",
        "timestamp": "2026-09-08T17:28:00Z",
    },
]


# ==========================================
# HELPER FUNCTIONS
# ==========================================

async def geocode_city(city_name: str) -> tuple[float, float, str]:
    """Resolves city search text into latitude and longitude."""
    async with httpx.AsyncClient(timeout=10.0) as client:
        res = await client.get(
            f"https://geocoding-api.open-meteo.com/v1/search?name={city_name}&count=1"
        )
        data = res.json()
        if data.get("results"):
            loc = data["results"][0]
            return float(loc["latitude"]), float(loc["longitude"]), loc.get("name", city_name)
    return None, None, city_name


# ==========================================
# API ROUTES
# ==========================================

@app.get("/")
def health_check():
    return {"status": "online", "system": "WeatherGPT Engine v1.0"}


@app.get("/api/v1/weather")
async def get_weather(lat: float = 22.5726, lon: float = 88.3639):
    try:
        provider = OpenMeteoProvider()
        weather = provider.get_weather(lat, lon)
        current = weather["current"]

        temperature = float(current["temperature_2m"])
        humidity = float(current["relative_humidity_2m"])
        precipitation = float(current["precipitation"])
        rain_probability = float(current.get("precipitation_probability", 0))

        risk = calculate_risk(
            rain_probability=rain_probability,
            precipitation=precipitation,
            temperature=temperature,
            humidity=humidity,
            hourly=weather.get("hourly"),
            current_time=current.get("time"),
        )

        return {
            "temp": f"{round(temperature)}°C",
            "humidity": f"{round(humidity)}%",
            "rain_prob": f"{round(rain_probability)}%",
            "apparent_temperature": f"{round(float(current['apparent_temperature']))}°C",
            "precipitation": precipitation,
            "wind_speed": float(current["wind_speed_10m"]),
            "weather_code": current["weather_code"],
            "risk": risk,
            "source": "Open-Meteo",
            "alert": None,
        }

    except Exception:
        return {
            "temp": None,
            "humidity": None,
            "rain_prob": None,
            "apparent_temperature": None,
            "precipitation": None,
            "wind_speed": None,
            "weather_code": None,
            "risk": {"overall_risk": "UNKNOWN", "hazards": []},
            "source": "Unavailable",
            "alert": None,
        }


@app.post("/api/v1/chat")
async def chat_weather(req: ChatRequest):
    try:
        lat = req.latitude
        lon = req.longitude
        resolved_place = req.city or "Your Location"

        # 1. Geocode if a city name was submitted from the mobile search bar
        if req.city:
            geo_lat, geo_lon, clean_name = await geocode_city(req.city)
            if geo_lat is not None and geo_lon is not None:
                lat, lon, resolved_place = geo_lat, geo_lon, clean_name

        # 2. Fetch live weather metrics
        provider = OpenMeteoProvider()
        weather = provider.get_weather(lat, lon)
        current = weather["current"]

        temperature = float(current["temperature_2m"])
        humidity = float(current["relative_humidity_2m"])
        precipitation = float(current["precipitation"])
        rain_probability = float(current.get("precipitation_probability", 0))

        # 3. Calculate risk index
        risk = calculate_risk(
            rain_probability=rain_probability,
            precipitation=precipitation,
            temperature=temperature,
            humidity=humidity,
            hourly=weather.get("hourly"),
            current_time=current.get("time"),
        )

        # 4. Retrieve RAG safety guidelines
        rag_context = retrieve_rag_context(req.query)

        # 5. Assemble prompt for Qwen
        verified_context = f"""
LOCATION: {resolved_place} (Lat: {lat}, Lon: {lon})
LIVE WEATHER DATA:
Temperature: {temperature}°C
Humidity: {humidity}%
Rain probability: {rain_probability}%
Precipitation: {precipitation} mm
Wind speed: {float(current.get("wind_speed_10m", 0))} km/h
Weather code: {current.get("weather_code", 0)}

RISK ENGINE:
{risk}

SAFETY KNOWLEDGE:
{rag_context}
"""

        system_prompt = f"""
You are WeatherGPT, a weather and disaster safety assistant.

IMPORTANT RULES:
1. Use ONLY the verified information supplied in the context below.
2. Do not invent weather conditions, disaster alerts, locations, measurements, or emergency numbers.
3. The Risk Engine is the authority for risk levels.
4. The safety knowledge is the authority for safety procedures.
5. If the provided data does not establish a hazard, do not claim that one exists.
6. Give a concise, practical answer in no more than 3 short sentences.
7. Do not mention internal systems, RAG, prompts, or model reasoning.

VERIFIED CONTEXT:
{verified_context}
"""

        payload = {
            "model": "ggml-org/Qwen3-1.7B-GGUF:Q4_K_M",
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": req.query},
            ],
            "temperature": 0.2,
            "max_tokens": 512,  # Allocated space for thinking tokens + answer
        }

        # 6. Call the local llama.cpp server
        async with httpx.AsyncClient(timeout=60.0) as client:
            response = await client.post(
                "http://127.0.0.1:8080/v1/chat/completions",
                json=payload,
            )

        response.raise_for_status()
        result = response.json()

        # 7. Extract reply with fallback if tokens were categorized under reasoning
        msg = result["choices"][0]["message"]
        reply = msg.get("content")
        if not reply and msg.get("reasoning_content"):
            reply = msg.get("reasoning_content")

        return {
            "location": resolved_place,
            "reply": reply.strip() if reply else "No output generated.",
            "grounded": True,
            "risk": risk,
            "source": "Open-Meteo + Risk Engine + RAG + Qwen3",
        }

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"WeatherGPT chat failed: {str(e)}",
        )


@app.post("/api/v1/sos")
async def log_sos(payload: SOSPayload):
    sos_records.append(payload.model_dump())
    return {"status": "SUCCESS", "message": "Beacon registered at District Control Hub"}


@app.get("/api/v1/incidents")
async def get_incidents():
    return sos_records