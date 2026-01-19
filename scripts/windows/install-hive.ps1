# Hive Zero-Touch Installer for Windows
# Run: powershell -ExecutionPolicy Bypass -File install-hive.ps1
# Requires: Admin rights for Tailscale, user rights for rest

param(
    [string]$ZTailscaleIP = "100.113.114.74",
    [string]$WebDAVPort = "8085",
    [string]$WebDAVUser = "hive",
    [string]$WebDAVPass = "hivesync2026"
)

$ErrorActionPreference = "Stop"
$BaseDir = "$env:USERPROFILE\claude-sync"
$ScriptsDir = "$BaseDir\scripts\windows"
$LogFile = "$BaseDir\install.log"

function Log {
    param([string]$Message)
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$ts] $Message"
    Write-Host $line
    Add-Content -Path $LogFile -Value $line -ErrorAction SilentlyContinue
}

function Test-Tailscale {
    Log "Checking Tailscale..."
    $ts = Get-Command tailscale -ErrorAction SilentlyContinue
    if (-not $ts) {
        Log "ERROR: Tailscale not installed. Install from https://tailscale.com/download"
        return $false
    }

    $status = tailscale status 2>&1
    if ($LASTEXITCODE -ne 0) {
        Log "ERROR: Tailscale not connected. Run 'tailscale up' first."
        return $false
    }
    Log "Tailscale: OK"
    return $true
}

function Test-ZConnectivity {
    Log "Testing connectivity to Z ($ZTailscaleIP)..."
    $ping = Test-Connection -ComputerName $ZTailscaleIP -Count 1 -Quiet
    if (-not $ping) {
        Log "ERROR: Cannot ping Z at $ZTailscaleIP"
        return $false
    }
    Log "Ping to Z: OK"

    Log "Testing WebDAV..."
    try {
        $cred = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${WebDAVUser}:${WebDAVPass}"))
        $response = Invoke-WebRequest -Uri "http://${ZTailscaleIP}:${WebDAVPort}/" -Headers @{Authorization = "Basic $cred"} -TimeoutSec 5 -UseBasicParsing
        Log "WebDAV: OK"
        return $true
    } catch {
        Log "ERROR: WebDAV not reachable. Is Z's WebDAV server running?"
        return $false
    }
}

function Initialize-FolderStructure {
    Log "Creating folder structure..."

    $folders = @(
        $BaseDir,
        $ScriptsDir,
        "$BaseDir\memory",
        "$BaseDir\handoff",
        "$BaseDir\logs"
    )

    foreach ($folder in $folders) {
        if (-not (Test-Path $folder)) {
            New-Item -ItemType Directory -Path $folder -Force | Out-Null
            Log "Created: $folder"
        }
    }
    Log "Folder structure: OK"
}

function Install-Watcher {
    Log "Installing watcher script..."

    $watcherPath = "$ScriptsDir\watcher.ps1"
    $watcherUrl = "http://${ZTailscaleIP}:${WebDAVPort}/scripts/windows/watcher.ps1"

    try {
        $cred = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${WebDAVUser}:${WebDAVPass}"))
        $response = Invoke-WebRequest -Uri $watcherUrl -Headers @{Authorization = "Basic $cred"} -TimeoutSec 10 -UseBasicParsing
        Set-Content -Path $watcherPath -Value $response.Content -Encoding UTF8
        Log "Downloaded watcher.ps1"
    } catch {
        Log "WARNING: Could not download watcher from WebDAV. Creating default..."
        # Create minimal watcher if download fails
        $defaultWatcher = @'
# Hive Watcher - Minimal Version
$WATCH_URL = "http://100.113.114.74:8085/to-t.md"
$AUTH = "hive:hivesync2026"
$POLL_INTERVAL = 2
$COOLDOWN = 90

Write-Host "Watcher starting... (minimal version)"
Write-Host "Please download full version from Z"
'@
        Set-Content -Path $watcherPath -Value $defaultWatcher -Encoding UTF8
    }
    Log "Watcher script: OK"
}

function Register-WatcherTask {
    Log "Registering scheduled task..."

    $taskName = "HiveWatcher"
    $scriptPath = "$ScriptsDir\watcher.ps1"

    # Remove existing task
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue

    # Create new task
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`""
    $trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Description "Hive T-Z WebDAV Watcher"
    Log "Scheduled task: OK"
}

function Install-StartupShortcut {
    Log "Creating startup shortcut..."

    $startupPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\HiveWatcher.bat"
    $content = @"
@echo off
start /min powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File "$ScriptsDir\watcher.ps1"
"@
    Set-Content -Path $startupPath -Value $content
    Log "Startup shortcut: OK"
}

function Show-Summary {
    Log "=========================================="
    Log "HIVE INSTALLATION COMPLETE"
    Log "=========================================="
    Log "Base directory: $BaseDir"
    Log "Watcher script: $ScriptsDir\watcher.ps1"
    Log "Scheduled task: HiveWatcher"
    Log "Z connection: $ZTailscaleIP:$WebDAVPort"
    Log ""
    Log "To start watcher now: Start-ScheduledTask -TaskName HiveWatcher"
    Log "To check status: Get-ScheduledTask -TaskName HiveWatcher"
    Log "=========================================="
}

# Main installation flow
Log "=========================================="
Log "HIVE ZERO-TOUCH INSTALLER FOR WINDOWS"
Log "=========================================="

if (-not (Test-Tailscale)) {
    Log "Installation aborted: Tailscale required"
    exit 1
}

if (-not (Test-ZConnectivity)) {
    Log "WARNING: Z not reachable. Continuing with offline install..."
}

Initialize-FolderStructure
Install-Watcher
Register-WatcherTask
Install-StartupShortcut
Show-Summary

Log "Starting watcher..."
Start-ScheduledTask -TaskName "HiveWatcher"
Log "Watcher started. Installation complete."
