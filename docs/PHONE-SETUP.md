# Phone Setup Guide (Android/Termux)

Complete setup instructions for running Phone Claude (Z) on Android using Termux/proot/Debian.

## Android/Termux Setup

### Prerequisites

- Android device (tested on Z Fold 7)
- Termux (0.118+)
- proot-distro (Debian recommended)

### Installation Steps

#### 1. Install Termux from F-Droid (NOT Google Play)

**Critical:** The Google Play version of Termux is outdated and incompatible. Use F-Droid.

Download F-Droid: https://f-droid.org/
Install Termux from F-Droid app store

#### 2. Install proot-distro

```bash
pkg install proot-distro
proot-distro install debian
```

#### 3. Install XFCE Desktop

```bash
proot-distro login debian
apt update && apt upgrade
apt install xfce4 xfce4-goodies
```

#### 4. Install xautomation (for xte)

```bash
apt install xautomation
```

This provides the `xte` command used by the auto-sync trigger script for GUI automation.

#### 5. Install VS Code

Follow standard VS Code installation for Debian Linux.

#### 6. Install Claude Code VS Code Extension

Install the Claude Code extension through VS Code's extension marketplace.

### Critical Gotchas

#### ⚠️ PATH Issue: Claude Binary Not in System PATH

**Problem:** Claude Code is installed as a VS Code extension, not a system-wide binary.

**Impact:** Cannot invoke `claude` command directly from scripts.

**Solution:** Use GUI automation (xte) to trigger /sync via keyboard input instead of direct binary invocation.

#### ⚠️ DISPLAY Variable Must Be Set

**Problem:** xte requires X11 DISPLAY to send keyboard events.

**Verification:**
```bash
echo $DISPLAY
# Should show `:0` or similar
```

**Solution:** Run the auto-sync watcher from a terminal inside the XFCE desktop environment, NOT from SSH or external shell.

#### ⚠️ Wake Lock: Termux May Sleep and Kill Watcher

**Problem:** Android power management can suspend Termux and terminate the watcher daemon.

**Solutions:**
- Use `termux-wake-lock` to prevent suspension
- Run watcher in persistent terminal (tmux/screen)
- Keep Termux app in foreground or exempt from battery optimization

**Enable wake lock:**
```bash
termux-wake-lock
```

### File Paths

On Termux/proot, paths differ from standard Linux:

| Context | Path |
|---------|------|
| Termux native | `/data/data/com.termux/files/home/` |
| Proot Debian | `/home/jonathan/` (appears as `~/` in proot) |
| Sync folder | `~/claude-sync/` (same in both contexts) |
| Claude commands | `/home/jonathan/.claude/commands/` |

### Installation Verification

After completing setup, verify all components:

```bash
# 1. Check DISPLAY is set
echo $DISPLAY
# Expected: :0

# 2. Verify xte is installed
which xte
# Expected: /usr/bin/xte

# 3. Check sync folder exists
ls -la ~/claude-sync/
# Expected: Directory with protocol files

# 4. Verify scripts are executable
ls -la ~/claude-sync/*.sh
# Expected: -rwxr-xr-x permissions

# 5. Test xte (should type text in focused window)
xte 'str test'
```

## Known Issues & Solutions

### Issue: Watcher Dies When Device Sleeps

**Symptom:** Auto-sync stops working after device has been idle.

**Root Cause:** Android power management suspends Termux.

**Solution:**
```bash
# Option 1: Wake lock
termux-wake-lock

# Option 2: Run in persistent session
tmux new -s claude-sync
./auto-sync-phone-poll.sh
# Detach with Ctrl+B, D
```

### Issue: xte Fails with "Can't open display"

**Symptom:** Auto-sync trigger script errors with display connection failure.

**Root Cause:** DISPLAY environment variable not set or watcher not running in X11 session.

**Solution:**
1. Run watcher from terminal inside XFCE desktop environment
2. Verify `echo $DISPLAY` shows `:0`
3. Do NOT run watcher from SSH or external terminal

### Issue: Claude Binary Not in PATH

**Symptom:** Scripts cannot find `claude` command.

**Root Cause:** Claude Code is installed as VS Code extension, binary is embedded in extension directory.

**Why This Is Okay:** We use GUI automation (xte) to trigger /sync via keyboard input rather than invoking the binary directly. This is the intended design.

**Solution:** No action needed. The xte-based approach works around this limitation.

### Issue: Sync Messages Not Received

**Debugging Steps:**

1. **Check watcher is running:**
   ```bash
   ps aux | grep auto-sync-phone-poll
   ```

2. **Check Syncthing sync status:**
   - Open Syncthing web UI
   - Verify folder shows "Up to Date"
   - Check for sync conflicts

3. **Verify file permissions:**
   ```bash
   ls -la ~/claude-sync/from-windows.md
   # Should be readable and writable
   ```

4. **Check watcher logs:**
   - Watcher outputs to terminal
   - Look for error messages or failures

5. **Manual trigger test:**
   ```bash
   # In VS Code with focus, manually trigger /sync
   cd ~/claude-sync
   xte 'str /sync'
   xte 'key Return'
   ```

## Architecture: Phone Claude (Z)

### Environment Stack

```
Android (Z Fold 7)
  └─ Termux (Android terminal emulator)
      └─ proot-distro (Debian container)
          └─ XFCE (Desktop environment)
              └─ VS Code
                  └─ Claude Code Extension
```

### Challenges

1. **No native inotify in userspace proot**
   - Cannot use file watching APIs available in native Linux
   - Solution: Polling-based file watcher (5-second interval)

2. **Claude binary embedded in VS Code extension**
   - Cannot invoke claude command from PATH
   - Solution: GUI automation via xautomation/xte

3. **Termux sleep/wake management**
   - Android power management suspends background processes
   - Solution: Wake locks, persistent terminal sessions (tmux/screen)

### Design Decisions

**Polling vs. inotify:**
- Chose polling with 5-second interval
- inotify not available in proot userspace
- 5 seconds balances responsiveness vs. battery/CPU

**GUI automation vs. direct invocation:**
- Chose xte keyboard simulation
- Claude binary path is dynamic (embedded in extension)
- GUI approach is more robust across VS Code updates

**Loop prevention:**
- Cooldown period after each trigger
- Edit detection to avoid triggering on own writes
- Message-ID tracking to prevent duplicate processing

## Next Steps

After completing setup:

1. Copy `/sync` command to Claude commands directory:
   ```bash
   cp ~/claude-sync/phone-sync-command.md /home/jonathan/.claude/commands/sync.md
   ```

2. Start the auto-sync watcher:
   ```bash
   cd ~/claude-sync
   ./auto-sync-phone-poll.sh
   ```

3. Test the system:
   - From Windows, send a message via /sync
   - Watch Z's terminal for watcher activity
   - Verify message appears in VS Code

4. Enable wake lock for production use:
   ```bash
   termux-wake-lock
   ```

## See Also

- [PROTOCOL.md](PROTOCOL.md) - Communication protocol specification
- [DEPENDENCIES.html](../index.html) - Living documentation of the system
- [Main README](../README.md) - System overview and quick start
