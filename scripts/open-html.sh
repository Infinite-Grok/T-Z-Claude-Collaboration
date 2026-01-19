#!/bin/bash
# Open HTML file in browser
# Works on both WSL (Windows) and Termux (Android)

FILE="$1"

if [ -z "$FILE" ]; then
    echo "Usage: open-html.sh <file.html>"
    exit 1
fi

# Convert to absolute path if relative
if [[ ! "$FILE" = /* ]]; then
    FILE="$(pwd)/$FILE"
fi

# Detect environment and open appropriately
if [ -n "$WSL_DISTRO_NAME" ]; then
    # WSL - convert path and open in Windows browser
    WIN_PATH=$(wslpath -w "$FILE")
    cmd.exe /c start "" "$WIN_PATH" 2>/dev/null
    echo "Opened in Windows browser: $WIN_PATH"
elif [ -n "$TERMUX_VERSION" ]; then
    # Termux - use termux-open
    termux-open "$FILE" 2>/dev/null || am start -a android.intent.action.VIEW -d "file://$FILE" -t "text/html"
    echo "Opened in Android browser: $FILE"
else
    # Generic Linux
    xdg-open "$FILE" 2>/dev/null || open "$FILE" 2>/dev/null
    echo "Opened: $FILE"
fi
