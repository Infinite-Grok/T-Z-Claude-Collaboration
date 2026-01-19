#!/bin/bash
# The Hive - T Node Watcher (WebDAV Edition)
# Polls Z's WebDAV server for changes to to-t.md

WEBDAV_URL="http://100.113.114.74:8085"
WEBDAV_USER="hive"
WEBDAV_PASS="hivesync2026"

WATCH_FILE="to-t.md"
OUTBOX_FILE="to-z.md"
LOG_FILE="$HOME/.hive/watcher.log"

# tmux settings
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

claude_is_running() {
    PANE_PID=$(tmux display-message -t "$TMUX_SESSION:$TMUX_WINDOW" -p '#{pane_pid}' 2>/dev/null)
    [ -n "$PANE_PID" ] && pgrep -P "$PANE_PID" -f "claude" >/dev/null 2>&1
}

spawn_claude() {
    log "Spawning Claude in $TMUX_SESSION:$TMUX_WINDOW..."
    tmux send-keys -t "$TMUX_SESSION:$TMUX_WINDOW" "cd ~/claude-sync && claude --dangerously-skip-permissions" Enter
    sleep 5
}

log "============================================"
log "     THE HIVE - T Node Watcher (WebDAV)"
log "============================================"
log "Polling: $WEBDAV_URL/$WATCH_FILE"
log "Target: $TMUX_SESSION:$TMUX_WINDOW"
log ""
log "Waiting for Z..."
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

        log ">>> Message from Z <<<"
        LAST_PROCESS=$NOW

        if ! tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
            log "ERROR: tmux session not found"
            continue
        fi

        if ! claude_is_running; then
            spawn_claude
        fi

        tmux send-keys -t "$TMUX_SESSION:$TMUX_WINDOW" -l "check to-t.md"
        sleep 0.3
        tmux send-keys -t "$TMUX_SESSION:$TMUX_WINDOW" C-m
        log "Sent prompt"
        log ""
        log "Waiting for Z..."
    fi
done
