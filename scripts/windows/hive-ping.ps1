# Quick ping to Z - manually trigger sync check
$ZIP = "100.113.114.74"
$AUTH = "hive:hivesync2026"
$BASE64 = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($AUTH))

$msg = "# T → Z`n`nTimestamp: $(Get-Date -Format 'ddd MMM dd HH:mm EST yyyy')`n`n## PING`n`n— T"
Invoke-WebRequest -Uri "http://${ZIP}:8085/to-z.md" -Method PUT -Body $msg -Headers @{Authorization="Basic $BASE64"} -UseBasicParsing | Out-Null
Write-Host "Ping sent to Z"
