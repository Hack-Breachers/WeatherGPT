$ErrorActionPreference = 'Stop'
$Repo = (Get-Location).Path

$files = @(
  @{ From = 'android/app/src/main/kotlin/com/example/flutter_application_2/MeshRelayService.kt'; To = 'android/app/src/main/kotlin/com/example/flutter_application_2/MeshRelayService.kt' },
  @{ From = 'android/app/src/main/kotlin/com/example/flutter_application_2/MainActivity.kt'; To = 'android/app/src/main/kotlin/com/example/flutter_application_2/MainActivity.kt' },
  @{ From = 'lib/emergency_sos_dialog.dart'; To = 'lib/emergency_sos_dialog.dart' }
)

foreach ($f in $files) {
  Copy-Item (Join-Path $PSScriptRoot $f.From) (Join-Path $Repo $f.To) -Force
}

# Patch the current backend SOS endpoint in-place while preserving the rest of main.py.
$backendPath = Join-Path $Repo 'backend/app/main.py'
$backend = Get-Content $backendPath -Raw

if ($backend -notmatch '_seen_sos_packet_ids') {
  $backend = $backend -replace '(?s)(@app\.post\("/api/v1/sos"\))', '_seen_sos_packet_ids = set()
_sos_status = {}

$1'
}
elseif ($backend -notmatch '_sos_status') {
  $backend = $backend -replace '(?s)(_seen_sos_packet_ids[^\r\n]*[\r\n]+)', '$1_sos_status = {}
'
}

$payloadBlock = @'
class SOSPayload(BaseModel):
    packet_id: str | None = None
    phone: str
    latitude: float
    longitude: float
    category: str = "STRANDED"
    severity: int = 4
    location_code: str = ""
    message: str = ""

'@
$backend = [regex]::Replace(
  $backend,
  '(?s)class SOSPayload\(BaseModel\):.*?(?=sos_records\s*=)',
  [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $payloadBlock }
)

$sosBlock = @'
@app.post("/api/v1/sos")
async def log_sos(payload: SOSPayload):
    packet_id = payload.packet_id

    if packet_id and packet_id in _seen_sos_packet_ids:
        _sos_status[packet_id] = "DELIVERED"
        return {
            "status": "DUPLICATE",
            "message": "SOS packet already registered",
            "packet_id": packet_id,
        }

    if packet_id:
        _seen_sos_packet_ids.add(packet_id)
        _sos_status[packet_id] = "DELIVERED"

    record = payload.model_dump()
    record["id"] = packet_id or f"SOS-{len(sos_records) + 1}"
    record["status"] = "DELIVERED"
    record["timestamp"] = datetime.utcnow().isoformat() + "Z"
    sos_records.append(record)

    return {
        "status": "SUCCESS",
        "message": "Beacon registered at District Control Hub",
        "packet_id": packet_id,
    }


@app.get("/api/v1/sos/{packet_id}")
async def get_sos_status(packet_id: str):
    if packet_id not in _seen_sos_packet_ids:
        raise HTTPException(status_code=404, detail="SOS packet not registered")

    return {
        "status": _sos_status.get(packet_id, "DELIVERED"),
        "packet_id": packet_id,
    }


'@
$backend = [regex]::Replace(
  $backend,
  '(?s)@app\.post\("/api/v1/sos"\).*?(?=@app\.get\("/api/v1/incidents"\))',
  [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $sosBlock }
)
Set-Content -Path $backendPath -Value $backend -Encoding UTF8

Write-Host ''
Write-Host 'Production Rescue Relay source files applied.' -ForegroundColor Green
Write-Host 'Backend change is intentionally kept as a focused patch:' -ForegroundColor Yellow
Write-Host '  backend/backend_sos_patch.md' -ForegroundColor Yellow
Write-Host ''
Write-Host 'Next verification commands:' -ForegroundColor Cyan
Write-Host '  flutter clean'
Write-Host '  flutter pub get'
Write-Host '  flutter analyze'
Write-Host '  flutter build apk --debug'
Write-Host ''
Write-Host 'Then inspect git diff before committing.' -ForegroundColor Cyan
