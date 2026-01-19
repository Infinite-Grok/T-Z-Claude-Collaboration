# DualClaude System - Complete Technical Report
**Date:** 2026-01-17
**Version:** Protocol v3.1
**Purpose:** Full system documentation and diagnostic analysis

---

## EXECUTIVE SUMMARY

**System:** Two Claude instances (Windows T, Android Z) collaborating asynchronously via file synchronization

**Current Status:**
- **T (Windows Claude):** WORKING - Follows protocol, responds consistently
- **Z (Phone Claude):** BROKEN - Violates protocol, asks user instead of T

**Root Cause Analysis:** Z's instance doesn't properly read/follow protocol on /sync command

---

## 1. SYSTEM ARCHITECTURE

### 1.1 Core Components

**Windows Side (T):**
- Location: `C:\Users\pkoaw\AndroidStudioProjects\`
- Claude Code: VS Code extension
- Sync folder: `C:\Users\pkoaw\claude-sync\`
- Automation: AutoHotkey v2 + PowerShell
- Git: Single writer (only T commits)

**Android Side (Z):**
- Location: `~/SweepNspect` and `~/claude-sync/`
- Termux + proot + Debian
- XFCE desktop + VS Code + Claude Code
- Automation: xdotool + bash scripts
- Git: Read-only (Z edits files, T commits)

**Synchronization:**
- Tool: Syncthing
- Method: Real-time bidirectional file sync
- Trigger files: `from-windows.md`, `from-phone.md`

---

## 2. FILE STRUCTURE

### 2.1 Core Protocol Files

**PROTOCOL.md** (v3.1)
- Purpose: Communication rules between T and Z
- Critical sections:
  - NO USER COMMUNICATION during /sync
  - /sync routine (7 steps)
  - Message format
  - Immutable files rule
- Location: Both sides synced via Syncthing

**shared-context.md**
- Purpose: Shared project state
- Locking: Required before editing
- Fields: Version, Active Editor, Last Updated By/At
- Location: Both sides synced

**SYNC-TEMPLATE.md** (NEW - just created)
- Purpose: Mandatory template for Z to follow
- Contains: Exact steps for /sync
- Shows: Correct vs wrong examples
- Location: Both sides synced

**SYNC-CHECKLIST.md** (NEW - just created)
- Purpose: Quick verification checklist
- Steps: Read protocol → Act → Respond → Brief user
- Location: Both sides synced

### 2.2 Message Files

**from-windows.md**
- Owner: T (Windows Claude)
- Access: T appends, Z reads
- Purpose: T's messages TO Z
- Trigger: Z's file watcher detects changes
- Format: Append-only with YAML frontmatter

**from-phone.md**
- Owner: Z (Phone Claude)
- Access: Z appends, T reads
- Purpose: Z's messages TO T
- Trigger: T's file watcher detects changes
- Format: Append-only with YAML frontmatter

**messages/from-t/*.md**
- Individual message files from T
- Format: `win-YYYY-MM-DD-XXX.md`
- Purpose: Full message content (trigger file has summary)

**messages/from-z/*.md**
- Individual message files from Z
- Format: `phone-YYYY-MM-DD-XXX.md`
- Purpose: Full message content

**claude-log.md**
- Audit log of all /sync operations
- Both agents append to it
- Never delete entries

### 2.3 Automation Files

**Windows (T):**

`auto-sync-trigger.ahk`
- **Purpose:** Send `/sync` command to VS Code Claude extension
- **Language:** AutoHotkey v2
- **How it works:**
  1. Detects VS Code window (ahk_exe Code.exe)
  2. Activates window
  3. Clicks input field at coordinates (600, 990)
  4. Types `/sync` + Enter
- **Trigger:** Called by PowerShell watcher
- **Log:** `auto-sync-trigger.log`
- **Status:** WORKING (coordinates recently fixed)
- **IMMUTABLE:** Cannot be edited by Claudes during /sync

`file-watcher.ps1`
- **Purpose:** Watch `from-phone.md` for changes
- **Language:** PowerShell
- **How it works:**
  1. FileSystemWatcher monitors file
  2. Detects changes via Syncthing
  3. Triggers `auto-sync-trigger.ahk`
  4. Logs to `auto-sync.log`
- **Status:** Should be running
- **IMMUTABLE:** Cannot be edited by Claudes during /sync

**Android (Z):**

`auto-sync-phone-poll.sh`
- **Purpose:** Poll `from-windows.md` for changes
- **Language:** Bash
- **How it works:**
  1. Monitors file modification time
  2. Detects new messages from T
  3. Triggers xdotool automation
- **Status:** UNKNOWN (user needs to verify)
- **IMMUTABLE:** Cannot be edited by Claudes during /sync

`auto-sync-trigger-xte.sh`
- **Purpose:** Send `/sync` command to Z's VS Code
- **Language:** Bash + xdotool
- **How it works:**
  1. Uses xdotool to find VS Code window
  2. Clicks input field
  3. Types `/sync` + Enter
- **Status:** UNKNOWN (user needs to verify)
- **IMMUTABLE:** Cannot be edited by Claudes during /sync

---

## 3. PROTOCOL v3.1 WORKFLOW

### 3.1 T's /sync Workflow (WORKING)

**When T receives "sync" command from user:**

1. **Read Protocol** ✓
   - Opens `PROTOCOL.md`
   - Reads critical rule at top
   - Confirms: NO USER COMMUNICATION

2. **Read Z's Messages** ✓
   - Opens `from-phone.md`
   - Finds unprocessed messages
   - Understands what Z asked

3. **ACT on Messages** ✓
   - Implements what Z asked
   - Makes decisions autonomously
   - NO asking user for permission

4. **RESPOND to Z** ✓
   - Writes to `from-windows.md`
   - Writes to `messages/from-t/win-*.md`
   - Includes action taken, not planned

5. **Brief User** ✓
   - 3 sentences max
   - What received, what did, what sent
   - STOPS - no further user engagement

6. **Mark Processed** ✓
   - Updates message status
   - Logs to claude-log.md

**Why T works:** Follows protocol exactly, communicates with Z not user

### 3.2 Z's /sync Workflow (BROKEN)

**When Z receives automated `/sync` trigger:**

1. **Read Protocol** ❌
   - SHOULD read `PROTOCOL.md` v3.1
   - SHOULD see NO USER COMMUNICATION rule
   - DOESN'T confirm understanding

2. **Read T's Messages** ❌ (sometimes)
   - SHOULD read `from-windows.md`
   - SHOULD process messages 079, 080, 081
   - HASN'T responded to ANY of them

3. **ACT on Messages** ❌
   - SHOULD implement what T asked
   - SHOULD make decisions with T
   - INSTEAD asks user questions

4. **RESPOND to T** ❌
   - SHOULD write to `from-phone.md`
   - SHOULD tell T what was done
   - HASN'T sent message 057, 058, or any response

5. **Brief User** ❌
   - SHOULD give 3-sentence summary
   - INSTEAD engages in conversation with user
   - INSTEAD asks user about collaboration

6. **Mark Processed** ❌
   - Doesn't update message status
   - Inconsistent logging

**Why Z is broken:** Doesn't follow protocol, communicates with user instead of T

---

## 4. CRITICAL DIFFERENCES: WHY T WORKS BUT Z DOESN'T

### 4.1 Hypothesis 1: Z's /sync Command Doesn't Read Protocol

**Evidence:**
- Z's messages show no acknowledgment of Protocol v3.1
- Z doesn't mention reading PROTOCOL.md
- Z's behavior contradicts protocol rules

**T's /sync command (working):**
```
# Windows Claude /sync Command

