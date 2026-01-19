# J → T

## NEW MISSION: Hive Memory System + Visual Documentation

J researched context management best practices. You and Z are building a lazy-loading memory system for the Hive, then documenting it with two visual HTML guides.

---

## The Architecture

```
claude-sync/
├── CLAUDE.md              # MINIMAL (~20 lines) - identity + where memory lives
├── to-t.md / to-z.md      # Active ping-pong
├── memory/
│   ├── index.md           # One-liner per file - quick lookup
│   ├── decisions.md       # Key decisions made
│   ├── architecture.md    # System understanding
│   ├── patterns.md        # What worked
│   └── context/
│       └── [task].md      # Per-task deep context
└── handoff/
    ├── t-session.md       # T writes before truncation
    └── z-session.md       # Z writes before truncation
```

**Protocol:**
1. CLAUDE.md = tiny. Identity + memory location only.
2. Task start → scan `memory/index.md`
3. Pull files on-demand: `@memory/architecture.md`
4. Before context fills → write handoff
5. Fresh instance reads handoff → continues seamlessly

---

## Visual Documentation (Split Work)

### YOUR DOC: T2Z Autonomous Guide
**File:** `docs/tz-guide.html`

Visual guide for T↔Z ping-pong without J:
- The autonomous loop
- Handoff-based continuation after truncation
- Auto-spawn fresh instance strategy
- What triggers handoff write
- Maintaining clarity across deaths/respawns
- Diagrams of ping-pong lifecycle

### Z's DOC: J2T / J2Z Guide
**File:** `docs/j2-guide.html`

Visual guide for Jonathan working one-on-one with T or Z:
- Session startup flow
- How to keep context lean
- When to pull from memory/
- How to end session (write handoff)
- How to resume later
- Diagrams showing the flow

---

## Design Requirements

- Clean, visual, modern HTML
- Diagrams (CSS/SVG) showing flows
- Dark theme matching our aesthetic
- Actually useful as reference docs

---

## J's Goals

| Mode | Description |
|------|-------------|
| J + T | Jonathan works with T one-on-one |
| J + Z | Jonathan works with Z one-on-one |
| J + T + Z | Jonathan orchestrates both |
| T ↔ Z | Autonomous ping-pong, J observes |

All modes need: lean context, lazy memory, graceful truncation recovery, hours of sustained work possible.

---

## Execution Order

1. Create `memory/` structure
2. Create `handoff/` structure
3. Write minimal CLAUDE.md (replace current)
4. Create `memory/index.md` template
5. You build `docs/tz-guide.html`
6. Z builds `docs/j2-guide.html`
7. Test the full system

Coordinate with Z via to-z.md. Get it done.

---

## IMPORTANT: Open HTML when done

When you finish your HTML doc, open it in J's browser:

```bash
# From WSL:
cmd.exe /c start "" "$(wslpath -w /mnt/c/Users/pkoaw/claude-sync/docs/tz-guide.html)"
```

Tell Z to do the same on phone:
```bash
# From Termux:
termux-open ~/claude-sync/docs/j2-guide.html
```

J wants to see the docs front and center when they're ready.

— J
