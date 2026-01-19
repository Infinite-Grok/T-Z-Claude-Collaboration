# Hive Auto-Update for Windows (T Node)
# Downloads latest scripts from Z's WebDAV

$ZIP = "100.113.114.74"
$PORT = "8085"
$AUTH = "hive:hivesync2026"
$BASE64 = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($AUTH))
$HEADERS = @{Authorization = "Basic $BASE64"}
$BASE = "$env:USERPROFILE\claude-sync\scripts\windows"

Write-Host "=== HIVE AUTO-UPDATE ===" -ForegroundColor Cyan

$scripts = @("watcher.ps1", "hive-health.ps1", "install-hive.ps1", "bootstrap.ps1")

foreach ($script in $scripts) {
    Write-Host -NoNewline "Updating $script... "
    try {
        $url = "http://${ZIP}:${PORT}/scripts/windows/$script"
        Invoke-WebRequest -Uri $url -Headers $HEADERS -OutFile "$BASE\$script" -UseBasicParsing
        Write-Host "OK" -ForegroundColor Green
    } catch {
        Write-Host "SKIP (not on server)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Update complete. Restart watcher to apply changes:" -ForegroundColor Cyan
Write-Host "  Stop-ScheduledTask HiveWatcher; Start-ScheduledTask HiveWatcher" -ForegroundColor Yellow
