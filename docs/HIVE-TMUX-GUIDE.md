# The Hive - tmux Terminal Setup

No VS Code, no XFCE4, no proot needed. Pure terminal.

## Quick Start

```bash
# 1. Create the tmux session (one time)
~/claude-sync/hive-tmux-setup.sh

# 2. Attach to it
tmux attach -t hive

# 3. In window 1 (z-claude): start Claude Code
claude --dangerously-skip-permissions

# 4. Switch to window 0 (watcher): Ctrl+B then 0
# Start the watcher:
./auto-sync-tmux.sh

# 5. Switch back to z-claude: Ctrl+B then 1
```

## Window Layout

| Window | Name | Purpose |
|--------|------|---------|
| 0 | watcher | Runs auto-sync-tmux.sh (inotify watcher) |
| 1 | z-claude | Main Claude Code - receives /sync from T |
| 2 | work | Secondary Claude Code for other tasks |
| 3 | shell | General bash commands |

## tmux Cheatsheet

All commands start with `Ctrl+B`, then:

| Key | Action |
|-----|--------|
| 0-3 | Switch to window 0/1/2/3 |
| n | Next window |
| p | Previous window |
| c | Create new window |
| , | Rename current window |
| d | Detach (session keeps running!) |
| ? | Help |

## Syncthing Integration

```
Windows (T)                    Phone (Z)
───────────                    ─────────
from-windows.md  ──Syncthing──►  from-windows.md
                                      │
                               inotifywait detects
                                      │
                               tmux send-keys "/sync"
                                      │
                                      ▼
                               z-claude window
                               receives /sync
```

## Reconnecting

```bash
# After closing Termux or screen off:
tmux attach -t hive
# Everything is still there!
```

## Starting Fresh

```bash
# Kill existing session
tmux kill-session -t hive

# Recreate
~/claude-sync/hive-tmux-setup.sh
```

## Permission Bypass Mode

The `--dangerously-skip-permissions` flag lets Claude Code run without confirmation prompts. Essential for automated T↔Z sync.

```bash
claude --dangerously-skip-permissions
```

Without this flag, every file edit and bash command would require manual approval, breaking the autonomous workflow.

## Advantages Over VS Code Setup

| Old (VS Code) | New (tmux) |
|---------------|------------|
| Needs proot Debian | Termux native |
| Needs XFCE4 display | No GUI needed |
| xte requires focus | tmux send-keys always works |
| Polling (5s delay) | inotify (instant) |
| Dies if display closes | Survives disconnection |
| Heavy on battery | Lightweight |
