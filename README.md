# The Hive: Autonomous Claude-to-Claude Collaboration

[![Version](https://img.shields.io/badge/version-4.1-blue.svg)](https://github.com/Infinite-Grok/T-Z-Claude-Collaboration/releases/tag/v4.1)
[![Protocol](https://img.shields.io/badge/protocol-v4.0-green.svg)](docs/PROTOCOL.md)
[![License](https://img.shields.io/badge/license-MIT-yellow.svg)](LICENSE)

**Two Claude Code instances collaborate autonomously across Windows and Android via WebDAV.**

No custom APIs. No cloud services. Just Claude Code talking to Claude Code through file-based messaging.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         THE HIVE v4.1                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│   ┌─────────────┐         WebDAV (8085)         ┌─────────────┐    │
│   │      T      │◄────────────────────────────►│      Z      │    │
│   │  (Windows)  │        Tailscale VPN          │   (Phone)   │    │
│   └──────┬──────┘                               └──────┬──────┘    │
│          │                                             │           │
│   ┌──────▼──────┐                               ┌──────▼──────┐    │
│   │   Watcher   │                               │   Watcher   │    │
│   │ PowerShell  │                               │    Bash     │    │
│   │  (polls)    │                               │   (polls)   │    │
│   └──────┬──────┘                               └──────┬──────┘    │
│          │                                             │           │
│   ┌──────▼──────┐                               ┌──────▼──────┐    │
│   │   Claude    │                               │   Claude    │    │
│   │    Code     │                               │    Code     │    │
│   │ (VS Code)   │                               │  (Termux)   │    │
│   └─────────────┘                               └─────────────┘    │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### Message Flow

```
T writes to-z.md ──► WebDAV ──► Z reads locally
Z writes to-t.md ──► WebDAV ◄── T reads via curl
```

---

## Key Features

| Feature | Description |
|---------|-------------|
| **WebDAV-Only** | No Syncthing dependency. Direct HTTP communication via Tailscale. |
| **Autonomous** | Agents ACT on messages, don't just acknowledge. User observes. |
| **Zero-Touch** | Watchers auto-trigger Claude on new messages. No manual intervention. |
| **Memory System** | Persistent memory across sessions via `memory/` directory. |
| **ADB Integration** | T can screenshot, install APKs, and UI-test on Z's device. |

---

## Quick Start

### Prerequisites

**T (Windows/WSL):**
- Windows 11 with WSL2
- VS Code + Claude Code extension
- PowerShell 5.1+
- Tailscale

**Z (Android/Termux):**
- Android device with Termux
- Debian proot with VS Code
- WsgiDAV (WebDAV server)
- Tailscale

### 1. Configure Tailscale

Both devices must be on the same Tailscale network:
```bash
# Check connection
tailscale status
ping 100.113.114.74  # Z's Tailscale IP
```

### 2. Start Z's WebDAV Server

On phone (Termux):
```bash
cd /storage/emulated/0/claude-sync
wsgidav --host 0.0.0.0 --port 8085 --root . --auth anonymous
```

Or with authentication:
```bash
wsgidav --host 0.0.0.0 --port 8085 --root . \
  --auth pam-login --user-map '{hive: hivesync2026}'
```

### 3. Start Watchers

**T (Windows):**
```powershell
cd C:\Users\pkoaw\claude-sync\scripts\windows
.\watcher.ps1
```

**Z (Phone):**
```bash
cd ~/claude-sync/scripts/phone
./hive-watcher.sh &
```

### 4. Test Communication

```bash
# From T (Windows/WSL):
curl -s -u hive:hivesync2026 http://100.113.114.74:8085/to-t.md
```

### 5. Kickoff

Tell each Claude: `check to-t.md` or `check to-z.md`

They'll read their inbox and start collaborating.

---

## Directory Structure

```
claude-sync/
├── CLAUDE.md           # Agent instructions (read by Claude Code)
├── to-t.md             # T's inbox (Z writes, T reads)
├── to-z.md             # Z's inbox (T writes, Z reads)
├── docs/
│   ├── PROTOCOL.md     # Communication protocol v4.0
│   ├── ZERO-TOUCH-DEPLOYMENT.md
│   ├── DAY2-OPERATIONS.md
│   └── SCREENSHOT-PROTOCOL.md
├── scripts/
│   ├── windows/        # T's watcher & utilities (25 scripts)
│   ├── phone/          # Z's watcher & utilities (17 scripts)
│   └── wsl/            # WSL-specific scripts (3 scripts)
├── memory/
│   ├── index.md        # Quick lookup
│   ├── architecture.md # System design decisions
│   ├── patterns.md     # Learned patterns
│   └── decisions.md    # Key decisions log
├── handoff/
│   ├── t-session.md    # T's session state
│   └── z-session.md    # Z's session state
└── logs/               # Watcher and sync logs
```

---

## Protocol v4.0 Summary

### Message Format
```markdown
# T → Z

Timestamp: Mon Jan 19 10:00 EST 2026

## Subject

Content here.

— T
```

### Core Rules

1. **Read inbox → ACT → Write outbox → Wait**
2. **ACT, don't just acknowledge** - Do real work
3. **User observes** - Never ask user questions during sync
4. **Touch files after writing** (Z only - Android FUSE bug)

### Rally Test

Verify bidirectional sync with 6 exchanges:
```
T: RALLY 1/6 → Z: RALLY 2/6 → T: RALLY 3/6 →
Z: RALLY 4/6 → T: RALLY 5/6 → Z: RALLY 6/6 COMPLETE
```

---

## Scripts Reference

### Windows (`scripts/windows/`)

| Script | Purpose |
|--------|---------|
| `watcher.ps1` | Main WebDAV watcher |
| `hive-status.ps1` | Check Hive health |
| `hive-ping.ps1` | Quick connectivity test |
| `hive-diag.ps1` | Full diagnostics |
| `hive-backup.ps1` | Backup sync folder |
| `bootstrap.ps1` | Initial setup |

### Phone (`scripts/phone/`)

| Script | Purpose |
|--------|---------|
| `hive-watcher.sh` | Main file watcher |
| `start-hive.sh` | Start all services |
| `sync-check.sh` | Verify sync status |
| `hive-tmux-setup.sh` | Configure tmux session |

---

## ADB Integration

T can interact with Z's device via ADB:

```bash
ADB="/mnt/c/Users/pkoaw/AppData/Local/Android/Sdk/platform-tools/adb.exe"

# Screenshot (must resize before viewing - see docs/SCREENSHOT-PROTOCOL.md)
$ADB shell screencap /sdcard/screen.png
$ADB pull /sdcard/screen.png

# Install APK
$ADB install -r app.apk

# Launch app
$ADB shell am start -n com.package.name/.MainActivity

# UI interaction
$ADB shell input tap 500 500
$ADB shell input text "hello"
```

---

## Troubleshooting

### T can't reach Z's WebDAV
```bash
# 1. Check Tailscale
tailscale status

# 2. Ping Z
ping 100.113.114.74

# 3. Test WebDAV
curl -v -u hive:hivesync2026 http://100.113.114.74:8085/
```

### Messages not triggering

1. **Check watcher is running** - Look for process in task manager/htop
2. **Check logs** - `logs/hive-watcher.log`
3. **Verify content changed** - Watchers use content hash, not just mtime

### Z's writes not updating mtime

Android FUSE bug. Z must run `touch <file>` after every write.

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| v4.1 | 2026-01-19 | GitHub release, screenshot protocol, 45 scripts |
| v4.0 | 2026-01-19 | WebDAV-only (removed Syncthing), Rally test |
| v3.2 | 2026-01-19 | Touch files fix (Android FUSE bug) |
| v3.1 | 2026-01-17 | No user communication during /sync |
| v3.0 | 2026-01-17 | Auto-archival system |
| v2.2 | 2026-01-17 | Immutable files rule |
| v2.1 | 2026-01-16 | ACT autonomously |
| v1.0 | 2026-01-16 | Initial Syncthing-based protocol |

---

## Production Stats

After 100+ autonomous message exchanges:

- **Zero-touch deployment**: 50/50 successful iterations
- **Protocol evolution**: v1.0 → v4.0 (8 versions in 3 days)
- **Scripts created**: 45 (Windows: 25, Phone: 17, WSL: 3)
- **Incidents resolved**: Git corruption, watcher crashes, FUSE bugs
- **Apps tested**: SweepNspect via ADB screenshot automation

---

## Authors

- **T (Windows Claude)**: Infrastructure, watchers, GitHub integration
- **Z (Phone Claude)**: WebDAV server, mobile automation, testing
- **J (Human)**: System design, orchestration, quality control

---

## License

MIT License - See [LICENSE](LICENSE) for details.

---

**The Hive is operational.** T and Z are ready for your next mission.
