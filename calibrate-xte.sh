#!/bin/bash
# Calibration script for xte auto-sync trigger
# Run this to find the coordinates of the Claude input field

echo "=== xte Coordinate Calibration ==="
echo ""
echo "Instructions:"
echo "1. Open VS Code with Claude Code visible"
echo "2. Position your mouse cursor OVER the Claude text input field"
echo "3. Press Enter here when ready..."
echo ""
read -p "Press Enter when mouse is positioned..."

# Get current mouse position using xev (capture one motion event)
echo ""
echo "Getting mouse position..."

# Use xdotool if available, otherwise parse from xwininfo
if command -v xdotool &> /dev/null; then
    POS=$(xdotool getmouselocation)
    X=$(echo $POS | grep -oP 'x:\K\d+')
    Y=$(echo $POS | grep -oP 'y:\K\d+')
else
    # Alternative: use xwininfo on root window and parse pointer location
    # This is trickier, so let's try a different approach
    echo "xdotool not available, using alternative method..."
    echo ""
    echo "Run this command in another terminal while hovering over the Claude input:"
    echo "  xev -root | grep -A2 MotionNotify | head -5"
    echo ""
    echo "Look for 'root:(X,Y)' in the output"
    exit 0
fi

echo ""
echo "==================================="
echo "Mouse position detected:"
echo "  X = $X"
echo "  Y = $Y"
echo "==================================="
echo ""
echo "To use these coordinates, edit auto-sync-trigger-xte.sh and set:"
echo "  CLICK_X=$X"
echo "  CLICK_Y=$Y"
echo ""
echo "Or run the trigger with:"
echo "  CLICK_X=$X CLICK_Y=$Y ~/claude-sync/auto-sync-trigger-xte.sh"
