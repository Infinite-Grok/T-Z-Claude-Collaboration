#!/bin/bash
# Phone Claude Auto-Sync Daemon - Updated for Directory Structure
# Watches from-windows.md AND messages/from-t/ for changes
# Uses inotifywait for efficient watching
#
# SETUP:
#   1. Install inotify-tools: pkg install inotify-tools (Termux) or apt install inotify-tools
#   2. Make executable: chmod +x ~/claude-sync/auto-sync-phone.sh
#   3. Run: ~/claude-sync/auto-sync-phone.sh
#
# For background: nohup ~/claude-sync/auto-sync-phone.sh > ~/claude-sync/auto-sync.log 2>&1 &

SYNC_DIR="$HOME/claude-sync"
WATCH_FILE="$SYNC_DIR/from-windows.md"
WATCH_DIR="$SYNC_DIR/messages/from-t"
FROM_PHONE="$SYNC_DIR/from-phone.md"
TRIGGER_SCRIPT="$SYNC_DIR/auto-sync-trigger-xte.sh"
LOG_FILE="$SYNC_DIR/auto-sync.log"
COOLDOWN=30

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Check if we recently wrote to from-phone.md (loop prevention)
check_own_edit() {
    local my_mtime=$(stat -c %Y "$FROM_PHONE" 2>/dev/null || echo "0")
    local now=$(date +%s)
    local diff=$((now - my_mtime))
    if [ "$diff" -lt "$COOLDOWN" ]; then
        return 0  # true - is own edit
    fi
    return 1  # false - not own edit
}

log "=== Phone Claude Auto-Sync Daemon ==="
log "Watching: $WATCH_FILE"
log "Watching: $WATCH_DIR/*.md"
log "Cooldown: ${COOLDOWN}s after own edits"
log "Press Ctrl+C to stop"
log ""

# Check dependencies
if ! command -v inotifywait &> /dev/null; then
    log "ERROR: inotifywait not found"
    log "Install with: pkg install inotify-tools (Termux)"
    exit 1
fi

log "Daemon started. Waiting for changes..."
log ""

# Watch both file and directory
inotifywait -m -e modify -e create "$WATCH_FILE" "$WATCH_DIR" 2>/dev/null |
while read -r path events filename; do
    # Small delay for Syncthing
    sleep 0.5

    # Loop prevention
    if check_own_edit; then
        my_mtime=$(stat -c %Y "$FROM_PHONE" 2>/dev/null || echo "0")
        now=$(date +%s)
        diff=$((now - my_mtime))
        log "Change detected, but I wrote to from-phone.md ${diff}s ago. Skipping (cooldown: ${COOLDOWN}s)"
        continue
    fi

    log "Change detected in $path$filename"
    log "Triggering /sync..."

    # Run trigger script if available
    if [ -x "$TRIGGER_SCRIPT" ]; then
        "$TRIGGER_SCRIPT"
    elif command -v claude &> /dev/null; then
        # Fallback to direct Claude call
        cd "$SYNC_DIR" || exit
        if claude --print "/sync" 2>&1; then
            log "Sync complete"
        else
            log "Error running Claude"
        fi
    else
        log "ERROR: No trigger method available"
    fi

    log ""
    log "Watching for next change..."
done
