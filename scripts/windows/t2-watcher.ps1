# T² Watcher - Monitors T²'s WebDAV output and triggers T
# Part of Project Genesis infrastructure

$Config = @{
    WebDAV_URL = "http://100.113.114.74:8085/t2-to-t.md"
    WebDAV_User = "hive"
    WebDAV_Pass = "hivesync2026"
    PollInterval = 5  # seconds
    Cooldown = 30     # seconds between triggers
    LogFile = "$env:USERPROFILE\claude-sync\logs\t2-watcher.log"
}

$lastHash = ""
$lastTrigger = [DateTime]::MinValue

function Write-Log($msg) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $msg" | Out-File -Append $Config.LogFile
    Write-Host "$timestamp - $msg"
}

function Get-WebDAVContent {
    try {
        $cred = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($Config.WebDAV_User):$($Config.WebDAV_Pass)"))
        $headers = @{ Authorization = "Basic $cred" }
        $response = Invoke-WebRequest -Uri $Config.WebDAV_URL -Headers $headers -UseBasicParsing -ErrorAction Stop
        return $response.Content
    } catch {
        return $null
    }
}

function Get-ContentHash($content) {
    if (-not $content) { return "" }
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($content)
    $hash = [System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes)
    return [BitConverter]::ToString($hash) -replace '-',''
}

function Trigger-T {
    # Use same mechanism as main watcher - send to Claude terminal
    $ahkPath = "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"
    $ahkScript = "$env:USERPROFILE\claude-sync\scripts\windows\t2-trigger.ahk"
    if (Test-Path $ahkScript) {
        if (Test-Path $ahkPath) {
            Start-Process $ahkPath -ArgumentList $ahkScript
            Write-Log "Triggered T via AHK"
        } else {
            Write-Log "ERROR: AutoHotkey not found at $ahkPath"
        }
    } else {
        Write-Log "ERROR: t2-trigger.ahk not found"
    }
}

Write-Log "=== T² Watcher Started ==="
Write-Log "Monitoring: $($Config.WebDAV_URL)"

while ($true) {
    $content = Get-WebDAVContent
    $currentHash = Get-ContentHash $content

    if ($currentHash -ne $lastHash -and $currentHash -ne "") {
        $timeSinceTrigger = (Get-Date) - $lastTrigger

        if ($timeSinceTrigger.TotalSeconds -ge $Config.Cooldown) {
            Write-Log ">>> T² message detected <<<"
            $lastHash = $currentHash
            $lastTrigger = Get-Date
            Trigger-T
        } else {
            Write-Log "Change detected but in cooldown ($([int]$timeSinceTrigger.TotalSeconds)s / $($Config.Cooldown)s)"
        }
    }

    Start-Sleep -Seconds $Config.PollInterval
}
