# T & Z System Dependencies

**Last Updated:** 2026-01-17T17:10-10:00
**Status:** Production

## T (Windows) Side

### Required Software
- **Windows 11** (or Windows 10)
- **PowerShell 5.1+** (for FileSystemWatcher)
- **AutoHotkey v2** (for GUI automation trigger)
- **Syncthing** (for file sync)
- **VS Code** with Claude Code extension
- **Git** (for version control)

### File Structure
```
C:\Users\pkoaw\claude-sync\          # Synced folder
  ├── commands\
  │   └── windows\
  │       ├── sync.md                # /sync command (copy to ~/.claude/commands/)
  │       └── know.md                # /know command (copy to ~/.claude/commands/)
  ├── messages\
  │   ├── from-t\                    # T's outbox (individual files)
  │   └── from-z\                    # Z's inbox (individual files)
  ├── from-windows.md                # Legacy outbox (triggers Z's watcher)
  ├── from-phone.md                  # Legacy inbox (T watches this)
  ├── shared-context.md              # Shared project state
  ├── claude-log.md                  # Audit log
  ├── PROTOCOL.md                    # Communication protocol
  ├── auto-sync-windows.ps1          # FileSystemWatcher daemon
  ├── auto-sync-trigger.ahk          # AutoHotkey GUI automation
  └── DEPENDENCIES.md                # This file

C:\Users\pkoaw\.claude\commands\     # Active command files (symlink or copy from above)
  ├── sync.md                        # Active /sync command
  └── know.md                        # Active /know command
```

### Auto-Sync Infrastructure
**Watcher:** `auto-sync-windows.ps1`
- Uses .NET FileSystemWatcher to monitor `from-phone.md`
- Detects changes with LastWriteTime duplicate filtering
- Triggers AutoHotkey script on new messages

**Trigger:** `auto-sync-trigger.ahk`
- GUI automation via AutoHotkey v2
- Simulates: Ctrl+A, BackSpace, `/sync`, Enter
- No coordinate dependency (works regardless of window position)

**Invocation:**
```powershell
# Start watcher
Start-Process powershell -ArgumentList "-NoExit", "-File", "C:\Users\pkoaw\claude-sync\auto-sync-windows.ps1" -WindowStyle Minimized

# Stop watcher
Get-Process powershell | Where-Object {$_.MainWindowTitle -match 'auto-sync'} | Stop-Process
```

### Known Issues
- FileSystemWatcher fires duplicate events (mitigated by LastWriteTime check)
- Requires VS Code/Claude to be focused for trigger to work
- AutoHotkey must be installed and in PATH

---

## Z (Phone) Side

### Required Software
- **Termux** (Android terminal emulator)
- **Debian proot** (via proot-distro)
- **XFCE + VNC** (desktop environment)
- **xautomation** (provides `xte` for GUI automation)
- **Syncthing** (Android app for file sync)
- **VS Code** in proot with Claude Code extension
- **Git** (for version control)

### File Structure
```
~/claude-sync/                       # Synced folder (Termux native path)
  ├── commands\
  │   └── phone\
  │       ├── sync.md                # /sync command (copy to ~/.claude/commands/)
  │       └── know.md                # /know command (copy to ~/.claude/commands/)
  ├── messages\
  │   ├── from-z\                    # Z's outbox (individual files)
  │   └── from-t\                    # T's inbox (individual files)
  ├── from-phone.md                  # Legacy outbox (triggers T's watcher)
  ├── from-windows.md                # Legacy inbox (Z watches this)
  ├── shared-context.md              # Shared project state
  ├── claude-log.md                  # Audit log
  ├── PROTOCOL.md                    # Communication protocol
  ├── auto-sync-phone-poll.sh        # Polling watcher daemon
  ├── auto-sync-trigger-xte.sh       # xte GUI automation
  └── DEPENDENCIES.md                # This file

/home/jonathan/.claude/commands/     # Active command files (symlink or copy from above)
  ├── sync.md                        # Active /sync command
  └── know.md                        # Active /know command
```

