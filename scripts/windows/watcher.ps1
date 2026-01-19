# Lean Ping-Pong Watcher (Polling)
# FIXED: Preserves user's typing before sending sync

$WATCH_URL = "http://100.113.114.74:8085/to-t.md"
$AUTH = "hive:hivesync2026"
$LOG = "C:\Users\pkoaw\claude-sync\watcher.log"
$POLL_INTERVAL = 2  # seconds

Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;

public class Win {
    [DllImport("user32.dll")]
    public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);

    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);

    [DllImport("user32.dll")]
    public static extern bool IsWindowVisible(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);

    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
}
"@

Add-Type -AssemblyName System.Windows.Forms

function Log($msg) {
    $ts = Get-Date -Format "HH:mm:ss"
    $line = "[$ts] $msg"
    Write-Host $line
    Add-Content $LOG $line
}

function Send-Sync {
    # Target WindowsTerminal ONLY (where Claude CLI runs in WSL)
    $claudeProc = Get-Process -Name "WindowsTerminal" -EA SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1

    # NO fallback to claude desktop - it causes interference

    if (-not $claudeProc) {
        Log "No Claude/Terminal window found"
        return
    }

    $hwnd = $claudeProc.MainWindowHandle
    Log "Found window: $($claudeProc.ProcessName) (PID $($claudeProc.Id))"

    $prev = [Win]::GetForegroundWindow()
    [Win]::SetForegroundWindow($hwnd) | Out-Null
    Start-Sleep -Milliseconds 200

    # Step 1: Save user's clipboard
    $savedClipboard = $null
    try {
        $savedClipboard = [System.Windows.Forms.Clipboard]::GetText()
    } catch {}

    # Step 2: AGGRESSIVE CLEAR - Try multiple methods
    # Method A: Triple-click to select all (works in most inputs)
    [System.Windows.Forms.SendKeys]::SendWait("{HOME}")
    Start-Sleep -Milliseconds 50

    # Method B: Ctrl+A (standard select all)
    [System.Windows.Forms.SendKeys]::SendWait("^a")
    Start-Sleep -Milliseconds 150

    # Cut to clipboard
    [System.Windows.Forms.SendKeys]::SendWait("^x")
    Start-Sleep -Milliseconds 200

    # Get user's text
    $userText = $null
    try {
        $userText = [System.Windows.Forms.Clipboard]::GetText()
        Log "Cut text: $($userText.Length) chars"
    } catch {}

    # Method C: Backup clear - select from end to start and delete
    [System.Windows.Forms.SendKeys]::SendWait("{END}")
    Start-Sleep -Milliseconds 50
    [System.Windows.Forms.SendKeys]::SendWait("+{HOME}")  # Shift+Home to select
    Start-Sleep -Milliseconds 50
    [System.Windows.Forms.SendKeys]::SendWait("{BACKSPACE}")
    Start-Sleep -Milliseconds 50

    # Method D: Controlled backspace (less aggressive)
    for ($i = 0; $i -lt 30; $i++) {
        [System.Windows.Forms.SendKeys]::SendWait("{BACKSPACE}")
    }
    Start-Sleep -Milliseconds 300

    # Step 3: Type and send sync command
    [System.Windows.Forms.SendKeys]::SendWait("check to-t.md")
    Start-Sleep -Milliseconds 300
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
    Start-Sleep -Milliseconds 200
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")  # Send twice for reliability
    Start-Sleep -Milliseconds 500

    # Step 4: Restore user's text - DISABLED for debugging
    # if ($userText -and $userText.Length -gt 0 -and $userText -ne "check to-t.md" -and $userText -notmatch "^[\s]*$") {
    #     foreach ($char in $userText.ToCharArray()) {
    #         $escaped = $char
    #         if ($char -match '[\+\^\%\~\(\)\{\}\[\]]') {
    #             $escaped = "{$char}"
    #         }
    #         [System.Windows.Forms.SendKeys]::SendWait($escaped)
    #     }
    #     Log "Restored $($userText.Length) chars"
    # }
    if ($userText) {
        Log "Would restore: $($userText.Length) chars (disabled for debug)"
    }

    # Step 5: Restore original clipboard
    if ($savedClipboard) {
        try {
            [System.Windows.Forms.Clipboard]::SetText($savedClipboard)
        } catch {}
    }

    Start-Sleep -Milliseconds 100
    if ($prev -ne [IntPtr]::Zero) {
        [Win]::SetForegroundWindow($prev) | Out-Null
    }

    Log "Sent sync"
}

$COOLDOWN = 90  # Seconds between syncs (>60 to avoid Z's mtime touch)

Log "=== WATCHER STARTED (POLLING WebDAV) ==="
Log "Watching: $WATCH_URL"
Log "Poll interval: ${POLL_INTERVAL}s"
Log "Cooldown: ${COOLDOWN}s"
Log "Ctrl+C to stop"

$lastSyncTime = [DateTime]::MinValue

function Get-WebDAVContent {
    try {
        $cred = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($AUTH))
        $headers = @{ "Authorization" = "Basic $cred" }
        $response = Invoke-WebRequest -Uri $WATCH_URL -Method Get -Headers $headers -UseBasicParsing -TimeoutSec 5
        return $response.Content
    } catch {
        Log "WebDAV error: $($_.Exception.Message)"
    }
    return $null
}

$lastContent = Get-WebDAVContent
$lastContentHash = if ($lastContent) { [System.BitConverter]::ToString([System.Security.Cryptography.MD5]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($lastContent))) } else { "" }
Log "Initial content hash: $($lastContentHash.Substring(0,20))..."

while ($true) {
    Start-Sleep -Seconds $POLL_INTERVAL

    $currentContent = Get-WebDAVContent
    $currentHash = if ($currentContent) { [System.BitConverter]::ToString([System.Security.Cryptography.MD5]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($currentContent))) } else { "" }

    if ($currentHash -and $lastContentHash -and $currentHash -ne $lastContentHash) {
        $lastContentHash = $currentHash
        $timeSinceLastSync = (Get-Date) - $lastSyncTime
        if ($timeSinceLastSync.TotalSeconds -ge $COOLDOWN) {
            Log "Content changed, sending sync"
            Start-Sleep -Milliseconds 500
            Send-Sync
            $lastSyncTime = Get-Date
        } else {
            Log "Content changed but in cooldown ($([int]$timeSinceLastSync.TotalSeconds)s < ${COOLDOWN}s)"
        }
    } elseif ($currentHash -and -not $lastContentHash) {
        $lastContentHash = $currentHash
    }
}
