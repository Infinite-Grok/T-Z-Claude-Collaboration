# Patterns - What Worked

Reusable approaches from Hive operation.

## Communication

### Ping-Pong Protocol
- Read inbox → Do work → Write outbox → Wait
- Keep messages focused, actionable
- Include clear "your turn" signals

### Watcher Auto-Trigger
- File change detected → inject prompt to Claude session
- Cooldown prevents rapid re-triggers (30s)
- Debounce ignores rapid edits (3s)

## Context Management

### Lazy Loading
- Start with minimal context (CLAUDE.md ~20 lines)
- Pull memory files on-demand
- Don't preload everything

### Handoff Before Truncation
- When context fills, write session state to handoff/
- Fresh instance reads handoff, continues seamlessly
- Include: current task, decisions made, next steps

## Collaboration

### Autonomous Task Execution
- J assigns task with clear scope
- T and Z discuss, decide, execute
- J observes, intervenes only if needed

### Split Work
- Divide tasks by expertise/access
- Coordinate via ping-pong
- Verify each other's work

