$ErrorActionPreference = "Stop"

# Run this script from the WeatherGPT repository root.
$repo = Get-Location
$branch = (git branch --show-current).Trim()

Write-Host "=== WeatherGPT production Rescue Relay merge ===" -ForegroundColor Cyan
Write-Host "Repository: $repo"
Write-Host "Current branch: $branch"

if ([string]::IsNullOrWhiteSpace($branch)) {
    throw "Could not determine the current Git branch."
}

Write-Host "`nRunning Flutter analysis..." -ForegroundColor Cyan
flutter analyze

Write-Host "`nBuilding debug APK..." -ForegroundColor Cyan
flutter build apk --debug

Write-Host "`nChecking backend Python syntax..." -ForegroundColor Cyan
Push-Location backend
python -m py_compile app/main.py
Pop-Location

Write-Host "`nStaging production Rescue Relay files..." -ForegroundColor Cyan
git add android/app/src/main/kotlin/com/example/flutter_application_2/MainActivity.kt
git add android/app/src/main/kotlin/com/example/flutter_application_2/MeshRelayService.kt
git add lib/emergency_sos_dialog.dart
git add backend/app/main.py

git diff --cached --quiet
if ($LASTEXITCODE -eq 0) {
    Write-Host "No staged changes to commit." -ForegroundColor Yellow
} else {
    git commit -m "feat: production rescue relay SOS delivery"
}

Write-Host "`nFetching origin..." -ForegroundColor Cyan
git fetch origin

if ($branch -eq "main") {
    Write-Host "Already on main. Updating and pushing..." -ForegroundColor Cyan
    git pull --ff-only origin main
    git push origin main
} else {
    Write-Host "`nSwitching to main..." -ForegroundColor Cyan
    git checkout main

    Write-Host "Updating local main..." -ForegroundColor Cyan
    git pull --ff-only origin main

    Write-Host "Merging $branch into main..." -ForegroundColor Cyan
    git merge $branch

    Write-Host "Pushing main..." -ForegroundColor Cyan
    git push origin main
}

Write-Host "`n=== Production Rescue Relay changes are on main ===" -ForegroundColor Green
git status
