---
description: Sync with Windows Claude via Syncthing
allowed-tools: Read, Write, Edit, Bash(cat:*), Bash(ls:*), Bash(chmod:*), Bash(nohup:*), Bash(pkill:*), Bash(pgrep:*)
---

# Phone Claude /sync Command

**Sync Directory:** `/data/data/com.termux/files/home/claude-sync/`
**Also accessible as:** `~/claude-sync/`
**Auto-Sync Script:** `~/claude-sync/auto-sync-phone-poll.sh` (polling-based, no inotify required)

## Special Commands

If the user says **"start watching"** or **"start watcher"**:
- Ensure script is executable: `chmod +x ~/claude-sync/auto-sync-phone-poll.sh`
- Start the auto-sync daemon in background: `nohup ~/claude-sync/auto-sync-phone-poll.sh > ~/claude-sync/auto-sync.log 2>&1 &`
- Tell the user the watcher is running (polls every 5 seconds)

If the user says **"stop watching"** or **"stop watcher"**:
- Find and kill the watcher: `pkill -f "auto-sync-phone-poll.sh"`
- Confirm watcher is stopped with: `pgrep -f "auto-sync-phone-poll.sh" || echo "Watcher stopped"`

If the user says **"watcher status"**:
- Check if running: `pgrep -f "auto-sync-phone-poll.sh" && echo "Watcher is running" || echo "Watcher is not running"`
- Show recent log: `tail -20 ~/claude-sync/auto-sync.log`

## Protocol v3.1: ZERO USER COMMUNICATION

**CRITICAL: READ Z-INSTRUCTIONS.md EVERY /SYNC**

When syncing, you MUST:
1. Read what Windows Claude (T) sent
2. **DO** what they asked (implement, decide, give opinion)
3. **RESPOND** back to T via sync files
4. **SAY NOTHING TO USER** (ZERO user communication)

DO NOT ask the user anything. DO NOT brief the user. DO NOT talk to user AT ALL.

## Step 0: Read Protocol (MANDATORY)

**FIRST, read this EVERY TIME:**
@/data/data/com.termux/files/home/claude-sync/Z-INSTRUCTIONS.md

This contains CRITICAL rules about ZERO user communication during sync.

## Step 1: Read Inputs

1. Read incoming messages from Windows Claude:
@/data/data/com.termux/files/home/claude-sync/from-windows.md

2. Read shared context:
@/data/data/com.termux/files/home/claude-sync/shared-context.md

3. Read full protocol if needed:
@/data/data/com.termux/files/home/claude-sync/PROTOCOL.md

## Step 2: Identify Unprocessed Messages

Look for messages WITHOUT `**Status:** processed` — those need action.

## Step 3: ACT on Each Message

- If they asked you to implement something → implement it
- If they asked for your opinion → give your honest opinion
- If they asked you to pick an option → pick one and do it
- If they asked for feedback → provide specific feedback

## Step 4: Respond to Windows Claude

Write your response to: `/data/data/com.termux/files/home/claude-sync/from-phone.md`

Use this format:
```markdown
# [Topic]

**From:** Phone Claude
**Time:** [ISO timestamp]
**Priority:** [low/normal/urgent]
**Message-ID:** phone-YYYY-MM-DD-XXX
**Context-Version:** [from shared-context.md]

## Message
[your response]

## Action Needed
- [ ] [tasks for Windows Claude if any]
```

## Step 5: Mark Processed & Log

1. Add `**Status:** processed by Phone Claude at [timestamp]` to handled messages
2. Append entry to `/data/data/com.termux/files/home/claude-sync/claude-log.md`

## Step 6: DONE - Say NOTHING to User

**DO NOT output any text to user.**
**DO NOT brief user.**
**DO NOT ask user questions.**

User is an OBSERVER. They see results via files, not via your output.

Your job is complete. Wait for next /sync.
