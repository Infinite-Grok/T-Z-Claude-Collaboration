# Protocol v3.0 Auto-Archival Script
# Archives old messages from trigger files, keeping only last 20

$fromWindows = "C:\Users\pkoaw\claude-sync\from-windows.md"
$fromPhone = "C:\Users\pkoaw\claude-sync\from-phone.md"
$archiveDir = "C:\Users\pkoaw\claude-sync\archive"
$archiveWindows = "$archiveDir\from-windows-2026-01.md"
$archivePhone = "$archiveDir\from-phone-2026-01.md"
$archiveIndex = "$archiveDir\index.md"

# Ensure archive directory exists
New-Item -ItemType Directory -Force -Path $archiveDir | Out-Null

# Function to split messages
function Split-Messages {
    param([string]$filePath)

    $content = Get-Content $filePath -Raw
    if (-not $content) {
        return @()
    }

    # Split by message boundaries (triple dash on its own line)
    $parts = $content -split '(?m)^---\s*$'

    # Recombine into full messages (each starting with ---)
    $messages = @()
    for ($i = 1; $i -lt $parts.Count; $i++) {
        if ($parts[$i].Trim()) {
            $messages += "---`n" + $parts[$i]
        }
    }

    # Handle any header before first message
    $header = $parts[0].Trim()

    return @{
        header = $header
        messages = $messages
    }
}

# Process from-windows.md
Write-Host "Processing from-windows.md..."
$windowsData = Split-Messages $fromWindows
$windowsCount = $windowsData.messages.Count
Write-Host "  Total messages: $windowsCount"

if ($windowsCount -gt 20) {
    $toArchive = $windowsData.messages[0..($windowsCount - 21)]
    $toKeep = $windowsData.messages[($windowsCount - 20)..($windowsCount - 1)]

    Write-Host "  Archiving: $($toArchive.Count) messages"
    Write-Host "  Keeping: $($toKeep.Count) messages"

    # Create archive file with summary
    $archiveSummary = @"
# Archived Messages from Windows Claude (T)
# Archive Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm')
# Protocol: v3.0 Auto-Archival

## Summary
This archive contains the first $($toArchive.Count) messages from the Windows Claude (T) trigger file.
Archived as part of Protocol v3.0 to prevent context bloat.

**Archive Period:** 2026-01-16 to 2026-01-17
**Total Archived Messages:** $($toArchive.Count)
**Retention Policy:** Keep last 20 messages in trigger file

## Key Topics in Archive:
- Initial art piece collaboration
- /sync command setup and testing
- Protocol v2.1 implementation
- Git corruption incident and resolution
- Immutable files rule v2.2
- GitHub publishing preparation
- HTML collaboration document (v1.0-v1.4)
- AutoHotkey coordinate calibration

---

"@

    $archiveSummary + ($toArchive -join "`n`n") | Set-Content $archiveWindows

    # Update trigger file
    if ($windowsData.header) {
        $windowsData.header + "`n`n" + ($toKeep -join "`n`n") | Set-Content $fromWindows
    } else {
        $toKeep -join "`n`n" | Set-Content $fromWindows
    }
} else {
    Write-Host "  No archival needed (less than 20 messages)"
}

# Process from-phone.md
Write-Host "`nProcessing from-phone.md..."
$phoneData = Split-Messages $fromPhone
$phoneCount = $phoneData.messages.Count
Write-Host "  Total messages: $phoneCount"

if ($phoneCount -gt 20) {
    $toArchive = $phoneData.messages[0..($phoneCount - 21)]
    $toKeep = $phoneData.messages[($phoneCount - 20)..($phoneCount - 1)]

    Write-Host "  Archiving: $($toArchive.Count) messages"
    Write-Host "  Keeping: $($toKeep.Count) messages"

    # Create archive file with summary
    $archiveSummary = @"
# Archived Messages from Phone Claude (Z)
# Archive Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm')
# Protocol: v3.0 Auto-Archival

## Summary
This archive contains the first $($toArchive.Count) messages from the Phone Claude (Z) trigger file.
Archived as part of Protocol v3.0 to prevent context bloat.

**Archive Period:** 2026-01-17
**Total Archived Messages:** $($toArchive.Count)
**Retention Policy:** Keep last 20 messages in trigger file

---

"@

    $archiveSummary + ($toArchive -join "`n`n") | Set-Content $archivePhone

    # Update trigger file
    if ($phoneData.header) {
        $phoneData.header + "`n`n" + ($toKeep -join "`n`n") | Set-Content $fromPhone
    } else {
        $toKeep -join "`n`n" | Set-Content $fromPhone
    }
} else {
    Write-Host "  No archival needed (less than 20 messages)"
}

# Create index
$indexContent = @"
# Archive Index
# Protocol v3.0 Auto-Archival System

## Overview
This directory contains archived messages from the Claude-to-Claude communication system.
Messages are archived automatically when trigger files exceed 20 messages.

## Archive Files

### from-windows-2026-01.md
- **Source:** Windows Claude (T)
- **Created:** $(Get-Date -Format 'yyyy-MM-dd')
- **Messages Archived:** $(if ($windowsCount -gt 20) { $windowsCount - 20 } else { "N/A" })
- **Period:** 2026-01-16 to 2026-01-17

### from-phone-2026-01.md
- **Source:** Phone Claude (Z)
- **Created:** $(Get-Date -Format 'yyyy-MM-dd')
- **Messages Archived:** $(if ($phoneCount -gt 20) { $phoneCount - 20 } else { "N/A" })
- **Period:** 2026-01-17

## Retention Policy
- **Trigger files:** Keep last 20 messages
- **Archive files:** Keep indefinitely
- **Archival frequency:** Automatic when threshold exceeded

## Protocol Version
v3.0 - Auto-archival with summaries
"@

$indexContent | Set-Content $archiveIndex

Write-Host "`nArchival complete!"
Write-Host "Archive directory: $archiveDir"
