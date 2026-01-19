#!/bin/bash
# Syncthing Manager for The Hive (Z Node)
# Manages Syncthing CLI in Termux

SYNC_DIR="$HOME/claude-sync"
LOG_FILE="$SYNC_DIR/logs/syncthing-manager.log"
PID_FILE="$SYNC_DIR/logs/syncthing.pid"

# Syncthing settings
GUI_ADDRESS="127.0.0.1:8384"
API_URL="http://$GUI_ADDRESS"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

is_running() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" >/dev/null 2>&1; then
            return 0
        fi
    fi
    # Also check by process name
    pgrep -x syncthing >/dev/null 2>&1
}

start_syncthing() {
    if is_running; then
        log "Syncthing already running"
        return 0
    fi

    log "Starting Syncthing..."
    syncthing serve --no-browser --gui-address="$GUI_ADDRESS" >> "$LOG_FILE" 2>&1 &
    echo $! > "$PID_FILE"
    sleep 3

    if is_running; then
        log "Syncthing started successfully (PID: $(cat $PID_FILE))"
        return 0
    else
        log "ERROR: Failed to start Syncthing"
        return 1
    fi
}

stop_syncthing() {
    log "Stopping Syncthing..."
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        kill "$PID" 2>/dev/null
        rm -f "$PID_FILE"
    fi
    pkill -x syncthing 2>/dev/null
    sleep 2
    log "Syncthing stopped"
}

restart_syncthing() {
    stop_syncthing
    sleep 1
    start_syncthing
}

status_syncthing() {
    if is_running; then
        PID=$(pgrep -x syncthing)
        echo "Syncthing is RUNNING (PID: $PID)"

        # Try to get API status
        API_KEY=$(grep -oP '(?<=<apikey>)[^<]+' ~/.local/state/syncthing/config.xml 2>/dev/null)
        if [ -n "$API_KEY" ]; then
            STATUS=$(curl -s -H "X-API-Key: $API_KEY" "$API_URL/rest/system/status" 2>/dev/null)
            if [ -n "$STATUS" ]; then
                echo "API responding: OK"
                echo "$STATUS" | grep -o '"myID":"[^"]*"' | head -1
            fi
        fi
    else
        echo "Syncthing is NOT RUNNING"
    fi
}

check_and_restart() {
    # Called by watcher - restart if not running
    if ! is_running; then
        log "Syncthing not running - auto-restarting..."
        start_syncthing
    fi
}

case "${1:-status}" in
    start)
        start_syncthing
        ;;
    stop)
        stop_syncthing
        ;;
    restart)
        restart_syncthing
        ;;
    status)
        status_syncthing
        ;;
    check)
        check_and_restart
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|check}"
        exit 1
        ;;
esac
