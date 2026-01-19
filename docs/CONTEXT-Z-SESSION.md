# Z Node Context - Session Handoff

**Created:** 2026-01-18 13:59
**Purpose:** Continue this work in a new Claude Code session

---

## Who You Are

You are **Z**, a Claude Code instance running on Jonathan's Samsung Galaxy Z Fold 7 in Termux (native, not proot). You are part of **The Hive** - a distributed multi-Claude system.

Jonathan (J) is your human operator. He is NOT a coder - explain things clearly.

---

## The Hive Network

| Node | Platform | Role |
|------|----------|------|
| J | Human | Hub, decision-maker |
| T | Claude Code (Windows) | Twin - implementation |
| Z | Claude Code (Termux) | **YOU** - Twin + mobile |
| D | Claude Desktop | Strategy, heavy lifting |
| 7 | Claude Mobile App | Strategy, easy access |
| 8 | Claude Web | Universal fallback |

**T↔Z Bridge:** Syncthing syncs `~/claude-sync/` between Windows and this phone.

---

## What We Built This Session

### 1. Verified inotify Works in Termux
- `/proc/sys/fs/inotify` exists and functions
- `inotifywait` can watch files for instant change detection
- This was assumed broken but works fine in Termux native

### 2. Installed Claude Code Globally
```bash
npm install -g @anthropic-ai/claude-code
claude --version  # 2.1.12
```
Now just type `claude` instead of `npx @anthropic-ai/claude-code`

### 3. Created Headless Sync System
When T sends a message via Syncthing, Z automatically processes it:

```
from-windows.md changes
        ↓
hive-watcher.sh detects (inotify)
        ↓
hive-sync-processor.sh spawns headless Claude
        ↓
Claude reads message, does work, writes to from-phone.md
        ↓
Syncthing carries response to T
```

### 4. Created tmux Infrastructure (Optional)
For interactive work, there's a tmux session "hive" with windows:
- 0:watcher - for running the file watcher
- 1:z-claude - for interactive Claude
- 2:work - secondary Claude
- 3:shell - bash

---

## Key Files in ~/claude-sync/

| File | Purpose |
|------|---------|
| `CLAUDE.md` | Protocol - any Claude here knows The Hive rules |
| `CONTEXT-Z-SESSION.md` | **THIS FILE** - session handoff |
| `hive-watcher.sh` | Unified watcher (headless or tmux mode) |
| `hive-sync-processor.sh` | Spawns headless Claude for sync |
| `hive-tmux-setup.sh` | Creates the tmux session |
| `from-windows.md` | Messages FROM T (Windows) TO Z |
| `from-phone.md` | Z's responses TO T |
| `Z-INSTRUCTIONS.md` | Original sync protocol (still valid) |

---

## Current State

### Watcher Status
A watcher should be running in the background:
```bash
ps aux | grep hive-watcher
```

If not running, start it:
```bash
nohup ~/claude-sync/hive-watcher.sh headless >> ~/claude-sync/hive-watcher.log 2>&1 &
```

### tmux Session
Check if hive session exists:
```bash
tmux has-session -t hive && echo "exists" || echo "not running"
```

Create if needed:
```bash
~/claude-sync/hive-tmux-setup.sh
tmux attach -t hive
```

---

## How to Start This Session

```bash
# Start watcher in background (if not already running)
nohup ~/claude-sync/hive-watcher.sh headless >> ~/claude-sync/hive-watcher.log 2>&1 &

# Start Claude with bypass permissions
claude --dangerously-skip-permissions

# First message to Claude:
# "Read ~/claude-sync/CONTEXT-Z-SESSION.md and continue from where we left off"
```

---

## Important Technical Notes

1. **inotify works** in Termux native (not proot) - use it for instant file watching

2. **tmux shortcuts** don't work well with Jonathan's Bluetooth keyboard - use direct commands:
   ```bash
   tmux select-window -t hive:z-claude
   tmux select-window -t hive:watcher
   ```

3. **Headless Claude** works with simple prompts. Complex prompts may hang. Keep prompts short.

4. **Bash tool** sometimes has `/tmp` permission errors - use `Read` tool as fallback

5. **Screenshots** are at `/storage/emulated/0/DCIM/Screenshots/` - you can read them

6. **Copy/paste** with hardware keyboard: `Ctrl+Alt+V` to paste

---

## Pending/Future Work

1. **Test real T→Z sync** - have Windows Claude send a message
2. **Refine the protocol** - the headless sync format could be cleaner
3. **Explore other Hive enhancements** from the original ideas document
4. **Consider 7→Z→T pipeline** - mobile app triggering work

---

## Quick Reference Commands

```bash
# Check watcher status
ps aux | grep hive-watcher

# View watcher log
tail -20 ~/claude-sync/hive-watcher.log

# View sync log
tail -20 ~/claude-sync/hive-sync.log

# Check latest messages from T
tail -50 ~/claude-sync/from-windows.md

# Check latest responses to T
tail -50 ~/claude-sync/from-phone.md

# Kill all watchers
pkill -f hive-watcher

# Restart watcher
nohup ~/claude-sync/hive-watcher.sh headless >> ~/claude-sync/hive-watcher.log 2>&1 &
```

---

## Session Continuity

When you start a new session, say:

> "I'm continuing the Z node work. Read CONTEXT-Z-SESSION.md for context. The watcher should be running. What would you like to work on?"

Jonathan will guide from there.

---

*— Previous Z instance, 2026-01-18*
