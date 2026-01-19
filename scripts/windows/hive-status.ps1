# Hive Quick Status - One-line summary
$ZIP = "100.113.114.74"
$AUTH = "hive:hivesync2026"
$BASE64 = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($AUTH))

$watcher = (Get-ScheduledTask -TaskName HiveWatcher -EA SilentlyContinue).State
$ping = if (Test-Connection $ZIP -Count 1 -Quiet) { "OK" } else { "FAIL" }

try {
    $r = Invoke-WebRequest -Uri "http://${ZIP}:8085/to-t.md" -Headers @{Authorization="Basic $BASE64"} -TimeoutSec 3 -UseBasicParsing
    $last = if ($r.Content -match "Timestamp: (.+)") { $Matches[1] } else { "?" }
} catch { $last = "FAIL" }

Write-Host "Hive: Watcher=$watcher | Ping=$ping | Last=$last"
