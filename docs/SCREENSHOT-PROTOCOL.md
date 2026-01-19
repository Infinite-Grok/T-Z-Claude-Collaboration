# Screenshot Protocol

## Problem
Large screenshots (especially from high-res devices like Z Fold) cause API errors:
```
API Error: 400 "Could not process image"
```

## Required Protocol

**ALWAYS resize screenshots before viewing.** Never try to Read a raw screenshot directly.

### Step 1: Capture
```bash
ADB="/mnt/c/Users/pkoaw/AppData/Local/Android/Sdk/platform-tools/adb.exe"
$ADB exec-out screencap -p > /tmp/screen-raw.png
```

### Step 2: Resize (MANDATORY)

**WSL/Windows (PowerShell .NET) - TESTED & WORKING:**
```bash
powershell.exe -Command "
Add-Type -AssemblyName System.Drawing
\$img = [System.Drawing.Image]::FromFile('C:\\Users\\pkoaw\\claude-sync\\screen-test.png')
\$ratio = 600 / \$img.Width
\$newW = [int](\$img.Width * \$ratio)
\$newH = [int](\$img.Height * \$ratio)
\$bmp = New-Object System.Drawing.Bitmap \$newW, \$newH
\$g = [System.Drawing.Graphics]::FromImage(\$bmp)
\$g.DrawImage(\$img, 0, 0, \$newW, \$newH)
\$bmp.Save('C:\\Users\\pkoaw\\claude-sync\\screen-small.png')
\$g.Dispose(); \$bmp.Dispose(); \$img.Dispose()
Write-Host 'Resized to' \$newW 'x' \$newH
"
```

**If ImageMagick available:**
```bash
convert /tmp/screen-raw.png -resize 800x /tmp/screen-view.png
```

### Step 3: View
```bash
# Only AFTER resizing - use the RESIZED file
Read /path/to/screen-small.png
```

## Complete Working Flow (WSL)
```bash
ADB="/mnt/c/Users/pkoaw/AppData/Local/Android/Sdk/platform-tools/adb.exe"
# 1. Capture on device
$ADB shell screencap /sdcard/screen.png
# 2. Pull to Windows path
$ADB pull /sdcard/screen.png /mnt/c/Users/pkoaw/claude-sync/screen-test.png
# 3. Resize with PowerShell (see above)
# 4. Read the resized file
```

## Device-Specific Notes
- **Z Fold (1968x2184)**: ALWAYS resize. Raw = ~150KB+ = API fail
- **Standard phones**: Usually safe, but resize anyway for consistency
- **Target size**: 800x width or ~50KB max

## Recovery
If Claude freezes on image read:
1. Cancel/restart session
2. Delete the problematic image: `rm /tmp/*.png`
3. Follow this protocol

---
*Created: 2026-01-19 after Z Fold screenshot incident*
