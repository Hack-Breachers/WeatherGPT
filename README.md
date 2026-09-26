# WeatherGPT 🌦️

> Conversational AI for Weather Forecasting, Disaster Awareness, and Safety Guidance

WeatherGPT is an **SIH 2026** prototype that combines a Flutter mobile application with a FastAPI backend to provide location-aware weather conversations, deterministic weather-risk assessment, verified safety guidance, and an emergency SOS/Rescue Relay workflow.

**SIH Problem Statement:** 26068 — WeatherGPT: Conversational AI for Weather Forecasting, Alerts, and Climate Information  
**Team:** Hack-Breachers

## ✨ Core Features

- 💬 Conversational weather assistant
- 📍 Location-aware queries
- 🌦️ Live weather data through Open-Meteo
- ⚠️ Deterministic Risk Engine
- 📚 RAG-based safety protocols
- 🤖 Local Qwen3-1.7B GGUF through llama.cpp
- 🌍 English, Hindi, and Bengali UI support
- 🌐 GDACS disaster-event integration
- 🚨 SOS / Rescue Relay workflow
- 💾 SQLite database
- 🏛️ Citizen and Government-oriented interfaces

## 🧠 AI & Safety Pipeline

WeatherGPT separates **risk calculation** from **language generation**:

```text
User Query
    ↓
Location Resolution
    ↓
Live Weather Data
    ↓
Risk Engine
    ↓
Verified Hazards
    ↓
RAG Safety Protocols
    ↓
Verified Context
    ↓
Local Qwen3-1.7B
    ↓
Conversational Response
```

The **Risk Engine is the authority for risk levels**. The LLM does not independently decide whether a hazard exists. RAG supplies the safety procedures used to ground the response.

## 🏗️ Architecture

```text
Flutter App
    │
    │ HTTP
    ▼
FastAPI Backend
    ├── Weather Provider ── Open-Meteo
    ├── Risk Engine
    ├── RAG Retriever ───── Safety Protocol JSON
    ├── Disaster Events ─── GDACS
    ├── SOS / Rescue APIs
    └── SQLite
          │
          ▼
     llama.cpp
          │
          ▼
     Qwen3-1.7B
```

## 🛠️ Technology Stack

**Frontend**
- Flutter / Dart
- Geolocation
- Shared Preferences
- Android native integration

**Backend**
- Python
- FastAPI / Uvicorn
- Pydantic
- SQLAlchemy
- SQLite

**AI**
- Qwen3-1.7B GGUF Q4_K_M
- llama.cpp
- Retrieval-Augmented Generation
- Deterministic Risk Engine

**Data**
- Open-Meteo
- GDACS
- Local safety-protocol JSON files

## 📁 Main Project Structure

```text
WeatherGPT/
├── lib/                         # Flutter application
├── android/                     # Android/native integration
├── backend/
│   ├── app/
│   │   ├── api/
│   │   ├── database/
│   │   ├── providers/
│   │   ├── rag/
│   │   ├── risk/
│   │   ├── schemas/
│   │   └── services/
│   └── requirements.txt
├── docs/
├── assets/
├── APPLY_PRODUCTION_MESH.ps1
├── MERGE_TO_MAIN.ps1
├── pubspec.yaml
└── README.md
```

## 🚀 Local Setup

### 1. Clone

```powershell
git clone https://github.com/Hack-Breachers/WeatherGPT.git
cd WeatherGPT
```

### 2. Flutter

```powershell
flutter pub get
flutter analyze
flutter run
```

### 3. Backend

From the project root:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
cd backend
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

FastAPI documentation:

```text
http://127.0.0.1:8000/docs
```

### 4. Qwen / llama.cpp

The GGUF model is **not included** in the repository.

After installing llama.cpp and obtaining the model, start the local server:

```powershell
llama serve -hf ggml-org/Qwen3-1.7B-GGUF:Q4_K_M --device none
```

The backend communicates with:

```text
http://127.0.0.1:8080/v1/chat/completions
```

## 📱 Physical Android Testing

For local phone testing, connect the phone and backend computer to the same Wi-Fi network.

Find the computer's IPv4 address:

```powershell
ipconfig
```

Use the computer's LAN address for the Flutter backend URL, for example:

```text
http://192.168.1.4:8000
```

Do not use `127.0.0.1` on the phone because it refers to the phone itself.

## 🌐 GDACS

WeatherGPT includes a live GDACS provider at:

```text
backend/app/providers/gdacs_provider.py
```

It retrieves recent disaster events from the GDACS API and maps event types such as:

```text
EQ → Earthquake
TC → Cyclone
FL → Flood
VO → Volcano
WF → Wildfire
DR → Drought
```

## 🚨 SOS / Rescue Relay

The application includes an emergency SOS workflow with packet information such as:

- Packet ID
- Phone number
- Latitude / longitude
- Category
- Severity
- Location information
- Message

The Android side includes native relay components, while the FastAPI backend handles SOS registration and duplicate packet detection.

## 💾 Database

The current runtime database is **SQLite**:

```text
sqlite:///./weathergpt.db
```

PostgreSQL-related implementation files are also present for future deployment/migration work, and `psycopg[binary]` is included in `backend/requirements.txt`.

## 🔐 Security / Submission Notes

Do not commit:

- API keys
- Passwords
- `.env` files
- Private credentials
- Local databases
- GGUF model files
- Generated build artifacts

The repository's `.gitignore` excludes the relevant local/generated files.

## 🧪 Validation

Before committing changes:

```powershell
flutter pub get
flutter analyze
python -m compileall -q backend/app
git status
```

## 📚 Documentation

- FastAPI Swagger: `http://127.0.0.1:8000/docs`
- Architecture and project documentation are maintained with the project deliverables.
- A separate User Manual and prototype demonstration are planned as submission materials.

## ⚠️ Prototype Scope

WeatherGPT is an SIH prototype. Live weather and GDACS data depend on external services; local Qwen inference requires the separate model and llama.cpp runtime; physical-phone testing currently uses LAN connectivity; and the Rescue Relay infrastructure is a prototype emergency-communication implementation.

---

**Hack-Breachers · WeatherGPT · SIH 2026**
