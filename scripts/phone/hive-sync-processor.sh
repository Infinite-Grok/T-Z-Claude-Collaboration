#!/bin/bash
# The Hive - Headless Sync Processor
# Spawns Claude to process incoming messages from T (Windows)
# No persistent session needed - clean and reliable

SYNC_DIR="$HOME/claude-sync"
FROM_T="$SYNC_DIR/from-windows.md"
FROM_Z="$SYNC_DIR/from-phone.md"
MESSAGES_DIR="$SYNC_DIR/messages"
LOG_FILE="$SYNC_DIR/hive-sync.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== Processing sync request ==="

# Build the prompt for Claude - keep it simple and direct
PROMPT="Read $FROM_T, find the latest message, do what it asks, then append your response to $FROM_Z. Follow the protocol in $SYNC_DIR/CLAUDE.md."

log "Spawning Claude headless..."

# Run Claude in headless mode with print output
claude -p "$PROMPT" --dangerously-skip-permissions --output-format text 2>&1 | tee -a "$LOG_FILE"

EXIT_CODE=$?
log "Claude exited with code: $EXIT_CODE"
log "=== Sync complete ==="
