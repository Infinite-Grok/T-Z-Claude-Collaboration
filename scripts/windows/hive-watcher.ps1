# The Hive - Windows Watcher
# Watches for changes from Z and triggers sync
#
# Usage:
#   Run in PowerShell: .\hive-watcher.ps1
#
# Behavior:
#   - Detects when Z (Phone) modifies from-phone.md
#   - Creates sync trigger marker for Claude to detect

$SYNC_DIR = "C:\Users\pkoaw\claude-sync"
$WATCH_FILE = "from-phone.md"
$FULL_PATH = Join-Path $SYNC_DIR $WATCH_FILE
$TRIGGER_FILE = Join-Path $SYNC_DIR ".sync-trigger"
$LOG_FILE = Join-Path $SYNC_DIR "hive-watcher.log"

# Timing settings (match Z's setup)
$COOLDOWN = 10      # Don't re-trigger if processed recently (seconds)
$DEBOUNCE = 2       # Ignore rapid successive events (seconds)

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logLine = "[$timestamp] $Message"
    Write-Host $logLine
    Add-Content -Path $LOG_FILE -Value $logLine
}

# Verify watch file exists
if (-not (Test-Path $FULL_PATH)) {
    Write-Log "ERROR: Watch file not found: $FULL_PATH"
    exit 1
}

Write-Log "============================================"
Write-Log "     THE HIVE - T Node Watcher"
Write-Log "============================================"
Write-Log "Watching: $FULL_PATH"
Write-Log "Trigger: $TRIGGER_FILE"
Write-Log "Cooldown: ${COOLDOWN}s | Debounce: ${DEBOUNCE}s"
Write-Log ""
Write-Log "Waiting for Z to send messages..."
Write-Log ""

# Track last process time and file modification time
$script:lastProcessTime = Get-Date
$script:lastModTime = (Get-Item $FULL_PATH).LastWriteTime

# Create FileSystemWatcher
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $SYNC_DIR
$watcher.Filter = $WATCH_FILE
$watcher.EnableRaisingEvents = $true
$watcher.NotifyFilter = [System.IO.NotifyFilters]::LastWrite

# Define action for file changes - using -MessageData to pass variables
$action = {
    param($sender, $eventArgs)

    $syncDir = $Event.MessageData.SyncDir
    $logFile = $Event.MessageData.LogFile
    $cooldown = $Event.MessageData.Cooldown
    $debounce = $Event.MessageData.Debounce
    $fullPath = $eventArgs.FullPath

    # Log function within event handler
    function Local-WriteLog {
        param([string]$Message)
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logLine = "[$timestamp] $Message"
        Add-Content -Path $logFile -Value $logLine
    }

    try {
        # Let Syncthing finish writing
        Start-Sleep -Milliseconds 500

        Local-WriteLog "Change detected: $($eventArgs.ChangeType)"

        # Load Windows API for window manipulation
        Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;

public class WinAPI3 {
    [DllImport("user32.dll")]
    public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);

    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);

    [DllImport("user32.dll")]
    public static extern bool IsWindowVisible(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll", SetLastError = true)]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);

    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
}
"@  -IgnoreWarnings -ErrorAction SilentlyContinue

        # Load SendKeys
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue

        # Find Windows Terminal window (prioritize over plain PowerShell)
        $script:foundWindow = [IntPtr]::Zero
        $script:foundTitle = ""

        # First pass: look for Windows Terminal specifically
        $callback = {
            param([IntPtr]$hwnd, [IntPtr]$lParam)

            if ([WinAPI3]::IsWindowVisible($hwnd)) {
                $title = New-Object System.Text.StringBuilder 256
                [WinAPI3]::GetWindowText($hwnd, $title, $title.Capacity) | Out-Null
                $titleStr = $title.ToString()

                # Get the process ID
                $processId = 0
                [WinAPI3]::GetWindowThreadProcessId($hwnd, [ref]$processId) | Out-Null

                try {
                    $proc = Get-Process -Id $processId -ErrorAction SilentlyContinue
                    if ($proc -and $proc.ProcessName -eq "WindowsTerminal") {
                        # Found Windows Terminal!
                        $script:foundWindow = $hwnd
                        $script:foundTitle = $titleStr
                        return $false  # Stop enumeration
                    }
                } catch {}
            }
            return $true  # Continue enumeration
        }

        $enumDelegate = [WinAPI3+EnumWindowsProc]$callback
        [WinAPI3]::EnumWindows($enumDelegate, [IntPtr]::Zero) | Out-Null

        if ($script:foundWindow -eq [IntPtr]::Zero) {
            Local-WriteLog "WARNING: Could not find Windows Terminal window"
            Local-WriteLog "Make sure Claude is running in Windows Terminal (not plain PowerShell)"
            return
        }

        Local-WriteLog "Found terminal window: $($script:foundTitle)"
        $windowHandle = $script:foundWindow

        # Save current foreground window
        $previousWindow = [WinAPI3]::GetForegroundWindow()

        # Bring terminal to foreground
        [WinAPI3]::SetForegroundWindow($windowHandle) | Out-Null
        Start-Sleep -Milliseconds 300

        # Send the sync command - just use /sync skill
        $syncCommand = "/sync"
        [System.Windows.Forms.SendKeys]::SendWait($syncCommand)
        Start-Sleep -Milliseconds 100
        [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")

        Local-WriteLog ">>> Message from Z detected <<<"
        Local-WriteLog "Sent sync command to terminal"

        # Restore previous window
        Start-Sleep -Milliseconds 200
        if ($previousWindow -ne [IntPtr]::Zero) {
            [WinAPI3]::SetForegroundWindow($previousWindow) | Out-Null
        }

        Local-WriteLog ""
        Local-WriteLog "Waiting for Z..."
    }
    catch {
        Local-WriteLog "ERROR: $_"
    }
}

# Register event with message data
$messageData = @{
    SyncDir = $SYNC_DIR
    LogFile = $LOG_FILE
    Cooldown = $COOLDOWN
    Debounce = $DEBOUNCE
}
$job = Register-ObjectEvent -InputObject $watcher -EventName Changed -Action $action -MessageData $messageData

Write-Log "Daemon started. Press Ctrl+C to stop."
Write-Log ""

# Keep script running
try {
    while ($true) {
        Start-Sleep -Seconds 1

        # Optional: Check if trigger was consumed and log it
        if (Test-Path $TRIGGER_FILE) {
            $triggerAge = ((Get-Date) - (Get-Item $TRIGGER_FILE).LastWriteTime).TotalSeconds
            if ($triggerAge -gt 60) {
                # Trigger is old, might be stale
                # Don't log this every second, just occasionally
            }
        }
    }
}
finally {
    # Cleanup on exit
    Unregister-Event -SourceIdentifier $job.Name -ErrorAction SilentlyContinue
    $watcher.Dispose()
    Write-Log "Daemon stopped."
}