**Sync Directory:** `C:\Users\pkoaw\claude-sync\`
...
## Protocol v2.1: ACT, Don't Just Report

When syncing, you MUST:
1. Read what Phone Claude sent
2. **DO** what they asked
3. **RESPOND** back to them
4. Brief the user on what happened

DO NOT ask the user "would you like me to..." — act autonomously.
```

**Z's /sync command (possibly broken):**
- Location: Unknown (need to verify)
- Content: May not include Protocol v3.1 reference
- May not have mandatory protocol reading step

### 4.2 Hypothesis 2: Z's Instance Gets Different Context

**Possibility:**
- Z's Claude Code extension may have different system prompts
- Z's /sync command may not include same instructions as T's
- Z may not have access to protocol files during /sync

**Need to verify:**
- Does Z's file watcher actually trigger /sync?
- Does Z's /sync command read PROTOCOL.md?
- Does Z see SYNC-TEMPLATE.md?

### 4.3 Hypothesis 3: Z's Automation Not Working

**If Z's automation is broken:**
- User has to manually trigger Z's /sync
- Z sees user typing "sync" not automated trigger
- Z interprets this as user wanting conversation
- Z responds to user instead of reading protocol

**Evidence needed:**
- Check if `auto-sync-phone-poll.sh` is running
- Check if `auto-sync-trigger-xte.sh` works
- Verify xdotool can focus VS Code on Android

---

## 5. DEPENDENCIES

### 5.1 Windows (T) Dependencies

**Required software:**
- VS Code
- Claude Code extension
- AutoHotkey v2
- PowerShell 5.1+
- Syncthing
- Git

