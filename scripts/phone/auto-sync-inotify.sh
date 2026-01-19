#!/bin/bash
# Phone Claude Auto-Sync Daemon (inotify + xte)
# Runs in Termux NATIVE, watches for changes, triggers via proot xte
# Much more efficient than polling - instant detection, less battery

SYNC_DIR="/data/data/com.termux/files/home/claude-sync"
WATCH_FILE="from-windows.md"
MY_FILE="from-phone.md"
FULL_PATH="$SYNC_DIR/$WATCH_FILE"
MY_PATH="$SYNC_DIR/$MY_FILE"
TRIGGER_SCRIPT="$SYNC_DIR/auto-sync-trigger-xte.sh"
COOLDOWN=10
LOG_FILE="$SYNC_DIR/auto-sync-inotify.log"
INOTIFYWAIT="/data/data/com.termux/files/usr/bin/inotifywait"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== Phone Claude Auto-Sync Daemon (inotify) ==="
log "Watching: $FULL_PATH"
log "Trigger: $TRIGGER_SCRIPT"
log "Press Ctrl+C to stop"

# Verify inotifywait exists
if [ ! -x "$INOTIFYWAIT" ]; then
    log "ERROR: inotifywait not found at $INOTIFYWAIT"
    exit 1
fi

# Verify watch file exists
if [ ! -f "$FULL_PATH" ]; then
    log "ERROR: Watch file not found: $FULL_PATH"
    exit 1
fi

log "Daemon started. Waiting for changes..."

# Use inotifywait in monitor mode
"$INOTIFYWAIT" -m -e modify,close_write "$FULL_PATH" 2>/dev/null | while read -r directory event filename; do
    log "Event detected: $event"

    # Check cooldown - did I recently write to from-phone.md?
    NOW=$(date +%s)
    MY_MOD=$(stat -c %Y "$MY_PATH" 2>/dev/null || echo "0")
    SECONDS_SINCE_MY_WRITE=$((NOW - MY_MOD))

    if [ "$SECONDS_SINCE_MY_WRITE" -lt "$COOLDOWN" ]; then
        log "Skipping - wrote to from-phone.md ${SECONDS_SINCE_MY_WRITE}s ago (cooldown: ${COOLDOWN}s)"
        continue
    fi

    # Small delay to let Syncthing finish
    sleep 0.5

    log "Triggering /sync via xte..."

    # Run trigger through proot if needed, or directly if xte is in Termux
    if command -v xte &>/dev/null; then
        "$TRIGGER_SCRIPT" 2>&1 && log "Trigger sent" || log "Trigger failed"
    else
        # xte is in proot - need to call through proot-distro
        proot-distro login debian --shared-tmp -- bash "$TRIGGER_SCRIPT" 2>&1 && log "Trigger sent (via proot)" || log "Trigger failed"
    fi

    log "Waiting for next change..."
done
