#!/bin/bash
# The Hive - File Watcher (Poll-based) with Syncthing Health Checks
# Watches for changes from T using polling (more reliable on Android)

SYNC_DIR="$HOME/claude-sync"
WATCH_FILE="$SYNC_DIR/to-z.md"
MY_FILE="$SYNC_DIR/to-t.md"
LOG_FILE="$SYNC_DIR/logs/hive-watcher.log"
HEARTBEAT_FILE="$SYNC_DIR/.heartbeat-z"
SYNCTHING_MANAGER="$SYNC_DIR/scripts/phone/syncthing-manager.sh"

# tmux settings
TMUX_BIN="/data/data/com.termux/files/usr/bin/tmux"
TMUX_SESSION="hive"
TMUX_WINDOW="z-claude"

# Timing
POLL_INTERVAL=3      # Check every 3 seconds
COOLDOWN=30          # Don't re-trigger if we processed recently
HEALTH_CHECK_INTERVAL=60  # Check Syncthing health every 60 seconds
STALE_THRESHOLD=600  # Alert if no inbox changes for 10 minutes

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Check if Claude is running in the tmux pane
claude_is_running() {
    PANE_PID=$("$TMUX_BIN" display-message -t "$TMUX_SESSION:$TMUX_WINDOW" -p '#{pane_pid}' 2>/dev/null)
    if [ -z "$PANE_PID" ]; then
        return 1
    fi
    pgrep -P "$PANE_PID" -f "claude" >/dev/null 2>&1
}

# Spawn Claude in the tmux window
spawn_claude() {
    log "Spawning Claude in $TMUX_SESSION:$TMUX_WINDOW..."
    "$TMUX_BIN" send-keys -t "$TMUX_SESSION:$TMUX_WINDOW" "claude --dangerously-skip-permissions"
    sleep 0.5
    "$TMUX_BIN" send-keys -t "$TMUX_SESSION:$TMUX_WINDOW" Enter
    sleep 3
}

# Check Syncthing health
check_syncthing() {
    if [ -x "$SYNCTHING_MANAGER" ]; then
        if ! pgrep -x syncthing >/dev/null 2>&1; then
            log "WARNING: Syncthing not running - attempting restart..."
            "$SYNCTHING_MANAGER" start
        fi
    fi
}

# Write heartbeat for T to verify sync
write_heartbeat() {
    echo "$(date +%s) Z $(date '+%Y-%m-%d %H:%M:%S')" > "$HEARTBEAT_FILE"
}

# Check if inbox is stale (might indicate sync issues)
check_stale_inbox() {
    local inbox_age=$(( $(date +%s) - $(stat -c %Y "$WATCH_FILE" 2>/dev/null || echo "0") ))
    if [ "$inbox_age" -gt "$STALE_THRESHOLD" ]; then
        log "WARNING: Inbox stale for ${inbox_age}s - sync may be down!"
        return 1
    fi
    return 0
}

if [ ! -f "$WATCH_FILE" ]; then
    log "ERROR: Watch file not found: $WATCH_FILE"
    exit 1
fi

log "============================================"
log "     THE HIVE - Z Node Watcher (Poll)"
log "        + Syncthing Health Checks"
log "============================================"
log "Watching: $WATCH_FILE"
log "Target: $TMUX_SESSION:$TMUX_WINDOW"
log "Poll interval: ${POLL_INTERVAL}s | Cooldown: ${COOLDOWN}s"
log "Health check: every ${HEALTH_CHECK_INTERVAL}s"
log ""
log "Waiting for T to send messages..."
log ""

# Get initial modification time
LAST_MTIME=$(stat -c %Y "$WATCH_FILE" 2>/dev/null || echo "0")
LAST_PROCESS=0
LAST_HEALTH_CHECK=0
LOOP_COUNT=0

# Poll loop
while true; do
    sleep "$POLL_INTERVAL"
    LOOP_COUNT=$((LOOP_COUNT + 1))
    NOW=$(date +%s)

    # Periodic health checks
    if [ $((NOW - LAST_HEALTH_CHECK)) -ge "$HEALTH_CHECK_INTERVAL" ]; then
        check_syncthing
        write_heartbeat
        check_stale_inbox
        LAST_HEALTH_CHECK=$NOW
    fi

    CURRENT_MTIME=$(stat -c %Y "$WATCH_FILE" 2>/dev/null || echo "0")

    if [ "$CURRENT_MTIME" != "$LAST_MTIME" ]; then
        SINCE_LAST=$((NOW - LAST_PROCESS))

        log "Change detected (mtime: $LAST_MTIME -> $CURRENT_MTIME)"
        LAST_MTIME="$CURRENT_MTIME"

        # Cooldown check
        if [ "$SINCE_LAST" -lt "$COOLDOWN" ]; then
            log "Skipping - processed ${SINCE_LAST}s ago (cooldown: ${COOLDOWN}s)"
            continue
        fi

        # Check if Z recently wrote
        MY_MOD=$(stat -c %Y "$MY_FILE" 2>/dev/null || echo "0")
        SINCE_MY_WRITE=$((NOW - MY_MOD))
        if [ "$SINCE_MY_WRITE" -lt 10 ]; then
            log "Skipping - Z wrote ${SINCE_MY_WRITE}s ago (likely our own activity)"
            continue
        fi

        log ">>> Message from T detected <<<"
        LAST_PROCESS=$NOW

        # Ensure tmux session exists
        if ! "$TMUX_BIN" has-session -t "$TMUX_SESSION" 2>/dev/null; then
            log "ERROR: tmux session '$TMUX_SESSION' not found"
            continue
        fi

        # Spawn Claude if not running
        if ! claude_is_running; then
            spawn_claude
        fi

        # Send the sync prompt
        "$TMUX_BIN" send-keys -t "$TMUX_SESSION:$TMUX_WINDOW" -l "Read to-z.md and process the latest message from T. Follow the CLAUDE.md protocol."
        sleep 0.3
        "$TMUX_BIN" send-keys -t "$TMUX_SESSION:$TMUX_WINDOW" C-m
        log "Sent sync prompt to $TMUX_SESSION:$TMUX_WINDOW"

        log ""
        log "Waiting for T..."
    fi
done
