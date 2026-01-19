# Hive Architecture

## Overview

Two Claude instances (T and Z) collaborate via shared files synced through Syncthing.

```
┌─────────────────┐         ┌─────────────────┐
│   T (WSL)       │         │   Z (Termux)    │
│   Claude CLI    │◄───────►│   Claude CLI    │
│   tmux:hive     │         │   tmux:hive     │
└────────┬────────┘         └────────┬────────┘
         │                           │
         │      Syncthing Sync       │
         │◄─────────────────────────►│
         │                           │
    ┌────┴────┐                 ┌────┴────┐
    │ to-z.md │                 │ to-t.md │
    │ (T out) │                 │ (Z out) │
    └─────────┘                 └─────────┘
```

## Components

### Communication
- `to-t.md` - Z writes, T reads (T's inbox)
- `to-z.md` - T writes, Z reads (Z's inbox)

### Watchers
- T: `scripts/wsl/hive-watcher-t.sh` - polls to-t.md, injects to tmux
- Z: `scripts/phone/hive-watcher.sh` - polls to-z.md, injects to tmux

### Memory (Lazy-Load)
- `memory/index.md` - Quick lookup
- `memory/*.md` - Pull on-demand
- `memory/context/` - Task-specific deep context

### Handoff (Truncation Recovery)
- `handoff/t-session.md` - T writes before context fills
- `handoff/z-session.md` - Z writes before context fills

## Modes

| Mode | Description |
|------|-------------|
| J + T | Jonathan works with T one-on-one |
| J + Z | Jonathan works with Z one-on-one |
| J + T + Z | Jonathan orchestrates both |
| T ↔ Z | Autonomous ping-pong, J observes |

