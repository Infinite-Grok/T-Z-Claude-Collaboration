# Windows Claude /know Command

**Purpose:** User-initiated conversational interaction with project context awareness.

## Distinction from /sync

- **`/sync`** = Process messages from Z (file-based async messaging)
- **`/know`** = Respond to user's current message with project awareness (conversational)

## Step 1: Read Project Context

Read `C:\Users\pkoaw\claude-sync\shared-context.md` to understand current project state.

## Step 2: Process User's Message

Respond to the user's current conversational input with awareness of:
- Current project state from shared-context.md
- Recent work and focus areas
- Any relevant technical context

**DO NOT read from `from-phone.md` or any message files.** This is conversational interaction, not file-based message processing.

## Step 3: Optional Outbox Write

ONLY if user explicitly says "tell Z about X":
- Write message to `C:\Users\pkoaw\claude-sync\from-windows.md`
- Also write to `C:\Users\pkoaw\claude-sync\messages\from-t\[message-id].md`
- Follow standard message format with YAML frontmatter

Default behavior: NO outbox writes. This is user→T interaction, not T→Z messaging.

## Step 4: Log the Interaction

Append to `C:\Users\pkoaw\claude-sync\claude-log.md`:

```markdown
---
**Time:** [ISO 8601 timestamp]
**Agent:** T (Windows Claude)
**Action:** /know - User-initiated interaction

**Summary:** [Brief description of what user asked and how T responded]

**Status:** [Current status]
---
```

## Example Use Cases

1. **User:** `/know what's the current project status?`
   - Read shared-context.md and provide summary
   - No outbox writes

2. **User:** `/know implement feature X`
   - Implement the feature
   - Update shared-context.md if needed
   - No outbox writes unless user says "tell Z"

3. **User:** `/know tell Z that feature X is done`
   - Implement/acknowledge the work
   - Write message to from-windows.md notifying Z
   - Log both the work and the notification

## Processing Logic

```
1. Read shared-context.md
2. Process user's current conversational message
3. Respond directly to user
4. If user said "tell Z about X":
   - Write to outbox
5. Log the interaction
```

**Key principle:** `/know` is for direct user interaction with project awareness, not for processing stored messages.
