#!/bin/bash
# T→T² Watcher - Monitors T's messages to T² and triggers T²
# Run this in T²'s tmux context

WEBDAV_URL="http://100.113.114.74:8085"
WEBDAV_USER="hive"
WEBDAV_PASS="hivesync2026"

WATCH_FILE="t-to-t2.md"
LOG_FILE="$HOME/.hive/t-to-t2-watcher.log"

TMUX_SESSION="hive"
TMUX_WINDOW="t2-claude"

POLL_INTERVAL=5
COOLDOWN=30

mkdir -p "$HOME/.hive"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

get_remote_hash() {
    curl -s -u "$WEBDAV_USER:$WEBDAV_PASS" "$WEBDAV_URL/$WATCH_FILE" | md5sum | cut -d' ' -f1
}

log "=== T→T² Watcher Started ==="
log "Monitoring: $WEBDAV_URL/$WATCH_FILE"
log "Target: $TMUX_SESSION:$TMUX_WINDOW"

LAST_HASH=$(get_remote_hash)
LAST_PROCESS=0

while true; do
    sleep "$POLL_INTERVAL"
    NOW=$(date +%s)
    CURRENT_HASH=$(get_remote_hash)

    if [ "$CURRENT_HASH" != "$LAST_HASH" ] && [ -n "$LAST_HASH" ]; then
        SINCE_LAST=$((NOW - LAST_PROCESS))
        log "Change detected"
        LAST_HASH="$CURRENT_HASH"

        if [ "$SINCE_LAST" -lt "$COOLDOWN" ]; then
            log "Skipping - cooldown"
            continue
        fi

        log ">>> Message from T <<<" 
        LAST_PROCESS=$NOW

        if ! tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
            log "ERROR: tmux session not found"
            continue
        fi

        tmux send-keys -t "$TMUX_SESSION:$TMUX_WINDOW" "check t-to-t2.md" Enter
        log "Sent prompt to T²"
    fi
done
