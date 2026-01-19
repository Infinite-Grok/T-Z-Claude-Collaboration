#!/bin/bash
# Z's Ping-Pong Watcher (Phone/Termux)
# Watches to-z.md for changes from T, triggers sync in tmux

WATCH="$HOME/claude-sync/to-z.md"
LOG="$HOME/claude-sync/watcher-z.log"
TMUX_SESSION="hive"
TMUX_WINDOW="claude"

log() {
    echo "[$(date +%H:%M:%S)] $1" | tee -a "$LOG"
}

send_sync() {
    if tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
        tmux send-keys -t "$TMUX_SESSION:$TMUX_WINDOW" "/sync" Enter
        log "Sent /sync to tmux"
    else
        log "No tmux session '$TMUX_SESSION' found"
    fi
}

log "=== Z WATCHER STARTED ==="
log "Watching: $WATCH"

# Use inotifywait if available, else poll
if command -v inotifywait &>/dev/null; then
    log "Using inotifywait"
    while true; do
        inotifywait -qq -e modify "$WATCH" 2>/dev/null
        sleep 0.5  # Let sync finish
        send_sync
        sleep 2  # Debounce
    done
else
    log "Using polling (install inotify-tools for better performance)"
    LAST_MOD=$(stat -c %Y "$WATCH" 2>/dev/null || echo 0)
    while true; do
        sleep 2
        CURR_MOD=$(stat -c %Y "$WATCH" 2>/dev/null || echo 0)
        if [ "$CURR_MOD" != "$LAST_MOD" ]; then
            LAST_MOD=$CURR_MOD
            log "Change detected"
            send_sync
        fi
    done
fi
