#!/bin/bash
# Sync Health Check for The Hive
# Detects if Syncthing is working by checking file modification times

SYNC_DIR="$HOME/claude-sync"
MY_INBOX="$SYNC_DIR/to-z.md"
MY_OUTBOX="$SYNC_DIR/to-t.md"
HEARTBEAT="$SYNC_DIR/.heartbeat-z"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================="
echo "   SYNC HEALTH CHECK - Z Node"
echo "========================================="
echo ""

# Check 1: When was inbox last modified?
if [ -f "$MY_INBOX" ]; then
    INBOX_AGE=$(( $(date +%s) - $(stat -c %Y "$MY_INBOX") ))
    INBOX_TIME=$(stat -c %y "$MY_INBOX" | cut -d'.' -f1)
    if [ "$INBOX_AGE" -lt 300 ]; then
        echo -e "${GREEN}[OK]${NC} Inbox (to-z.md) modified ${INBOX_AGE}s ago ($INBOX_TIME)"
    elif [ "$INBOX_AGE" -lt 3600 ]; then
        echo -e "${YELLOW}[WARN]${NC} Inbox (to-z.md) modified ${INBOX_AGE}s ago ($INBOX_TIME)"
    else
        echo -e "${RED}[STALE]${NC} Inbox (to-z.md) modified ${INBOX_AGE}s ago ($INBOX_TIME)"
    fi
else
    echo -e "${RED}[ERROR]${NC} Inbox file not found!"
fi

# Check 2: When was outbox last modified?
if [ -f "$MY_OUTBOX" ]; then
    OUTBOX_AGE=$(( $(date +%s) - $(stat -c %Y "$MY_OUTBOX") ))
    OUTBOX_TIME=$(stat -c %y "$MY_OUTBOX" | cut -d'.' -f1)
    echo -e "${GREEN}[INFO]${NC} Outbox (to-t.md) modified ${OUTBOX_AGE}s ago ($OUTBOX_TIME)"
else
    echo -e "${RED}[ERROR]${NC} Outbox file not found!"
fi

echo ""

# Check 3: Write heartbeat and check T's heartbeat
echo "$(date +%s) Z" > "$HEARTBEAT"
echo -e "${GREEN}[SENT]${NC} Wrote heartbeat to .heartbeat-z"

T_HEARTBEAT="$SYNC_DIR/.heartbeat-t"
if [ -f "$T_HEARTBEAT" ]; then
    T_BEAT=$(cat "$T_HEARTBEAT" | cut -d' ' -f1)
    T_AGE=$(( $(date +%s) - $T_BEAT ))
    if [ "$T_AGE" -lt 120 ]; then
        echo -e "${GREEN}[OK]${NC} T's heartbeat: ${T_AGE}s ago (sync working!)"
    elif [ "$T_AGE" -lt 600 ]; then
        echo -e "${YELLOW}[WARN]${NC} T's heartbeat: ${T_AGE}s ago (may be delayed)"
    else
        echo -e "${RED}[STALE]${NC} T's heartbeat: ${T_AGE}s ago (sync may be down)"
    fi
else
    echo -e "${YELLOW}[WAIT]${NC} No heartbeat from T yet (.heartbeat-t missing)"
fi

echo ""

# Check 4: Recent .sync-conflict files (indicates sync issues)
CONFLICTS=$(find "$SYNC_DIR" -name "*.sync-conflict-*" -mmin -60 2>/dev/null | wc -l)
if [ "$CONFLICTS" -gt 0 ]; then
    echo -e "${RED}[WARN]${NC} Found $CONFLICTS sync conflict files in last hour!"
    find "$SYNC_DIR" -name "*.sync-conflict-*" -mmin -60 2>/dev/null
else
    echo -e "${GREEN}[OK]${NC} No recent sync conflicts"
fi

echo ""
echo "========================================="
echo "  DIAGNOSIS"
echo "========================================="

# Simple diagnosis
if [ "$INBOX_AGE" -gt 3600 ] && [ -f "$T_HEARTBEAT" ] && [ "$T_AGE" -gt 600 ]; then
    echo -e "${RED}LIKELY ISSUE: Syncthing not running or paused${NC}"
    echo "Action: Open Syncthing app on phone and check status"
elif [ "$INBOX_AGE" -gt 1800 ]; then
    echo -e "${YELLOW}POSSIBLE ISSUE: T may not be sending, or sync delayed${NC}"
    echo "Action: Ask J to check T's side, or wait for sync"
else
    echo -e "${GREEN}Sync appears healthy${NC}"
fi

echo ""
echo "Run this script anytime to check sync status."
echo "T should have matching script: scripts/wsl/sync-check.sh"
