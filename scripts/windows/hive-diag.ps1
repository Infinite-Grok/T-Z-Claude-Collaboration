# Hive Diagnostic Dump
# Collects system info for debugging

$OUT = "$env:USERPROFILE\claude-sync\logs\diag-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"

Write-Host "Collecting diagnostics to $OUT" -ForegroundColor Cyan

$diag = @"
=== HIVE DIAGNOSTIC DUMP ===
Date: $(Get-Date)
User: $env:USERNAME
Computer: $env:COMPUTERNAME

=== HIVE VERSION ===
$(Get-Content "$env:USERPROFILE\claude-sync\VERSION" -ErrorAction SilentlyContinue)

=== WATCHER TASK ===
$(Get-ScheduledTask -TaskName HiveWatcher -ErrorAction SilentlyContinue | Format-List | Out-String)

=== WATCHER LOG (last 50 lines) ===
$(Get-Content "$env:USERPROFILE\claude-sync\watcher.log" -Tail 50 -ErrorAction SilentlyContinue)

=== NETWORK ===
Tailscale: $(tailscale status 2>&1 | Select-Object -First 5 | Out-String)

=== FOLDER STRUCTURE ===
$(Get-ChildItem "$env:USERPROFILE\claude-sync" -Recurse -Name -ErrorAction SilentlyContinue | Select-Object -First 30)

=== END DIAGNOSTIC ===
"@

$diag | Out-File $OUT -Encoding UTF8
Write-Host "Saved to: $OUT" -ForegroundColor Green
