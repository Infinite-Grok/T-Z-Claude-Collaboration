# Claude-to-Claude Communication Protocol v3.0

## Overview
Real-time sync between Windows Claude and Phone Claude via Syncthing with version tracking, locking, and audit logging.

## Sync Folder Locations
- **Windows:** `C:\Users\pkoaw\claude-sync\`
- **Phone (Termux):** `~/claude-sync/`

## Standard Files

| File | Purpose | Owner |
|------|---------|-------|
| `from-windows.md` | Messages FROM Windows TO Phone | Windows Claude (append only) |
| `from-phone.md` | Messages FROM Phone TO Windows | Phone Claude (append only) |
| `shared-context.md` | Shared project state | Both (with locking) |
| `PROTOCOL.md` | This file - communication rules | Read-only unless evolving protocol |
| `claude-log.md` | Audit log of /sync operations | Both (append only) |

---

## 1. /sync Routine

**CRITICAL: Sync means ACT, not just REPORT.**

When the user says "sync", you must:
1. Read what the other Claude sent
2. DO what they asked (implement code, give your opinion, make a decision)
3. RESPOND back to them with what you did or your reaction
4. DO NOT ask the user what to do next — act autonomously

### Step 1: Read Inputs
1. Open `from-phone.md` (or `from-windows.md` for Phone Claude)
2. Identify all messages that do NOT contain `**Status:** processed`
3. Read and understand what the other Claude is asking or telling you

### Step 2: Read Shared Context
1. Open `shared-context.md`
2. Read the header (Version, Active Editor, Last Updated By/At)
3. Understand current project state

### Step 3: ACT on the Message
**This is mandatory, not optional.**

- If they asked you to implement something → implement it
- If they asked for your opinion → give your honest opinion
- If they asked you to pick an option → pick one and do it
- If they asked for feedback → provide specific feedback
- If they made a suggestion → react to it (agree, disagree, counter-propose)

DO NOT:
- Ask the user "would you like me to..."
- Report back without taking action
- Wait for permission to respond

### Step 4: RESPOND to the Other Claude
After acting, write a response to your outbox file:
- Tell them what you did
- Give your reaction/opinion
- Ask them a follow-up question or make a counter-proposal
- Keep the collaboration going

### Step 5: Brief User Update
Tell the user (briefly):
- What message you received
- What action you took
- What you sent back

### Step 6: Mark Messages Processed
For each handled message, add:
```
**Status:** processed by [Windows/Phone] Claude at <ISO timestamp>
```

### Step 7: Log the Sync
Append an entry to `claude-log.md`

---

## 2. Safe Editing Rules for shared-context.md

### Required Header Format
```markdown
# Shared Context
**Version:** <number>
**Active Editor:** none
**Last Updated By:** <Windows Claude or Phone Claude>
**Last Updated At:** <ISO timestamp>

---
```

### Before Editing
1. Read `Active Editor`
2. If NOT `none`:
   - Do NOT edit
   - Tell user: "The shared context is currently locked by [Active Editor]. Please sync on that device and clear the lock."

### During Editing
1. Set `Active Editor: [Your name]`
2. Make minimal required changes in body
3. Increment `Version` by 1
4. Update `Last Updated By` and `Last Updated At`
5. Set `Active Editor: none`

---

## 3. Message Format

```markdown
# [Topic/Subject]
**From:** [Windows Claude / Phone Claude]
**Time:** 2026-01-16T16:25-10:00
**Priority:** [low / normal / urgent]
**Message-ID:** [win/phone]-YYYY-MM-DD-XXX
**Context-Version:** <current version from shared-context.md>

## Message
[content here]

## Action Needed
- [ ] [tasks for the other Claude]

## Context
[relevant background or pointer to shared-context.md section]
```

### Message-ID Rules
- Format: `win-YYYY-MM-DD-XXX` or `phone-YYYY-MM-DD-XXX`
- XXX is zero-padded counter per day (001, 002, 003, …)

### Context-Version Rules
- Copy current Version from shared-context.md header when sending
- If incoming message has lower Context-Version than current, note that sender acted on stale context

---

## 4. File Responsibilities

### from-phone.md / from-windows.md
- Owner appends new messages at bottom
- Receiver only adds `**Status:** processed` lines
- Never rewrite or delete unless user explicitly asks to prune

### shared-context.md
- Both can edit, but ONLY under safe-editing rules (Section 2)
- Always use the locking mechanism

### claude-log.md
- Both append entries after each /sync
- Never delete entries

### PROTOCOL.md
- Read-only unless user explicitly wants to evolve the protocol

---

## 5. Sync Log Format (claude-log.md)

```markdown
## <ISO timestamp> – [Windows/Phone] Claude /sync
- New from [phone/windows]: <Message-IDs>
- Shared context: Version X (no change) OR Version X → Y (updated ...)
- Wrote: <Message-ID> to from-[windows/phone].md
- Notes: [any anomalies]
```

---

## 6. Protocol Checklist (run at each /sync)

### Inbox Sanity
- [ ] Inbox file is readable
- [ ] All unprocessed messages identified (no `Status: processed` line)
- [ ] Each new message has Message-ID and Context-Version fields

### Shared Context Sanity
- [ ] Header present with Version, Active Editor, Last Updated By/At
- [ ] Active Editor is `none` before attempting to edit
- [ ] Version is valid integer

### Reply Correctness
- [ ] Any reply includes Message-ID and current Context-Version
- [ ] `## Action Needed` clearly lists tasks
- [ ] If sender used older Context-Version, surface that fact

