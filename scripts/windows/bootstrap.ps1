# Hive One-Line Bootstrap for Windows
# Usage: irm https://raw.githubusercontent.com/.../bootstrap.ps1 | iex
# Or: powershell -c "irm http://100.113.114.74:8085/scripts/windows/bootstrap.ps1 -Headers @{Authorization='Basic aGl2ZTpoaXZlc3luYzIwMjY='} | iex"

$ErrorActionPreference = "Stop"

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "  HIVE ZERO-TOUCH BOOTSTRAP" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$ZIP = "100.113.114.74"
$PORT = "8085"
$AUTH = "hive:hivesync2026"
$BASE64 = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($AUTH))
$HEADERS = @{Authorization = "Basic $BASE64"}

# Download installer
Write-Host "[1/3] Downloading installer..." -ForegroundColor Yellow
$installerUrl = "http://${ZIP}:${PORT}/scripts/windows/install-hive.ps1"
$installerPath = "$env:TEMP\install-hive.ps1"

try {
    Invoke-WebRequest -Uri $installerUrl -Headers $HEADERS -OutFile $installerPath -UseBasicParsing
    Write-Host "[OK] Installer downloaded" -ForegroundColor Green
} catch {
    Write-Host "[FAIL] Could not download installer: $_" -ForegroundColor Red
    Write-Host "Is Z's WebDAV running? Try: curl -u hive:hivesync2026 http://${ZIP}:${PORT}/" -ForegroundColor Yellow
    exit 1
}

# Run installer
Write-Host "[2/3] Running installer..." -ForegroundColor Yellow
& powershell -ExecutionPolicy Bypass -File $installerPath

# Cleanup
Write-Host "[3/3] Cleanup..." -ForegroundColor Yellow
Remove-Item $installerPath -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "=====================================" -ForegroundColor Green
Write-Host "  HIVE BOOTSTRAP COMPLETE" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
