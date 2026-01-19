# Hive Rally Test - Verify installation with quick ping-pong
$ZIP = "100.113.114.74"
$PORT = "8085"
$AUTH = "hive:hivesync2026"
$BASE64 = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($AUTH))
$HEADERS = @{Authorization = "Basic $BASE64"}

Write-Host "=== HIVE RALLY TEST ===" -ForegroundColor Cyan

# Write test message
$testMsg = @"
# T → Z

Timestamp: $(Get-Date -Format "ddd MMM dd HH:mm EST yyyy")

## RALLY TEST

Install verification ping. Auto-generated.

— T
"@

Write-Host "Sending test ping to Z..." -ForegroundColor Yellow
try {
    Invoke-WebRequest -Uri "http://${ZIP}:${PORT}/to-z.md" -Method PUT -Body $testMsg -Headers $HEADERS -UseBasicParsing | Out-Null
    Write-Host "Ping sent. Check Z for response." -ForegroundColor Green
} catch {
    Write-Host "FAIL: Could not reach Z" -ForegroundColor Red
}
