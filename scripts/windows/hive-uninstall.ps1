# Hive Uninstaller for Windows
param([switch]$KeepData)

Write-Host "=== HIVE UNINSTALLER ===" -ForegroundColor Red

if (-not $KeepData) {
    Write-Host "WARNING: This will remove ALL Hive data!" -ForegroundColor Yellow
    $confirm = Read-Host "Type 'UNINSTALL' to confirm"
    if ($confirm -ne "UNINSTALL") {
        Write-Host "Aborted." -ForegroundColor Green
        exit 0
    }
}

# Stop and remove task
Write-Host "Removing scheduled task..." -ForegroundColor Yellow
Stop-ScheduledTask -TaskName "HiveWatcher" -ErrorAction SilentlyContinue
Unregister-ScheduledTask -TaskName "HiveWatcher" -Confirm:$false -ErrorAction SilentlyContinue

# Remove startup shortcut
Write-Host "Removing startup shortcut..." -ForegroundColor Yellow
Remove-Item "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\HiveWatcher.bat" -Force -ErrorAction SilentlyContinue

if (-not $KeepData) {
    Write-Host "Removing data folder..." -ForegroundColor Yellow
    Remove-Item "$env:USERPROFILE\claude-sync" -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "Uninstall complete." -ForegroundColor Green
