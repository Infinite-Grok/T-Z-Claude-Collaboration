#!/bin/bash
# T→T² Watcher - triggers T² when T writes to t-to-t2.md

WEBDAV_URL="http://100.113.114.74:8085"
WATCH_FILE="t-to-t2.md"
TMUX_SESSION="hive"
TMUX_WINDOW="sandbox-t"

mkdir -p ~/.hive
LOG=~/.hive/t-to-t2-watcher.log

echo "[$(date)] T→T² Watcher STARTED" >> $LOG

LAST=""
while true; do
    HASH=$(curl -s -u hive:hivesync2026 "$WEBDAV_URL/$WATCH_FILE" 2>/dev/null | md5sum | cut -d' ' -f1)
    if [ "$HASH" != "$LAST" ] && [ -n "$LAST" ]; then
        echo "[$(date)] Change detected - triggering T²" >> $LOG
        tmux send-keys -t "$TMUX_SESSION:$TMUX_WINDOW" "check t-to-t2.md" Enter 2>/dev/null
    fi
    LAST="$HASH"
    sleep 5
done