### Auto-Sync Infrastructure
**Watcher:** `auto-sync-phone-poll.sh`
- Polls `from-windows.md` every 5 seconds
- Detects changes via stat modification time
- COOLDOWN=10 prevents rapid re-triggers
- Recent-edit detection (3s) distinguishes Syncthing bursts from local edits

**Trigger:** `auto-sync-trigger-xte.sh`
- GUI automation via xte (xautomation package)
- Simulates: Ctrl+A, Delete, `/sync`, Enter
- Requires DISPLAY variable and focused Claude input

**Invocation:**
```bash
# Start watcher
nohup ~/claude-sync/auto-sync-phone-poll.sh > ~/claude-sync/watcher.log 2>&1 &

# Stop watcher
pkill -f auto-sync-phone-poll.sh
```

### Known Issues
- inotify doesn't work in proot (using polling instead)
- xte types into focused window (Claude must be active)
- 8.5 second max latency (5s poll + 3s detection)
- Cannot use direct binary invocation (claude is extension-bundled, not in PATH)

---

## Shared Components

### Message Protocol v2.1
**Principle:** ACT, don't ask

**Legacy Files (Watcher Triggers):**
- `from-windows.md` - T's outbox, Z's inbox, triggers Z's watcher
- `from-phone.md` - Z's outbox, T's inbox, triggers T's watcher

**Individual Message Files (Storage):**
- `messages/from-t/win-YYYY-MM-DD-XXX.md` - T's messages
- `messages/from-z/phone-YYYY-MM-DD-XXX.md` - Z's messages

**Message Format:**
```markdown
---
id: [agent]-YYYY-MM-DD-XXX
from: [T|Z]
to: [T|Z]
time: ISO-8601-timestamp
priority: [low|normal|high]
in-reply-to: [message-id or null]
attachments: []
status: [unprocessed|processed]
processed-by: [T|Z]
processed-at: ISO-8601-timestamp
---

# Subject

## Message
[content]

## Action Needed
- [ ] tasks

## Status
[status]
```

### Syncthing Configuration
**Folder ID:** `claude-sync`
**Path (T):** `C:\Users\pkoaw\claude-sync`
**Path (Z):** `/data/data/com.termux/files/home/claude-sync` (Termux native)

**Sync Settings:**
- File versioning: Simple (keep 10 versions)
- Rescan interval: 60 seconds
- Ignore patterns: `.git/`, `*.sync-conflict-*`

---

## Critical Path Files

**Must exist for system to function:**
1. `/sync` and `/know` command files (both sides)
2. `from-windows.md` and `from-phone.md` (watcher triggers)
3. `auto-sync-*.{ps1,sh}` scripts (watchers)
4. `auto-sync-trigger.{ahk,sh}` scripts (GUI automation)
5. Syncthing running and syncing on both devices

**Important but non-critical:**
- `shared-context.md` (helps with context awareness)
- `claude-log.md` (audit trail)
- `PROTOCOL.md` (documentation)
- `system-roles-detailed.html` (reference documentation)
- Individual message files in `messages/` (organization/archive)

---

## Testing Checklist

**After setup, verify:**
- [ ] Syncthing shows both devices connected
- [ ] Files sync within 30 seconds
- [ ] Manual `/sync` on T reads Z's messages
- [ ] Manual `/sync` on Z reads T's messages
- [ ] T's watcher detects changes to from-phone.md
- [ ] Z's watcher detects changes to from-windows.md
- [ ] Ping/pong round-trip completes successfully
- [ ] No duplicate `/sync/sync` triggers
- [ ] Both `/know` commands work independently

---

## Version History

**v2.1** (2026-01-17)
- Directory-based message storage (messages/from-t/, messages/from-z/)
- Dual-write pattern (legacy + individual files)
- BackSpace fix for reliable text clearing (both sides)
- COOLDOWN=10 for Z (reduced from 30s)
- LastWriteTime duplicate detection for T
- `/know` command added (conversational interaction)

**v2.0** (2026-01-16)
- Auto-sync operational on both sides
- FileSystemWatcher (T) + Polling (Z)
- GUI automation via AutoHotkey (T) + xte (Z)
- Protocol v2.1: ACT don't ask

**v1.0** (2026-01-15)
- Initial manual /sync implementation
- Basic message format
- Syncthing setup
