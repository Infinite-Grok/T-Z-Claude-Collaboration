# Windows Auto-Sync Watcher
# Watches from-phone.md for changes and auto-triggers Claude /sync
# Run in PowerShell: .\auto-sync-windows.ps1

$script:syncDir = "C:\Users\pkoaw\claude-sync"
$script:watchFile = "from-phone.md"
$script:fullPath = Join-Path $script:syncDir $script:watchFile
$script:claudePath = "C:\Users\pkoaw\AppData\Roaming\npm\claude.cmd"

Write-Host "=== Windows Claude Auto-Sync Daemon ===" -ForegroundColor Cyan
Write-Host "Watching: $fullPath" -ForegroundColor Gray
Write-Host "Press Ctrl+C to stop" -ForegroundColor Gray
Write-Host ""

# Track last modification time to avoid duplicate triggers
$lastModTime = (Get-Item $fullPath).LastWriteTime

# Create file system watcher
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $syncDir
$watcher.Filter = $watchFile
$watcher.EnableRaisingEvents = $true
$watcher.NotifyFilter = [System.IO.NotifyFilters]::LastWrite

# Define the action to take when file changes
$action = {
    $path = $Event.SourceEventArgs.FullPath
    $changeType = $Event.SourceEventArgs.ChangeType
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    # Small delay to let Syncthing finish writing
    Start-Sleep -Milliseconds 500

    # Check if file actually changed (prevent duplicate triggers)
    $currentModTime = (Get-Item $path).LastWriteTime
    if ($currentModTime -eq $script:lastModTime) {
        Write-Host "[$timestamp] Duplicate event ignored (same mod time)" -ForegroundColor DarkGray
        return
    }
    $script:lastModTime = $currentModTime

    Write-Host "[$timestamp] Change detected in from-phone.md" -ForegroundColor Yellow
    Write-Host "[$timestamp] Triggering Claude /sync..." -ForegroundColor Green

    # Trigger sync via AutoHotkey (simulates VS Code input)
    $ahkPath = "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"
    $ahkScript = "C:\Users\pkoaw\claude-sync\auto-sync-trigger.ahk"

    try {
        # Run AutoHotkey script to trigger /sync in VS Code
        & $ahkPath $ahkScript
        Write-Host "[$timestamp] Sync triggered via AutoHotkey" -ForegroundColor Green
    }
    catch {
        Write-Host "[$timestamp] Error triggering sync: $_" -ForegroundColor Red
    }

    Write-Host ""
    Write-Host "Watching for next change..." -ForegroundColor Gray
}

# Register the event
$job = Register-ObjectEvent -InputObject $watcher -EventName Changed -Action $action

Write-Host "Daemon started. Waiting for changes..." -ForegroundColor Green
Write-Host ""

# Keep the script running
try {
    while ($true) {
        Start-Sleep -Seconds 1
    }
}
finally {
    # Cleanup on exit
    Unregister-Event -SourceIdentifier $job.Name
    $watcher.Dispose()
    Write-Host "Daemon stopped." -ForegroundColor Yellow
}
