# Hive Health Check for Windows (T Node)
# Run: powershell -File hive-health.ps1

$ZIP = "100.113.114.74"
$PORT = "8085"
$AUTH = "hive:hivesync2026"
$BASE64 = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($AUTH))

Write-Host "=== HIVE HEALTH CHECK ===" -ForegroundColor Cyan
Write-Host ""

# 1. Watcher Task
Write-Host -NoNewline "Watcher Task: "
$task = Get-ScheduledTask -TaskName "HiveWatcher" -ErrorAction SilentlyContinue
if ($task -and $task.State -eq "Running") {
    Write-Host "RUNNING" -ForegroundColor Green
} elseif ($task) {
    Write-Host "$($task.State)" -ForegroundColor Yellow
} else {
    Write-Host "NOT FOUND" -ForegroundColor Red
}

# 2. Tailscale
Write-Host -NoNewline "Tailscale: "
$ts = tailscale status 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "CONNECTED" -ForegroundColor Green
} else {
    Write-Host "DISCONNECTED" -ForegroundColor Red
}

# 3. Ping Z
Write-Host -NoNewline "Ping to Z: "
if (Test-Connection -ComputerName $ZIP -Count 1 -Quiet) {
    Write-Host "OK" -ForegroundColor Green
} else {
    Write-Host "FAIL" -ForegroundColor Red
}

# 4. WebDAV
Write-Host -NoNewline "WebDAV: "
try {
    $r = Invoke-WebRequest -Uri "http://${ZIP}:${PORT}/" -Headers @{Authorization="Basic $BASE64"} -TimeoutSec 5 -UseBasicParsing
    Write-Host "OK" -ForegroundColor Green
} catch {
    Write-Host "FAIL" -ForegroundColor Red
}

# 5. Last sync
Write-Host -NoNewline "Last to-t.md: "
try {
    $content = Invoke-WebRequest -Uri "http://${ZIP}:${PORT}/to-t.md" -Headers @{Authorization="Basic $BASE64"} -TimeoutSec 5 -UseBasicParsing
    $match = [regex]::Match($content.Content, "Timestamp: (.+)")
    if ($match.Success) {
        Write-Host $match.Groups[1].Value -ForegroundColor Cyan
    } else {
        Write-Host "Unknown" -ForegroundColor Yellow
    }
} catch {
    Write-Host "FAIL" -ForegroundColor Red
}

Write-Host ""
Write-Host "=========================" -ForegroundColor Cyan