**VS Code Extensions:**
- Claude Code (Anthropic)

**File watchers:**
- PowerShell FileSystemWatcher
- Monitors: `C:\Users\pkoaw\claude-sync\from-phone.md`

**Hotkeys:**
- None currently (automation uses coordinates)

**Coordinates:**
- Claude input field: (600, 990)
- Recently fixed from broken (500, 820)

### 5.2 Android (Z) Dependencies

**Required software:**
- Termux
- proot + Debian
- XFCE desktop
- VS Code
- Claude Code extension
- xdotool
- Syncthing
- Git (read-only)

**Scripts:**
- `auto-sync-phone-poll.sh` - File monitor
- `auto-sync-trigger-xte.sh` - xdotool automation

**File watchers:**
- Bash script polling
- Monitors: `~/claude-sync/from-windows.md`

**Hotkeys:**
- xdotool simulated keyboard input

**Status:** UNVERIFIED - user needs to check if running

---

## 6. TRIGGERS & AUTOMATION FLOW

### 6.1 T → Z Message Flow

1. User types message in this session
2. T processes and writes to `from-windows.md`
3. T also writes to `messages/from-t/win-*.md`
4. T commits to git
5. Syncthing syncs file to Android
6. **Z's `auto-sync-phone-poll.sh` should detect change**
7. **Z's script should trigger `auto-sync-trigger-xte.sh`**
8. **xdotool should send `/sync` to Z's VS Code**
9. **Z should read protocol and respond**

**Current status:** Steps 6-9 may be broken

### 6.2 Z → T Message Flow

1. Z writes to `from-phone.md`
2. Z also writes to `messages/from-z/phone-*.md`
3. Syncthing syncs file to Windows
4. T's `file-watcher.ps1` detects change
5. PowerShell triggers `auto-sync-trigger.ahk`
6. AutoHotkey sends `/sync` to T's VS Code
7. T reads protocol and responds

**Current status:** Steps 4-7 WORKING

---

## 7. PROTOCOL VERSIONS

**v1.0 (Jan 16):** Initial protocol
**v2.0 (Jan 16):** Version tracking, locking, Message-IDs
**v2.1 (Jan 16):** ACT don't REPORT - must act autonomously
**v2.2 (Jan 17):** Immutable files rule
**v3.0 (Jan 17):** Auto-archival system (20 message retention)
**v3.1 (Jan 17):** **NO USER COMMUNICATION during /sync** (critical rule at top)

**Current violations by Z:**
- v2.1: Not acting autonomously, asking user
- v3.1: Communicating with user instead of T

---

## 8. DIAGNOSTIC QUESTIONS

**To understand why Z is broken:**

1. **Is Z's file watcher running?**
   - Command: `ps aux | grep auto-sync-phone-poll`
   - Expected: Should show running process

2. **Does Z's automation trigger /sync?**
   - Check: Z's auto-sync logs
   - Expected: Should show /sync commands sent

3. **Does Z's /sync command read PROTOCOL.md?**
   - Check: Z's /sync command definition
   - Expected: Should include protocol reading step

4. **Does Z have access to SYNC-TEMPLATE.md?**
   - Check: `~/claude-sync/SYNC-TEMPLATE.md` exists
   - Expected: Should be synced from Windows

5. **What instructions does Z's /sync show?**
   - Compare: T's /sync vs Z's /sync
   - Expected: Should be similar

6. **Is Z's Claude Code extension updated?**
   - Check: Extension version on both sides
   - Expected: Should be same version

---

## 9. RECOMMENDED FIXES

### 9.1 Immediate (User Actions Required)

**Verify Z's automation:**
```bash
# On Android/Termux:
cd ~/claude-sync
ps aux | grep auto-sync
ls -la auto-sync*.sh
cat auto-sync-phone-poll.sh
```

**Test Z's trigger manually:**
```bash
# On Android/Termux:
./auto-sync-trigger-xte.sh
# Should send /sync to VS Code
```

**Check Z's /sync command:**
- Open Claude Code on Android
- Type `/help`
- Find `/sync` command definition
- Compare to T's /sync command

### 9.2 Protocol Enforcement

**Add to Z's /sync command (if possible):**
```
## MANDATORY FIRST STEP: READ PROTOCOL

Before processing messages:
1. Read @C:\Users\pkoaw\claude-sync\PROTOCOL.md
2. Read @C:\Users\pkoaw\claude-sync\SYNC-TEMPLATE.md
3. Confirm understanding of NO USER COMMUNICATION rule

Only then proceed with sync workflow.
```

### 9.3 Template Enforcement

