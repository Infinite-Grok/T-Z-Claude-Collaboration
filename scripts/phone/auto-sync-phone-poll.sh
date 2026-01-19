#!/bin/bash
# Phone Claude Auto-Sync Daemon (Polling + xte)
# Watches from-windows.md for changes and triggers /sync via xte
# No need to invoke claude binary - just types into VS Code!

SYNC_DIR="/data/data/com.termux/files/home/claude-sync"
WATCH_FILE="from-windows.md"
MY_FILE="from-phone.md"
FULL_PATH="$SYNC_DIR/$WATCH_FILE"
MY_PATH="$SYNC_DIR/$MY_FILE"
POLL_INTERVAL=5  # Check every 5 seconds
TRIGGER_SCRIPT="$SYNC_DIR/auto-sync-trigger-xte.sh"
COOLDOWN=10  # Don't trigger if I wrote to from-phone.md within this many seconds

echo "=== Phone Claude Auto-Sync Daemon (xte) ==="
echo "Watching: $FULL_PATH"
echo "Poll interval: ${POLL_INTERVAL}s"
echo "Trigger: $TRIGGER_SCRIPT"
echo "Press Ctrl+C to stop"
echo ""

# Check if xte is available
if ! command -v xte &> /dev/null; then
    echo "ERROR: xte not found. Install xautomation."
    exit 1
fi

# Check if trigger script exists
if [ ! -x "$TRIGGER_SCRIPT" ]; then
    echo "ERROR: Trigger script not found or not executable: $TRIGGER_SCRIPT"
    exit 1
fi

# Get initial modification time
if [ -f "$FULL_PATH" ]; then
    LAST_MOD=$(stat -c %Y "$FULL_PATH" 2>/dev/null || stat -f %m "$FULL_PATH" 2>/dev/null)
else
    echo "ERROR: Watch file not found: $FULL_PATH"
    exit 1
fi

echo "Daemon started. Initial mod time: $LAST_MOD"
echo "Waiting for changes..."
echo ""

while true; do
    sleep $POLL_INTERVAL

    # Get current modification time
    CURRENT_MOD=$(stat -c %Y "$FULL_PATH" 2>/dev/null || stat -f %m "$FULL_PATH" 2>/dev/null)

    if [ "$CURRENT_MOD" != "$LAST_MOD" ]; then
        TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
        LAST_MOD="$CURRENT_MOD"

        # Check if I recently wrote to from-phone.md (meaning I'm in an active session)
        NOW=$(date +%s)
        MY_MOD=$(stat -c %Y "$MY_PATH" 2>/dev/null || echo "0")
        SECONDS_SINCE_MY_WRITE=$((NOW - MY_MOD))

        if [ "$SECONDS_SINCE_MY_WRITE" -lt "$COOLDOWN" ]; then
            echo "[$TIMESTAMP] Change detected, but I wrote to from-phone.md ${SECONDS_SINCE_MY_WRITE}s ago. Skipping (cooldown: ${COOLDOWN}s)"
            continue
        fi

        # Also check if from-windows.md was JUST modified (within 3s means I probably edited it, not Syncthing)
        WINDOWS_MOD=$(stat -c %Y "$FULL_PATH" 2>/dev/null || echo "0")
        SECONDS_SINCE_WINDOWS_CHANGE=$((NOW - WINDOWS_MOD))
        if [ "$SECONDS_SINCE_WINDOWS_CHANGE" -lt 3 ]; then
            # Could be me marking messages processed - wait and re-check
            echo "[$TIMESTAMP] Change too recent (${SECONDS_SINCE_WINDOWS_CHANGE}s ago). Waiting to confirm it's not my own edit..."
            sleep 3
            # Re-check if file changed again (Syncthing would keep updating)
            NEW_MOD=$(stat -c %Y "$FULL_PATH" 2>/dev/null || echo "0")
            if [ "$NEW_MOD" = "$WINDOWS_MOD" ]; then
                echo "[$TIMESTAMP] No further changes - was probably my own edit. Skipping."
                continue
            fi
            echo "[$TIMESTAMP] File changed again - likely Syncthing. Proceeding."
        fi

        # Small delay to let Syncthing finish writing
        sleep 0.5

        echo "[$TIMESTAMP] Change detected in from-windows.md"
        echo "[$TIMESTAMP] Triggering /sync via xte..."

        # Run the xte trigger script
        if "$TRIGGER_SCRIPT" 2>&1; then
            echo "[$TIMESTAMP] Trigger sent"
        else
            echo "[$TIMESTAMP] Error running trigger"
        fi

        echo ""
        echo "Watching for next change..."
    fi
done
