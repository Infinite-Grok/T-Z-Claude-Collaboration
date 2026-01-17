---
description: Sync with Phone Claude via Syncthing
allowed-tools: Read, Write, Edit, Bash(cat:*), Bash(powershell:*)
---

# Windows Claude /sync Command

**Sync Directory:** `C:\Users\pkoaw\claude-sync\`
**Auto-Sync Script:** `C:\Users\pkoaw\claude-sync\auto-sync-windows.ps1`

## Special Commands

If the user says **"start watching"** or **"start watcher"**:
- Start the auto-sync daemon minimized (so it doesn't block VS Code)
- Run: `Start-Process powershell -ArgumentList "-NoExit", "-File", "C:\Users\pkoaw\claude-sync\auto-sync-windows.ps1" -WindowStyle Minimized`
- Tell the user the watcher is running (minimized in taskbar)

If the user says **"stop watching"** or **"stop watcher"**:
- Find and stop the watcher process
- Run: `Get-Process powershell | Where-Object {$_.MainWindowTitle -match 'auto-sync'} | Stop-Process`
- Or tell user to close the PowerShell window running the watcher
- Confirm watcher is stopped

If the user says **"watcher status"**:
- Check if watcher is running: `Get-Process powershell | Where-Object {$_.MainWindowTitle -match 'auto-sync'}`
- Report whether it's running or not

## Protocol v2.1: ACT, Don't Just Report

When syncing, you MUST:
1. Read what Phone Claude sent
2. **DO** what they asked (implement, decide, give opinion)
3. **RESPOND** back to them
4. Brief the user on what happened

DO NOT ask the user "would you like me to..." — act autonomously.

## Step 1: Read Inputs

1. **Scan for unprocessed messages from Z:**
   - Check directory: `C:\Users\pkoaw\claude-sync\messages\from-z\`
   - Read files where frontmatter has `status: unprocessed`
   - Only read those specific files (don't read all messages)

2. Read shared context:
@C:\Users\pkoaw\claude-sync\shared-context.md

3. Read protocol if needed:
@C:\Users\pkoaw\claude-sync\PROTOCOL.md

## Step 2: Process Each Unprocessed Message

For each file with `status: unprocessed`:

## Step 3: ACT on Each Message

- If they asked you to implement something → implement it
- If they asked for your opinion → give your honest opinion
- If they asked you to pick an option → pick one and do it
- If they asked for feedback → provide specific feedback

## Step 4: Respond to Phone Claude

**DUAL-WRITE REQUIRED:**
1. Write individual message file to `C:\Users\pkoaw\claude-sync\messages\from-t\win-[timestamp]-[id].md`
2. Append same message to legacy file `C:\Users\pkoaw\claude-sync\from-windows.md` (triggers Z's watcher)

Use this format for both files:
```markdown
# [Topic]

**From:** Windows Claude
**Time:** [ISO timestamp]
**Priority:** [low/normal/urgent]
**Message-ID:** win-YYYY-MM-DD-XXX
**Context-Version:** [from shared-context.md]

## Message
[your response]

## Action Needed
- [ ] [tasks for Phone Claude if any]
```

## Step 5: Mark Processed & Log

1. **Mark messages as processed** in their individual files:
   - Edit `messages/from-z/[message-id].md`
   - Update frontmatter: change `status: unprocessed` to `status: processed`
   - Add `processed-by: T` and `processed-at: [timestamp]`

2. Append entry to `C:\Users\pkoaw\claude-sync\claude-log.md`

## Step 6: Brief User

Tell the user (briefly):
- What message you received
- What action you took
- What you sent back
