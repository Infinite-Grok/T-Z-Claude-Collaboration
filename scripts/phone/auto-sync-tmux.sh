#!/bin/bash
# The Hive - Auto-Sync Watcher (inotify + tmux)
# Watches from-windows.md and sends /sync to z-claude window
#
# Requirements:
#   - tmux session "hive" with window "z-claude" running Claude Code
#   - inotify-tools installed in Termux
#
# Run this in the "watcher" window of the hive session

SYNC_DIR="$HOME/claude-sync"
WATCH_FILE="from-windows.md"
MY_FILE="from-phone.md"
FULL_PATH="$SYNC_DIR/$WATCH_FILE"
MY_PATH="$SYNC_DIR/$MY_FILE"
LOG_FILE="$SYNC_DIR/auto-sync-tmux.log"

# tmux target
TMUX="/data/data/com.termux/files/usr/bin/tmux"
SESSION="hive"
TARGET_WINDOW="z-claude"

# Timing
COOLDOWN=10
DEBOUNCE=2

INOTIFYWAIT="/data/data/com.termux/files/usr/bin/inotifywait"

log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$msg"
    echo "$msg" >> "$LOG_FILE"
}

# Verify dependencies
if [ ! -x "$INOTIFYWAIT" ]; then
    log "ERROR: inotifywait not found. Install: pkg install inotify-tools"
    exit 1
fi

if ! "$TMUX" has-session -t "$SESSION" 2>/dev/null; then
    log "ERROR: tmux session '$SESSION' not found. Run hive-tmux-setup.sh first"
    exit 1
fi

if [ ! -f "$FULL_PATH" ]; then
    log "ERROR: Watch file not found: $FULL_PATH"
    exit 1
fi

log "=== Hive Auto-Sync Watcher (tmux) ==="
log "Watching: $FULL_PATH"
log "Target: $SESSION:$TARGET_WINDOW"
log "Cooldown: ${COOLDOWN}s | Debounce: ${DEBOUNCE}s"
log "Press Ctrl+C to stop"
log ""
log "Waiting for changes..."

LAST_TRIGGER=0

# Monitor for changes
"$INOTIFYWAIT" -m -e modify,close_write "$FULL_PATH" 2>/dev/null | while read -r path event file; do
    NOW=$(date +%s)

    # Debounce - ignore rapid successive events
    SINCE_LAST=$((NOW - LAST_TRIGGER))
    if [ "$SINCE_LAST" -lt "$DEBOUNCE" ]; then
        continue
    fi

    log "Event: $event"

    # Cooldown - did Z recently write to from-phone.md?
    MY_MOD=$(stat -c %Y "$MY_PATH" 2>/dev/null || echo "0")
    SINCE_MY_WRITE=$((NOW - MY_MOD))

    if [ "$SINCE_MY_WRITE" -lt "$COOLDOWN" ]; then
        log "Skipping - Z wrote ${SINCE_MY_WRITE}s ago (cooldown: ${COOLDOWN}s)"
        continue
    fi

    # Let Syncthing finish writing
    sleep 0.5

    # Send /sync to z-claude window
    log "Sending /sync to $SESSION:$TARGET_WINDOW"

    if "$TMUX" send-keys -t "$SESSION:$TARGET_WINDOW" "/sync" Enter; then
        log "Trigger sent successfully"
        LAST_TRIGGER=$NOW
    else
        log "ERROR: Failed to send keys to tmux"
    fi

    log "Waiting for changes..."
done
