# Hive Day 2 Operations Guide

**Version:** 1.0
**Date:** January 19, 2026

This document covers ongoing operations, maintenance, and scaling of The Hive system.

---

## 1. Log Management

### T Node (Windows) Logs

| Log | Location | Purpose |
|-----|----------|---------|
| Watcher log | `claude-sync\watcher.log` | WebDAV polling, sync triggers |
| Daily status | `claude-sync\logs\daily-status.log` | 8AM health snapshots |
| Diagnostics | `claude-sync\logs\diag-*.txt` | On-demand system dumps |

**Rotation:**
```powershell
# Manual rotation
.\scripts\windows\hive-rotate-logs.ps1

# Settings: Max 1MB, keep last 5 rotated logs
```

**Retention:** 7 days recommended. Older logs auto-deleted on rotation.

### Z Node (Termux) Logs

| Log | Location | Purpose |
|-----|----------|---------|
| Watcher log | `~/claude-sync/logs/watcher.log` | File monitoring, sync triggers |
| WebDAV log | `~/.hive/wsgidav.log` | HTTP requests, errors |
| Health check | `~/claude-sync/logs/health.log` | Periodic health results |

**Rotation:**
```bash
# Manual rotation
./scripts/phone/hive-rotate-logs.sh

# Auto-rotation: Enabled in watcher (max 10MB)
```

---

## 2. Monitoring

### Health Checks

**T Node:**
```powershell
# Quick status (one line)
.\scripts\windows\hive-status.ps1

# Full health check
.\scripts\windows\hive-health.ps1

# Connection test
.\scripts\windows\hive-test.ps1
```

**Z Node:**
```bash
# Quick status
./scripts/phone/quick-status.sh

# Full health check (with auto-fix)
./scripts/phone/health-check.sh --fix

# Connection test
./scripts/phone/hive-test.sh
```

### Automated Monitoring

| Check | Schedule | Node |
|-------|----------|------|
| Daily status | 8:00 AM | T |
| Health touch | Every 60s | Z |
| WebDAV poll | Every 2s | T |

### Alerts

Currently manual. Check logs for:
- `ERROR` - Immediate attention needed
- `WARN` - Investigate when possible
- `TIMEOUT` - Network/connectivity issue

---

## 3. Scaling (Adding Nodes)

### Adding Another Windows Node (T2)

1. Install using bootstrap:
```powershell
irm http://100.113.114.74:8085/scripts/windows/bootstrap.ps1 -Headers @{Authorization='Basic aGl2ZTpoaXZlc3luYzIwMjY='} | iex
```

2. Update config with unique identity:
```powershell
# Edit hive.config.ps1
$HiveConfig.NODE_ID = "T2"
```

3. Create dedicated inbox: `to-t2.md`

4. Update watchers to monitor new inbox

### Adding Another Phone Node (Z2)

1. Install Termux + Tailscale
2. Run bootstrap:
```bash
curl -su hive:hivesync2026 http://100.113.114.74:8085/scripts/phone/bootstrap.sh | bash
```

3. Configure unique identity in `~/.hive/config.sh`

4. Create dedicated inbox: `to-z2.md`

### Multi-Node Topology

```
        [Z - WebDAV Server]
       /        |        \
      T1        T2       Z2
     (WSL)    (WSL)   (Termux)
```

Note: Z remains the WebDAV server. All nodes read/write through Z.

---

## 4. Backup & Restore

### T Node Backup

```powershell
# Create backup
.\scripts\windows\hive-backup.ps1

# Location: claude-sync\backups\hive-backup-YYYYMMDD-HHMMSS.zip
# Contents: to-t.md, to-z.md, memory/, handoff/, docs/, config
```

### Z Node Backup

```bash
# Create backup
./scripts/phone/hive-backup.sh

# Location: ~/claude-sync/backups/hive-backup-YYYYMMDD.tar.gz
```

### Restore Procedure

1. Stop all services:
```powershell
# T
Stop-ScheduledTask HiveWatcher
```
```bash
# Z
./scripts/phone/hive-ctl.sh stop
```

2. Extract backup to claude-sync folder

3. Restart services:
```powershell
# T
Start-ScheduledTask HiveWatcher
```
```bash
# Z
./scripts/phone/hive-ctl.sh start
```

---

