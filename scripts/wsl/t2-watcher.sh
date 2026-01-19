#!/bin/bash
# T² Watcher - Monitors T²'s WebDAV output and triggers T
# Part of Project Genesis infrastructure

WEBDAV_URL="http://100.113.114.74:8085"
WEBDAV_USER="hive"
WEBDAV_PASS="hivesync2026"

WATCH_FILE="t2-to-t.md"
LOG_FILE="$HOME/.hive/t2-watcher.log"

# tmux settings - same session as main watcher
TMUX_SESSION="hive"
TMUX_WINDOW="t-claude"

# Timing
POLL_INTERVAL=5
COOLDOWN=30

mkdir -p "$HOME/.hive"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

fetch_file() {
    curl -s -u "$WEBDAV_USER:$WEBDAV_PASS" "$WEBDAV_URL/$1"
}

get_remote_hash() {
    fetch_file "$WATCH_FILE" | md5sum | cut -d' ' -f1
}

log "============================================"
log "     T² WATCHER - Project Genesis"
log "============================================"
log "Polling: $WEBDAV_URL/$WATCH_FILE"
log "Target: $TMUX_SESSION:$TMUX_WINDOW"
log ""
log "Waiting for T²..."
log ""

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

        log ">>> Message from T² <<<"
        LAST_PROCESS=$NOW

        if ! tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
            log "ERROR: tmux session not found"
            continue
        fi

        tmux send-keys -t "$TMUX_SESSION:$TMUX_WINDOW" -l "check t2-to-t.md"
        sleep 0.3
        tmux send-keys -t "$TMUX_SESSION:$TMUX_WINDOW" C-m
        log "Sent prompt"
        log ""
        log "Waiting for T²..."
    fi
done
