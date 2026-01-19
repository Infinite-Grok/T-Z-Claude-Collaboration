#!/bin/bash
# T's Ping-Pong Watcher (WSL + tmux)
# Watches to-t.md, sends /sync to tmux session

WATCH="/mnt/c/Users/pkoaw/claude-sync/to-t.md"
LOG="/mnt/c/Users/pkoaw/claude-sync/watcher-wsl.log"
TMUX_SESSION="hive"
TMUX_WINDOW="claude"
POLL_INTERVAL=2

log() {
    echo "[$(date +%H:%M:%S)] $1" | tee -a "$LOG"
}

send_sync() {
    if tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
        tmux send-keys -t "$TMUX_SESSION:$TMUX_WINDOW" "/sync" Enter
        log "Sent /sync"
    else
        log "No tmux session '$TMUX_SESSION'"
    fi
}

log "=== WSL WATCHER STARTED ==="
log "Watching: $WATCH"
log "Poll: ${POLL_INTERVAL}s"

LAST_MOD=$(stat -c %Y "$WATCH" 2>/dev/null || echo 0)

while true; do
    sleep $POLL_INTERVAL
    CURR_MOD=$(stat -c %Y "$WATCH" 2>/dev/null || echo 0)
    if [ "$CURR_MOD" != "$LAST_MOD" ]; then
        log "Change detected"
        LAST_MOD=$CURR_MOD
        sleep 0.5
        send_sync
    fi
done
