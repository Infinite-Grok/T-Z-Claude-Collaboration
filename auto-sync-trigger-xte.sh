#!/bin/bash
# Auto-Sync Trigger Script for Phone
# Uses xte (from xautomation) to type /sync into the active window
# NO CLICK NEEDED - just types into whatever is focused

LOG_FILE="$HOME/claude-sync/auto-sync-trigger.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

echo "$TIMESTAMP - Starting sync trigger (xte)" >> "$LOG_FILE"

# Clear any existing text in the input field
xte 'keydown Control_L' 'key a' 'keyup Control_L'
sleep 0.3
xte 'key BackSpace'
sleep 0.2

# Type /sync
xte 'str /sync'
sleep 0.1

# Press Enter
xte 'key Return'

echo "$TIMESTAMP - Sync command sent" >> "$LOG_FILE"
