# T&Z: Autonomous Claude-to-Claude Collaboration
**Autonomous Claude Collaboration System**

[![Project Genesis](https://img.shields.io/badge/NEW-Project%20Genesis-gold?style=for-the-badge)](https://infinite-grok.github.io/T-Z-Claude-Collaboration/docs/project-genesis.html)

T (Windows) ↔ Z (Phone) | Zero-Touch Deployment | 50+ Iteration Cycles

---

Two Claude Code instances (VS Code extension) collaborate 24/7 across Windows ↔ Android (Termux proot).

## What This Is

A production system where two Claude instances (T on Windows, Z on Android phone) autonomously collaborate via Syncthing-synced message files. No custom APIs, no special infrastructure—just Claude Code running in VS Code on both sides, talking to each other through file-based messages.

## Production Stats

After 50+ autonomous message exchanges:

- **Git corruption recovery:** Discovered git objects don't sync via Syncthing → implemented `.stignore` local-only git strategy
- **Watcher crash postmortem:** Z's daemon crashed at 17:04 → discovered at 17:52 → documented incident in living HTML doc
- **FileSystemWatcher double-fire fix:** T implemented `LastWriteTime` check to prevent duplicate /sync triggers
- **Proot PATH bypass:** Z uses `xte` GUI automation (not binary calls) → 8.5s max latency (poll 5s + confirm 3s + settle 0.5s)
- **Living documentation:** Both agents maintain `DEPENDENCIES.html` v1.5 (5 rounds of collaboration: Z→T→Z→T→T)
- **Protocol evolution:** v1.0 → v2.0 (versioning, locking) → v2.1 (ACT autonomously) → v2.2 (immutable files rule)

## Architecture

### Message Flow

```
T (Windows) writes → from-windows.md → Syncthing sync → Z (Phone) reads
Z (Phone) writes → from-phone.md → Syncthing sync → T (Windows) reads
```

### Auto-Sync Infrastructure

**T's Side (Windows):**
- `auto-sync-windows.ps1`: PowerShell FileSystemWatcher monitoring `from-phone.md`
- `auto-sync-trigger.ahk`: AutoHotkey v2 GUI automation (clicks coordinates, types `/sync`, presses Enter)
- Duplicate detection: `LastWriteTime` check prevents double-fire

**Z's Side (Android/Termux/Proot):**
- `auto-sync-phone-poll.sh`: Polling-based watcher (5s interval, 10s cooldown)
- `auto-sync-trigger-xte.sh`: `xte` GUI automation (BackSpace to clear, types `/sync`, presses Enter)
- Latency optimization: COOLDOWN reduced from 30s → 10s (max theoretical delay: 8.5s)

**Challenges:**
- No native inotify in userspace proot
- Claude binary embedded in VS Code extension (PATH issues)
- Termux sleep/wake management

**Solutions:**
- Polling-based file watcher (5-second interval)
- GUI automation via xautomation/xte
- Loop prevention via cooldown + edit detection

### Critical Infrastructure Protection

**Protocol v2.2 - Immutable Files Rule:**

T & Z may NEVER edit:
- Watcher scripts (`auto-sync-windows.ps1`, `auto-sync-phone-poll.sh`)
- Trigger scripts (`auto-sync-trigger.ahk`, `auto-sync-trigger-xte.sh`)
- Protocol docs (`PROTOCOL.md`, `DEPENDENCIES.md`)
- Sync config (`.stignore`)
- Version control (`.git/` directory)

**Response if user asks to "fix watcher":**
1. Reply: "Immutable files cannot be edited per protocol v2.2"
2. Suggest: "User must apply infrastructure changes manually"
3. STOP all actions

### Role Boundaries

- **T & Z:** Process messages, respond autonomously, commit project work, log operations
- **User:** Manage watchers, debug infrastructure, control Syncthing

## Quick Start

### Prerequisites

**T (Windows):**
- Windows 11
- PowerShell 5.1+
- AutoHotkey v2
- Syncthing
- VS Code with Claude Code extension

**Z (Android):**
- Android device with Termux
- Debian proot environment
- XFCE desktop + VNC
- `xautomation` package (`xte` command)
- Syncthing
- VS Code with Claude Code extension (running in proot)

### Setup

1. **Install Syncthing on both devices**
   - Create shared folder: `claude-sync/`
   - Configure to sync bidirectionally

2. **Copy scripts to each device**
   - Windows: `scripts/windows/*` → `C:\Users\[user]\claude-sync\`
   - Phone: `scripts/phone/*` → `~/claude-sync/`

3. **Create message files**
   ```bash
   # On both sides
   touch from-windows.md from-phone.md
   ```

4. **Start watchers**
   - **T:** Run `auto-sync-windows.ps1` in PowerShell
   - **Z:** Run `./auto-sync-phone-poll.sh` in background

5. **Test communication**
   - Trigger `/sync` on either side
   - Agents should start exchanging messages autonomously

## Documentation

- **[DEPENDENCIES.html](https://infinite-grok.github.io/T-Z-Claude-Collaboration/):** Complete system documentation (v1.5) - roles, infrastructure, incidents, lessons learned **[Live on GitHub Pages]**
- **[PROTOCOL.md](docs/PROTOCOL.md):** Message protocol specification (v2.1) - ACT autonomously, don't ask permission
- **[.stignore](.stignore):** Syncthing ignore patterns (critical: excludes `.git/` to prevent corruption)

**Note:** The living documentation (DEPENDENCIES.html) is published to GitHub Pages for easy viewing. Local copy available in `docs/`.

## Demo

See [demo/](demo/) for 60-second video walkthrough (coming soon).

## Known Issues & Solutions

### Git Corruption (RESOLVED)
- **Problem:** Git objects synced via Syncthing → corrupted T's repository
- **Solution:** `.stignore` excludes `.git/` on both sides, local-only git strategy
- **Documented:** sections 9.4, 10.1 in DEPENDENCIES.html

### Watcher Reliability
- **Issue:** Daemons can crash unexpectedly (Z's watcher crashed 2026-01-17 17:04)
- **Mitigation:** Monitor logs, restart manually when needed
- **Future:** Health check mechanism (not yet implemented)

### Latency Optimization
- **Initial:** 38s delays (COOLDOWN=30s + poll 5s + wait 3s)
- **Optimized:** 8.5s max (COOLDOWN=10s + poll 5s + wait 3s + settle 0.5s)
- **Trade-off:** Lower cooldown risks rapid re-triggers, higher ensures stability

### Phone-Specific Issues

**Issue:** Watcher dies when device sleeps
- **Solution:** Use `termux-wake-lock` or run in persistent terminal (tmux/screen)

**Issue:** xte fails with "Can't open display"
- **Solution:** Run watcher from terminal inside XFCE desktop, ensure DISPLAY=:0
- **Verify:** `echo $DISPLAY` should show `:0`

**Issue:** Claude binary not in PATH
- **Why:** Claude Code installed as VS Code extension
- **Solution:** Use GUI automation (xte), don't try to invoke binary directly

See [PHONE-SETUP.md](docs/PHONE-SETUP.md) for complete Android/Termux setup guide.

## Lessons Learned

1. **Git objects don't sync via file sync systems** - Use `.stignore` to exclude `.git/`
2. **Polling beats inotify in proot** - inotify unreliable in Termux proot, 5s polling more stable
3. **GUI automation > binary calls** - Proot PATH issues bypassed with `xte` keyboard simulation
4. **Living documentation works** - 5 rounds of T↔Z collaboration produced comprehensive, accurate docs
5. **Protocol evolution is critical** - v2.1 "ACT autonomously" transformed from report-only to true collaboration
6. **Infrastructure protection matters** - Immutable files rule prevents accidental agent modifications

## License

MIT License - See LICENSE file for details

## Authors

- **T (Windows Claude):** Infrastructure setup, FileSystemWatcher implementation, git recovery, documentation v1.2/v1.4/v1.5
- **Z (Phone Claude):** Polling watcher design, latency optimization (COOLDOWN fix), documentation v1.0/v1.1/v1.3
- **Human orchestrator:** System design, protocol definition, incident resolution

---

**Status:** Production-ready | **Version:** Protocol v2.2 | **Last Updated:** 2026-01-17
