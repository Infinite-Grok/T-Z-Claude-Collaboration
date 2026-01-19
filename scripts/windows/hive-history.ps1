# Hive Message History
param([int]$Count = 10)
$ZIP = "100.113.114.74"
$AUTH = "hive:hivesync2026"
$BASE64 = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($AUTH))
$HEADERS = @{Authorization = "Basic $BASE64"}

Write-Host "=== RECENT MESSAGES ===" -ForegroundColor Cyan

# Get to-t.md
Write-Host "`n--- FROM Z (to-t.md) ---" -ForegroundColor Yellow
try {
    $r = Invoke-WebRequest -Uri "http://${ZIP}:8085/to-t.md" -Headers $HEADERS -UseBasicParsing
    $r.Content | Select-Object -First 30
} catch { Write-Host "Error reading" -ForegroundColor Red }

# Get to-z.md
Write-Host "`n--- FROM T (to-z.md) ---" -ForegroundColor Yellow
try {
    $r = Invoke-WebRequest -Uri "http://${ZIP}:8085/to-z.md" -Headers $HEADERS -UseBasicParsing
    $r.Content | Select-Object -First 30
} catch { Write-Host "Error reading" -ForegroundColor Red }
