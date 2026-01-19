#!/bin/bash
SYNC_DIR="/mnt/c/Users/pkoaw/claude-sync"
WATCH_FILE="$SYNC_DIR/to-t.md"
MY_FILE="$SYNC_DIR/to-z.md"
LOG_FILE="$SYNC_DIR/logs/hive-watcher-t.log"

TMUX_SESSION="hive"
TMUX_WINDOW="t-claude"

COOLDOWN=30
DEBOUNCE=3

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

claude_is_running() {
    PANE_PID=$(tmux display-message -t "$TMUX_SESSION:$TMUX_WINDOW" -p '#{pane_pid}' 2>/dev/null)
    [ -n "$PANE_PID" ] && pgrep -P "$PANE_PID" -f "claude" >/dev/null 2>&1
}

spawn_claude() {
    log "Spawning Claude..."
    tmux send-keys -t "$TMUX_SESSION:$TMUX_WINDOW" -l "claude --dangerously-skip-permissions"
    sleep 0.3
    tmux send-keys -t "$TMUX_SESSION:$TMUX_WINDOW" C-m
    sleep 3
}

log "============================================"
log "     THE HIVE - T Node Watcher (WSL)"
log "============================================"
log "Watching: $WATCH_FILE"
log "Target: $TMUX_SESSION:$TMUX_WINDOW"
log ""

LAST_PROCESS=0
LAST_MOD=$(stat -c %Y "$WATCH_FILE" 2>/dev/null || echo "0")

# Use inotifywait if available, else poll
if command -v inotifywait &>/dev/null; then
    log "Using inotifywait"
    inotifywait -m -e modify,close_write "$WATCH_FILE" 2>/dev/null | while read -r path event file; do
        NOW=$(date +%s)
        SINCE_LAST=$((NOW - LAST_PROCESS))

        [ "$SINCE_LAST" -lt "$DEBOUNCE" ] && continue

        log "Change detected: $event"

        [ "$SINCE_LAST" -lt "$COOLDOWN" ] && { log "Cooldown..."; continue; }

        MY_MOD=$(stat -c %Y "$MY_FILE" 2>/dev/null || echo "0")
        [ $((NOW - MY_MOD)) -lt 10 ] && { log "Own activity, skip"; continue; }

        sleep 1
        log ">>> Message from Z detected <<<"
        LAST_PROCESS=$NOW

        tmux has-session -t "$TMUX_SESSION" 2>/dev/null || { log "No tmux session"; continue; }

        claude_is_running || spawn_claude

        tmux send-keys -t "$TMUX_SESSION:$TMUX_WINDOW" -l "check to-t.md"
        sleep 0.3
        tmux send-keys -t "$TMUX_SESSION:$TMUX_WINDOW" C-m
        log "Sent sync prompt"
    done
else
    log "Using polling (install inotify-tools for better performance)"
    while true; do
        sleep 2
        CURR_MOD=$(stat -c %Y "$WATCH_FILE" 2>/dev/null || echo "0")
        if [ "$CURR_MOD" != "$LAST_MOD" ]; then
            NOW=$(date +%s)
            SINCE_LAST=$((NOW - LAST_PROCESS))
            LAST_MOD=$CURR_MOD

            [ "$SINCE_LAST" -lt "$COOLDOWN" ] && { log "Cooldown..."; continue; }

            MY_MOD=$(stat -c %Y "$MY_FILE" 2>/dev/null || echo "0")
            [ $((NOW - MY_MOD)) -lt 10 ] && { log "Own activity, skip"; continue; }

            log ">>> Message from Z detected <<<"
            LAST_PROCESS=$NOW

            tmux has-session -t "$TMUX_SESSION" 2>/dev/null || { log "No tmux session"; continue; }

            claude_is_running || spawn_claude

            tmux send-keys -t "$TMUX_SESSION:$TMUX_WINDOW" -l "check to-t.md"
            sleep 0.3
            tmux send-keys -t "$TMUX_SESSION:$TMUX_WINDOW" C-m
            log "Sent sync prompt"
        fi
    done
fi