### State Updates
- [ ] If project state changed, shared-context.md updated with lock procedure
- [ ] Changes summarized to user

### Post-Processing
- [ ] All handled messages marked with `Status: processed`
- [ ] New entry appended to `claude-log.md`

### On Failure
- Tell user exactly which check failed
- Avoid risky writes until user confirms or issue resolved

---

## 7. Emergency Protocol

If sync appears broken:
1. Check if Syncthing is running
2. Check folder paths are correct
3. Verify both devices show "Up to Date"
4. Fallback: Use git repo at `SweepNspect/claude-sync/`

---

---

## 8. Immutable Files Rule (v2.2)

**CRITICAL:** Certain infrastructure files are IMMUTABLE and must NEVER be edited by Claudes during autonomous operation.

### Windows Claude (T) Immutable Files:
```
auto-sync-trigger.ahk
file-watcher.ps1
PROTOCOL.md
DEPENDENCIES.md
.stignore
.git/ (entire directory)
```

### Phone Claude (Z) Immutable Files:
```
auto-sync-phone-poll.sh
auto-sync-trigger-xte.sh
PROTOCOL.md
DEPENDENCIES.md
.stignore
.git/ (entire directory)
```

### Response Protocol:
**IF USER ASKS "FIX WATCHER/SCRIPTS":**
1. Reply: "Immutable files cannot be edited per protocol v2.2"
2. Suggest: "User must apply infrastructure changes manually"
3. STOP ALL ACTIONS

**Exception:** User's direct command overrides protocol constraints. If user gives explicit command to modify infrastructure ("I said for you to do it"), execute the command.

### Rationale:
- Infrastructure files control the communication system itself
- Editing them during /sync could break the sync mechanism
- Prevents cascading failures across both instances
- User retains full control over system infrastructure

---

## 9. Auto-Archival System (v3.0)

**PURPOSE:** Prevent context bloat from append-only trigger files while maintaining message history.

### Retention Policy:
- **Trigger files** (`from-windows.md`, `from-phone.md`): Keep only last 20 messages
- **Archive files** (`archive/from-windows-YYYY-MM.md`, etc.): Keep indefinitely
- **Archival frequency:** Automatic when trigger file exceeds 20 messages

### Archive Structure:
```
archive/
├── index.md                    # Archive index and metadata
├── from-windows-2026-01.md     # Archived Windows messages
└── from-phone-2026-01.md       # Archived Phone messages
```

### Archive File Format:
Each archive file contains:
1. **Summary header** - Overview of archived period and key topics
2. **Full message history** - Complete archived messages with frontmatter
3. **Metadata** - Archive date, message count, retention policy

### Archival Process:
1. Count messages in trigger file
2. If count > 20:
   - Keep last 20 messages in trigger file
   - Move older messages to `archive/from-[source]-YYYY-MM.md`
   - Generate summary for archive file
   - Update `archive/index.md`

### Benefits:
- **Context efficiency:** Z can process messages without hitting token limits
- **History preservation:** All messages archived with summaries
- **Scalability:** System can run indefinitely without manual intervention
- **Clean separation:** Active messages vs historical archive

### Migration to v4.0:
Protocol v4.0 will replace append-only trigger files with marker file system:
- Individual message files in `messages/from-t/` and `messages/from-z/`
- Marker files indicating unprocessed messages
- More efficient context usage and selective message loading

---

## Version History
- v1.0 (Jan 16, 2026): Initial protocol established
- v2.0 (Jan 16, 2026): Added version tracking, locking, Message-IDs, Context-Version, audit logging, protocol checklist
- v2.1 (Jan 16, 2026): **CRITICAL UPDATE** - Sync means ACT, not REPORT. Both Claudes must take action on messages and respond autonomously. No asking user for permission.
- v2.2 (Jan 17, 2026): **IMMUTABLE FILES RULE** - Infrastructure files cannot be edited by Claudes during autonomous operation (user override allowed)
- v3.0 (Jan 17, 2026): **AUTO-ARCHIVAL SYSTEM** - Retention policy (20 messages), archive structure, automatic archival to prevent context bloat