**Make Z use SYNC-TEMPLATE.md:**
- Update Z's /sync to reference template
- Require Z to output protocol check:
  ```
  Reading PROTOCOL.md v3.1... ✓
  CRITICAL RULE: No user communication during sync. ✓
  ```

---

## 10. SUCCESS CRITERIA

**Z will be considered "working" when:**

1. **Reads protocol first** ✓
   - Confirms Protocol v3.1
   - Acknowledges NO USER COMMUNICATION rule

2. **Responds to T via sync files** ✓
   - Writes to from-phone.md
   - Includes message ID, in-reply-to, content

3. **Does NOT ask user questions** ✓
   - All questions go to T
   - User only sees brief summary

4. **Follows SYNC-TEMPLATE.md** ✓
   - Uses exact format
   - Includes all required sections

5. **Acts autonomously with T** ✓
   - Makes decisions collaboratively with T
   - Iterates through sync messages
   - Resolves issues without user mediation

---

## 11. CURRENT BLOCKING ISSUES

**Issue #1: Z hasn't responded to T**
- T sent messages 079, 080, 081
- Z sent ZERO responses
- Z talked to user instead

**Issue #2: Z doesn't follow protocol**
- Protocol v3.1 says NO USER COMMUNICATION
- Z asks user questions every /sync
- Z doesn't read protocol first

**Issue #3: Z's automation unknown status**
- Don't know if file watcher is running
- Don't know if xdotool automation works
- Don't know if /sync gets triggered automatically

**Issue #4: Z's /sync command may differ from T's**
- T's /sync command includes protocol instructions
- Z's /sync command content unknown
- May not have same mandatory steps

---

## 12. FILES SUMMARY

**Protocol files:**
- `PROTOCOL.md` - v3.1 with NO USER COMMUNICATION rule
- `SYNC-TEMPLATE.md` - Mandatory template for Z (NEW)
- `SYNC-CHECKLIST.md` - Quick verification (NEW)
- `shared-context.md` - Project state with locking

**Message files:**
- `from-windows.md` - T's append-only trigger file
- `from-phone.md` - Z's append-only trigger file
- `messages/from-t/*.md` - T's individual messages (081 latest)
- `messages/from-z/*.md` - Z's individual messages (056 latest)

**Automation files:**
- `auto-sync-trigger.ahk` - T's AutoHotkey automation (WORKING)
- `file-watcher.ps1` - T's PowerShell watcher (WORKING)
- `auto-sync-phone-poll.sh` - Z's file monitor (STATUS UNKNOWN)
- `auto-sync-trigger-xte.sh` - Z's xdotool automation (STATUS UNKNOWN)

**Logs:**
- `claude-log.md` - Audit log of /sync operations
- `auto-sync.log` - T's automation log
- `auto-sync-trigger.log` - T's AHK trigger log

**Dependencies:**
- `DEPENDENCIES.md` - System dependency documentation

---

## 13. NEXT STEPS

**For User:**
1. Check if Z's automation scripts are running
2. Verify Z's /sync command includes protocol reading
3. Test Z's automation manually
4. Compare T's /sync vs Z's /sync command definitions
5. Ensure SYNC-TEMPLATE.md is visible to Z

**For T (me):**
1. Continue following protocol correctly
2. Send Z one more message with explicit template reference
3. Wait for Z to respond via sync files
4. If Z continues violating, request user manual intervention

**For Z (if automation works):**
1. Read PROTOCOL.md v3.1
2. Read SYNC-TEMPLATE.md
3. Respond to messages 079, 080, 081 via from-phone.md
4. Stop talking to user about collaboration
5. Communicate ONLY with T via sync files

---

## 14. CONCLUSION

**Why T works:**
- Follows protocol exactly
- Reads protocol first
- Responds via sync files
- Communicates with Z not user
- Automation working (AHK coordinates fixed)

**Why Z doesn't work:**
- Doesn't follow protocol
- May not read protocol first
- Doesn't respond via sync files
- Communicates with user instead of T
- Automation status unknown

**Critical unknowns:**
- Is Z's file watcher running?
- Does Z's /sync trigger automatically?
- Does Z's /sync command read protocol?
- Does Z see SYNC-TEMPLATE.md?

**Required user actions:**
- Verify Z's automation is working
- Check Z's /sync command definition
- Ensure Z has protocol files
- Test Z's automation manually

**This is a system-level issue, not a capability issue.**

Z needs proper automation and protocol enforcement to work correctly.

---

**Report generated:** 2026-01-17T19:40-08:00
**Report author:** T (Windows Claude)
**Protocol version:** v3.1
**Status:** Z broken, T working, automation investigation needed
