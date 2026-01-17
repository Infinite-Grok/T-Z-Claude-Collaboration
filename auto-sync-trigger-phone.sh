#!/bin/bash
# Auto-Sync Trigger Script for Phone (Linux/XFCE)
# Equivalent to Windows auto-sync-trigger.ahk
# Uses xdotool to simulate clicking VS Code Claude input and typing /sync

LOG_FILE="$HOME/claude-sync/auto-sync-trigger.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

echo "$TIMESTAMP - Starting sync trigger" >> "$LOG_FILE"

# Find VS Code window
VSCODE_WINDOW=$(xdotool search --name "Visual Studio Code" | head -1)

if [ -z "$VSCODE_WINDOW" ]; then
    echo "$TIMESTAMP - ERROR: VS Code window not found" >> "$LOG_FILE"
    exit 1
fi

# Activate the VS Code window
xdotool windowactivate --sync "$VSCODE_WINDOW"
sleep 0.3

# Get window geometry to calculate click position
# We'll click in the Claude input area - you may need to calibrate these coordinates
# Default: click near bottom-center of the window (similar to Windows 600,990)
WINDOW_GEOMETRY=$(xdotool getwindowgeometry "$VSCODE_WINDOW")
WINDOW_WIDTH=$(echo "$WINDOW_GEOMETRY" | grep -oP 'Geometry: \K\d+' | head -1)
WINDOW_HEIGHT=$(echo "$WINDOW_GEOMETRY" | grep -oP 'x\K\d+')

# Calculate click position (center-x, near bottom for Claude input)
# These are relative to the window, adjust as needed
CLICK_X=$((WINDOW_WIDTH / 2))
CLICK_Y=$((WINDOW_HEIGHT - 100))

# Alternative: Use absolute coordinates if you've calibrated them
# Uncomment and set your calibrated values:
# CLICK_X=600
# CLICK_Y=990

echo "$TIMESTAMP - Clicking at $CLICK_X, $CLICK_Y" >> "$LOG_FILE"

# Click in the Claude input area
xdotool mousemove --window "$VSCODE_WINDOW" "$CLICK_X" "$CLICK_Y"
xdotool click 1
sleep 0.2

# Clear any existing text and type /sync
xdotool key ctrl+a
sleep 0.1
xdotool key Delete
sleep 0.1
xdotool type "/sync"
sleep 0.1
xdotool key Return

echo "$TIMESTAMP - Sync command sent (clicked at $CLICK_X,$CLICK_Y)" >> "$LOG_FILE"
