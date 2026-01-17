#!/bin/bash
# Calibration script for xdotool click coordinates
# Run this to find where the Claude input area is

echo "=== xdotool Coordinate Calibration ==="
echo ""
echo "1. Focus VS Code and position your mouse over the Claude input area"
echo "2. Press Enter when ready..."
read

# Get current mouse position
MOUSE_POS=$(xdotool getmouselocation)
echo ""
echo "Mouse position: $MOUSE_POS"
echo ""

# Extract coordinates
X=$(echo "$MOUSE_POS" | grep -oP 'x:\K\d+')
Y=$(echo "$MOUSE_POS" | grep -oP 'y:\K\d+')

echo "Coordinates to use:"
echo "  CLICK_X=$X"
echo "  CLICK_Y=$Y"
echo ""
echo "Edit auto-sync-trigger-phone.sh and set these values."
echo ""

# Test click
echo "Test click in 3 seconds... (move mouse away from input to see it work)"
sleep 3
xdotool mousemove "$X" "$Y"
xdotool click 1
echo "Click sent!"
