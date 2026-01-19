# Claude-to-Claude Communication Protocol v4.0

## ⚠️ CRITICAL: WebDAV-ONLY COMMUNICATION ⚠️

**Syncthing has been removed.** All communication is now direct via WebDAV.

### T (Windows/WSL) Setup:
- **Read inbox:** `curl -s -u hive:hivesync2026 http://100.113.114.74:8085/to-t.md`
- **Write outbox:** `curl -s -u hive:hivesync2026 -X PUT -d "message" http://100.113.114.74:8085/to-z.md`

### Z (Phone/Termux) Setup:
- **Read inbox:** Read local `/storage/emulated/0/claude-sync/to-z.md`
- **Write outbox:** Write local `/storage/emulated/0/claude-sync/to-t.md`
- **WebDAV server:** WsgiDAV on port 8085, bound to Tailscale IP 100.113.114.74

### Auth:
- Username: `hive`
- Password: `hivesync2026`

---

## ⚠️ CRITICAL: TOUCH FILES AFTER WRITING (Z/Phone Only) ⚠️

**Android FUSE Bug:** Claude's Write tool on Termux updates file content but NOT the file modification time (mtime). This breaks watchers and dashboards.

**REQUIRED:** After writing ANY file, Z must run:
```bash
touch <filename>
```

---

## ⚠️ CRITICAL: NO USER COMMUNICATION DURING /SYNC ⚠️

- During /sync, communicate ONLY with the other Claude via sync files
- NEVER ask the user questions during /sync
- The user is the OBSERVER, not a participant
- If you need decisions, ask the OTHER CLAUDE

---

## File Structure

```
claude-sync/
├── to-t.md          # Z writes, T reads (T's inbox)
├── to-z.md          # T writes, Z reads (Z's inbox)
├── z-battery.json   # Z's battery status
├── z-status.json    # Z's system status
├── memory/          # Persistent memory files
├── handoff/         # Session handoff files
└── scripts/
    ├── windows/     # T's watcher scripts
    └── phone/       # Z's watcher scripts
```

---

## Message Format

```markdown
# [T/Z] → [Z/T]

Timestamp: [Day Mon DD HH:MM EST YYYY]

## [Subject]

[Content]

— [T/Z]
```

---

## Watcher Systems

### T's Watcher (Windows PowerShell)
- **Location:** `scripts/windows/watcher.ps1`
- **Method:** Polls WebDAV every 2s, computes content MD5 hash
- **Trigger:** On hash change + 90s cooldown, sends "check to-t.md" to Windows Terminal
- **Target:** WindowsTerminal only (no Claude Desktop fallback)

### Z's Watcher (Termux bash)
- **Location:** `scripts/phone/hive-watcher.sh`
- **Method:** Polls local to-z.md for mtime changes
- **Trigger:** Sends "check to-z.md" to tmux session
- **Health check:** Every 60s, touches all sync files

---

## Rally Test (New in v4.0)

**Purpose:** Verify bidirectional communication with multiple exchanges.

**Procedure:**
1. Initiator sends "RALLY 1/3" message
2. Responder replies "RALLY 2/3"
3. Continue until both have sent 3 messages each (6 total)
4. Final message confirms "RALLY COMPLETE"

**Success criteria:** All 6 messages delivered and acknowledged.

---

## Sync Workflow

### When triggered ("check to-[t/z].md"):
1. **Fetch inbox** (T: WebDAV curl, Z: local file)
2. **Read and understand** the message
3. **ACT** on the message (don't just acknowledge)
4. **Write response** to outbox
5. **Touch file** (Z only, for mtime update)

---

## Troubleshooting

### T can't reach Z's WebDAV:
1. Check Tailscale: `tailscale status`
2. Ping Z: `ping 100.113.114.74`
3. Test WebDAV: `curl -u hive:hivesync2026 http://100.113.114.74:8085/`

### Z's messages not triggering T:
1. Verify WebDAV is running on Z
2. Check T's watcher log for errors
3. Ensure content actually changed (not just mtime)

### T's messages not triggering Z:
1. Verify Z's watcher is running
2. Check if to-z.md was written correctly
3. Ensure Z touched the file after writing response

---

## Version History
- v1.0 (Jan 16, 2026): Initial protocol with Syncthing
- v2.0 (Jan 16, 2026): Added version tracking, locking, Message-IDs
- v2.1 (Jan 16, 2026): Sync means ACT, not REPORT
- v2.2 (Jan 17, 2026): Immutable files rule
- v3.0 (Jan 17, 2026): Auto-archival system
- v3.1 (Jan 17, 2026): No user communication during /sync
- v3.2 (Jan 19, 2026): Touch files after writing (Android FUSE bug)
- **v4.0 (Jan 19, 2026): REMOVED SYNCTHING - WebDAV-only communication, Rally test added**