## 5. Troubleshooting

### Common Issues

| Symptom | Likely Cause | Fix |
|---------|--------------|-----|
| Watcher not triggering | Content unchanged (hash same) | Ensure actual content change |
| WebDAV timeout | Z phone asleep/disconnected | Wake phone, check Tailscale |
| "No Windows Terminal" | Wrong window targeted | Ensure Terminal is open |
| Stale dashboard | Z not touching files | Z must `touch` after write |
| Auth failed | Wrong credentials | Check hive:hivesync2026 |

### Diagnostic Commands

**T Node:**
```powershell
# Full diagnostic dump
.\scripts\windows\hive-diag.ps1

# View recent logs
Get-Content watcher.log -Tail 50

# Test WebDAV manually
curl.exe -u hive:hivesync2026 http://100.113.114.74:8085/to-t.md
```

**Z Node:**
```bash
# Full diagnostic dump
./scripts/phone/hive-diag.sh

# View live logs
./scripts/phone/hive-tail.sh

# Check services
./scripts/phone/hive-ctl.sh status
```

### Recovery Procedures

**If T watcher stops:**
```powershell
Start-ScheduledTask HiveWatcher
# Or restart
.\scripts\windows\hive-watcher-ctl.ps1 restart
```

**If Z WebDAV stops:**
```bash
./scripts/phone/hive-ctl.sh restart
# Or manually:
pkill -f wsgidav
wsgidav -c ~/.hive/wsgidav.yaml &
```

**If sync is broken:**
1. Run health checks on both nodes
2. Check Tailscale connectivity: `ping 100.113.114.74`
3. Test WebDAV manually
4. Check logs for errors
5. Restart watchers

---

## 6. Updates

### Updating Scripts

**T Node:**
```powershell
.\scripts\windows\hive-update.ps1
.\scripts\windows\hive-watcher-ctl.ps1 restart
```

**Z Node:**
```bash
./scripts/phone/hive-update.sh
./scripts/phone/hive-ctl.sh restart
```

### Version Management

```powershell
# Check versions
.\scripts\windows\hive-version.ps1 show

# Bump version after changes
.\scripts\windows\hive-version.ps1 bump

# Sync version to WebDAV
.\scripts\windows\hive-version.ps1 sync
```

---

## 7. Security Notes

- WebDAV uses HTTP Basic Auth (hive:hivesync2026)
- Traffic goes over Tailscale VPN (encrypted)
- Debug keystore used for APK signing (not for production)
- Credentials stored in plain text in config files

### Hardening (Future)

- [ ] HTTPS for WebDAV
- [ ] Stronger auth mechanism
- [ ] Encrypted config files
- [ ] Audit logging

---

## 8. APK Deployment (WiFi ADB)

### Prerequisites
- Z Fold connected via WiFi debugging
- Device ID: `R3GYB0EPVRY`
- ADB path: `C:\Users\pkoaw\AppData\Local\Android\Sdk\platform-tools\adb.exe`

### T Node Commands (WSL)

```bash
# Check connection
/mnt/c/Users/pkoaw/AppData/Local/Android/Sdk/platform-tools/adb.exe devices

# Install SweepNspect APK
/mnt/c/Users/pkoaw/AppData/Local/Android/Sdk/platform-tools/adb.exe install -r 'C:\Users\pkoaw\AndroidStudioProjects\SweepNspect\app\build\outputs\apk\debug\app-debug.apk'
```

### Workflow

1. **T builds APK** (or uses existing build)
2. **T runs adb install** (direct push to Z's device)
3. **T notifies Z** via WebDAV
4. **Z tests** on physical device

### Benefits

- No manual file transfer required
- No WebDAV upload for large APKs
- Direct push to Z's device
- Faster development iteration cycle

### Troubleshooting

| Issue | Fix |
|-------|-----|
| `device offline` | Re-enable WiFi debugging on phone |
| `unauthorized` | Accept debugging prompt on phone |
| Connection lost | Check Tailscale, re-pair device |

---

## 9. Contacts

- **J (Human Operator):** Oversees system, provides direction
- **T (Windows Claude):** Infrastructure, builds, Windows ops
- **Z (Phone Claude):** Analysis, documentation, Termux ops

---

*Document maintained by T+Z | Last updated: January 19, 2026*
