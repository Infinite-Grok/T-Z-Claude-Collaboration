#!/bin/bash
# The Hive - tmux Session Setup
# Creates a multi-window tmux session for Z node operations
#
# Windows:
#   0:watcher  - inotify watcher for Syncthing triggers
#   1:z-claude - Main Claude Code instance (receives /sync commands)
#   2:work     - Secondary Claude Code for general tasks
#   3:shell    - General bash for manual commands

SESSION="hive"
SYNC_DIR="$HOME/claude-sync"
TMUX="/data/data/com.termux/files/usr/bin/tmux"

# Check if session already exists
if "$TMUX" has-session -t "$SESSION" 2>/dev/null; then
    echo "Session '$SESSION' already exists."
    echo "  Attach with: tmux attach -t $SESSION"
    echo "  Kill with:   tmux kill-session -t $SESSION"
    exit 0
fi

echo "Creating Hive tmux session..."

# Create session with first window (watcher)
"$TMUX" new-session -d -s "$SESSION" -n watcher -c "$SYNC_DIR"

# Create z-claude window for main sync operations
"$TMUX" new-window -t "$SESSION" -n z-claude -c "$HOME"

# Create work window for general tasks
"$TMUX" new-window -t "$SESSION" -n work -c "$HOME"

# Create shell window for manual commands
"$TMUX" new-window -t "$SESSION" -n shell -c "$SYNC_DIR"

# Set up the watcher window with instructions
"$TMUX" send-keys -t "$SESSION:watcher" "# Watcher window - run: ./auto-sync-tmux.sh" Enter
"$TMUX" send-keys -t "$SESSION:watcher" "echo 'Ready to start watcher. Run: ./auto-sync-tmux.sh'" Enter

# Set up z-claude window with instructions
"$TMUX" send-keys -t "$SESSION:z-claude" "# Z-Claude window - this receives /sync triggers" Enter
"$TMUX" send-keys -t "$SESSION:z-claude" "echo 'Start Claude Code: claude --dangerously-skip-permissions'" Enter

# Go to z-claude window by default
"$TMUX" select-window -t "$SESSION:z-claude"

echo ""
echo "=== Hive tmux session created ==="
echo ""
echo "Windows:"
echo "  0:watcher  - Run the file watcher here"
echo "  1:z-claude - Main Claude Code (receives /sync)"
echo "  2:work     - Secondary Claude Code"
echo "  3:shell    - General commands"
echo ""
echo "Attach with:"
echo "  tmux attach -t $SESSION"
echo ""
echo "Switch windows: Ctrl+B then 0/1/2/3"
echo "Detach:         Ctrl+B then d"
echo ""
