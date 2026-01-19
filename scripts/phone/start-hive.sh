#!/bin/bash
# Start the Hive in WSL
# Creates tmux session with watcher and claude windows

SYNC_DIR="/mnt/c/Users/pkoaw/claude-sync"
SESSION="hive"

# Kill existing session
tmux kill-session -t $SESSION 2>/dev/null

# Create new session with watcher window
tmux new-session -d -s $SESSION -n watcher

# Start watcher
tmux send-keys -t $SESSION:watcher "cd $SYNC_DIR && chmod +x watcher-wsl.sh && ./watcher-wsl.sh" Enter

# Create claude window
tmux new-window -t $SESSION -n claude

# Start Claude
tmux send-keys -t $SESSION:claude "cd $SYNC_DIR && claude --dangerously-skip-permissions" Enter

# Attach to claude window
tmux select-window -t $SESSION:claude

echo "Hive started. Run: tmux attach -t hive"
