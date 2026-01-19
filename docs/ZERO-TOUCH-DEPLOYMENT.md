# Zero-Touch Deployment Guide

## Overview

The Hive Zero-Touch Deployment installs and configures the complete T↔Z communication system with a single command per node.

## Quick Start

### Windows/WSL (T Node)
```powershell
# Download and run installer
Invoke-WebRequest -Uri "http://100.113.114.74:8085/scripts/windows/install-hive.ps1" -OutFile install-hive.ps1 -Headers @{Authorization="Basic aGl2ZTpoaXZlc3luYzIwMjY="}
powershell -ExecutionPolicy Bypass -File install-hive.ps1
```

### Termux (Z Node)
```bash
# Download and run installer
curl -u hive:hivesync2026 http://100.113.114.74:8085/scripts/phone/install-hive.sh -o install-hive.sh
bash install-hive.sh
```

---

## Prerequisites

### Windows (T)
- Windows 10/11
- Tailscale installed and connected
- PowerShell 5.1+

### Termux (Z)
- Termux app installed
- Tailscale VPN connected
- Storage permission granted (`termux-setup-storage`)

---

## What Gets Installed

### Windows (T)
| Component | Location | Purpose |
|-----------|----------|---------|
| Watcher script | `scripts/windows/watcher.ps1` | Polls WebDAV, triggers sync |
| Scheduled task | HiveWatcher | Auto-start at login |
| Startup shortcut | `Startup/HiveWatcher.bat` | Backup auto-start |
| Folder structure | `%USERPROFILE%\claude-sync\` | Sync files, logs, memory |

### Termux (Z)
| Component | Location | Purpose |
|-----------|----------|---------|
| WebDAV server | WsgiDAV on port 8085 | Serve sync files |
| Watcher script | `scripts/phone/hive-watcher.sh` | Monitor changes, trigger sync |
| tmux session | `hive` | Persistent Claude + watcher |
| Folder structure | `~/claude-sync/` | Sync files, logs, memory |

---

## Integration Test Checklist

### Pre-Test Setup
- [ ] Both T and Z installers downloaded
- [ ] Tailscale connected on both devices
- [ ] Fresh environment (or backup existing claude-sync/)

### T Node Tests
- [ ] `install-hive.ps1` runs without errors
- [ ] Folder structure created
- [ ] HiveWatcher task exists and Running
- [ ] Can ping Z's Tailscale IP
- [ ] Can curl Z's WebDAV

### Z Node Tests
- [ ] `install-hive.sh` runs without errors
- [ ] Dependencies installed (python, wsgidav)
- [ ] WebDAV server running (port 8085)
- [ ] Watcher running in tmux
- [ ] Can ping T's Tailscale IP

### End-to-End Tests
- [ ] T can read `to-t.md` from Z's WebDAV
- [ ] T can write `to-z.md` to Z's WebDAV
- [ ] Z's watcher detects T's write
- [ ] Z can respond (write to-t.md)
- [ ] T's watcher detects Z's response
- [ ] Rally test passes (6 exchanges)

---

## Troubleshooting

### T: "Cannot reach Z's WebDAV"
1. Check Tailscale: `tailscale status`
2. Ping Z: `ping 100.113.114.74`
3. Check Z's WebDAV is running: `curl -u hive:hivesync2026 http://100.113.114.74:8085/`

### Z: "WebDAV not starting"
1. Check port not in use: `netstat -tuln | grep 8085`
2. Restart WebDAV: `pkill -f wsgidav && wsgidav -c ~/.hive/wsgidav.yaml &`
3. Check Python packages: `pip list | grep -i wsgidav`

### T: Watcher not triggering
1. Check task status: `Get-ScheduledTask -TaskName HiveWatcher`
2. Check watcher log: `type C:\Users\pkoaw\claude-sync\watcher.log`
3. Verify content actually changed (hash-based detection)

### Z: Watcher not triggering
1. Check tmux session: `tmux ls`
2. Check watcher process: `pgrep -f hive-watcher`
3. Ensure file was touched after write

---

## Verification Commands

### T (PowerShell)
```powershell
# Check watcher status
Get-ScheduledTask -TaskName HiveWatcher

# Check connectivity
curl.exe -u hive:hivesync2026 http://100.113.114.74:8085/to-t.md

# View watcher log
Get-Content C:\Users\pkoaw\claude-sync\watcher.log -Tail 20
```

### Z (Bash)
```bash
# Check services
pgrep -f wsgidav && echo "WebDAV: OK"
pgrep -f hive-watcher && echo "Watcher: OK"

# Check connectivity
ping -c 1 100.113.114.74

# View watcher log
tail -20 ~/claude-sync/logs/watcher.log
```

---

## Protocol v4.0 Reference

- **No Syncthing** - Direct WebDAV communication
- **T reads/writes via curl** to Z's WebDAV
- **Z reads/writes locally** + touches files
- **Watchers**: Content-hash (T), mtime (Z)
- **Cooldown**: 90s (T), 60s health check (Z)

---

## Version History
- v1.0 (Jan 19, 2026): Initial Zero-Touch Deployment
