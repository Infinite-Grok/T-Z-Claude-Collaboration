# Hive Full Connection Test
$ZIP = "100.113.114.74"
$AUTH = "hive:hivesync2026"
$BASE64 = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($AUTH))
$HEADERS = @{Authorization = "Basic $BASE64"}
$PASS = 0; $FAIL = 0

function Test-Item($name, $test) {
    Write-Host -NoNewline "$name`: "
    try {
        if (& $test) { Write-Host "PASS" -ForegroundColor Green; $script:PASS++ }
        else { Write-Host "FAIL" -ForegroundColor Red; $script:FAIL++ }
    } catch { Write-Host "ERROR" -ForegroundColor Red; $script:FAIL++ }
}

Write-Host "=== HIVE CONNECTION TEST ===" -ForegroundColor Cyan
Test-Item "Tailscale IP" { Test-Connection $ZIP -Count 1 -Quiet }
Test-Item "WebDAV root" { (Invoke-WebRequest "http://${ZIP}:8085/" -Headers $HEADERS -TimeoutSec 5 -UseBasicParsing).StatusCode -eq 200 }
Test-Item "Read to-t.md" { (Invoke-WebRequest "http://${ZIP}:8085/to-t.md" -Headers $HEADERS -TimeoutSec 5 -UseBasicParsing).Content.Length -gt 0 }
Test-Item "Write test" { Invoke-WebRequest "http://${ZIP}:8085/.test" -Method PUT -Body "test" -Headers $HEADERS -UseBasicParsing; $true }
Test-Item "Delete test" { Invoke-WebRequest "http://${ZIP}:8085/.test" -Method DELETE -Headers $HEADERS -UseBasicParsing -EA SilentlyContinue; $true }

Write-Host "`nResults: $PASS passed, $FAIL failed" -ForegroundColor $(if ($FAIL -eq 0) {"Green"} else {"Red"})
