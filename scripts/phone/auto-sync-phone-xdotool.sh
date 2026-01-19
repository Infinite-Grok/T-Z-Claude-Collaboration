#!/bin/bash
# Auto-Sync Watcher for Phone (Linux/XFCE) - Updated for Directory Structure
# Watches from-windows.md AND messages/from-t/ for changes
# Polling-based file watcher + xdotool/xte trigger

SYNC_DIR="$HOME/claude-sync"
WATCH_FILE="$SYNC_DIR/from-windows.md"
WATCH_DIR="$SYNC_DIR/messages/from-t"
FROM_PHONE="$SYNC_DIR/from-phone.md"
TRIGGER_SCRIPT="$SYNC_DIR/auto-sync-trigger-xte.sh"
LOG_FILE="$SYNC_DIR/auto-sync.log"
POLL_INTERVAL=5  # seconds
COOLDOWN=30      # seconds after own edit to skip

# Get modification time
get_mtime() {
    stat -c %Y "$1" 2>/dev/null || echo "0"
}

# Get newest file mtime in directory
get_dir_newest() {
    find "$1" -name "*.md" -type f -printf '%T@\n' 2>/dev/null | sort -n | tail -1 | cut -d. -f1
}

# Check if we recently wrote to from-phone.md (loop prevention)
check_own_edit() {
    local my_mtime=$(get_mtime "$FROM_PHONE")
    local now=$(date +%s)
    local diff=$((now - my_mtime))
    if [ "$diff" -lt "$COOLDOWN" ]; then
        return 0  # true - is own edit
    fi
    return 1  # false - not own edit
}

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

LAST_FILE_MTIME=$(get_mtime "$WATCH_FILE")
LAST_DIR_MTIME=$(get_dir_newest "$WATCH_DIR")

log "=== Phone Claude Auto-Sync Daemon ==="
log "Watching: $WATCH_FILE"
log "Watching: $WATCH_DIR/*.md"
log "Cooldown: ${COOLDOWN}s after own edits"
log "Poll interval: ${POLL_INTERVAL}s"
log ""
log "Daemon started. Waiting for changes..."

while true; do
    sleep "$POLL_INTERVAL"

    CURRENT_FILE_MTIME=$(get_mtime "$WATCH_FILE")
    CURRENT_DIR_MTIME=$(get_dir_newest "$WATCH_DIR")

    CHANGED=false

    if [ "$CURRENT_FILE_MTIME" != "$LAST_FILE_MTIME" ]; then
        CHANGED=true
        LAST_FILE_MTIME="$CURRENT_FILE_MTIME"
        CHANGE_SOURCE="from-windows.md"
    fi

    if [ "$CURRENT_DIR_MTIME" != "$LAST_DIR_MTIME" ] && [ -n "$CURRENT_DIR_MTIME" ]; then
        CHANGED=true
        LAST_DIR_MTIME="$CURRENT_DIR_MTIME"
        CHANGE_SOURCE="messages/from-t/"
    fi

    if [ "$CHANGED" = true ]; then
        # Loop prevention
        if check_own_edit; then
            my_mtime=$(get_mtime "$FROM_PHONE")
            now=$(date +%s)
            diff=$((now - my_mtime))
            log "Change detected, but I wrote to from-phone.md ${diff}s ago. Skipping (cooldown: ${COOLDOWN}s)"
            continue
        fi

        log "Change detected in $CHANGE_SOURCE"
        log "Triggering /sync..."

        # Check if X display is available
        if [ -z "$DISPLAY" ]; then
            log "ERROR: No DISPLAY set"
            continue
        fi

        # Run the trigger script
        if [ -x "$TRIGGER_SCRIPT" ]; then
            "$TRIGGER_SCRIPT"
        else
            log "ERROR: Trigger script not executable: $TRIGGER_SCRIPT"
        fi

        echo ""
        log "Watching for next change..."
    fi
done
