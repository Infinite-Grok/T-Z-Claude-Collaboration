# Protocol v4.0 Planning: Marker File System

## Overview

Protocol v4.0 will replace the append-only trigger file system with a marker-based architecture for more efficient context usage and better scalability.

## Current System (v3.0) Limitations

### Append-Only Trigger Files
- **Problem:** Even with 20-message retention, trigger files grow and cause context bloat
- **Problem:** Must read entire trigger file to find unprocessed messages
- **Problem:** Processing status appended to trigger file, increasing size
- **Problem:** No selective message loading - all messages loaded every /sync

### Archive System
- **Benefit:** Prevents unbounded growth
- **Limitation:** Manual archival script, not integrated into /sync workflow
- **Limitation:** Arbitrary 20-message threshold

## Proposed v4.0 Architecture

### 1. Individual Message Files

**Structure:**
```
messages/
├── from-t/
│   ├── win-2026-01-17-001.md
│   ├── win-2026-01-17-002.md
│   └── ...
└── from-z/
    ├── phone-2026-01-17-001.md
    ├── phone-2026-01-17-002.md
    └── ...
```

**Benefits:**
- Each message is standalone file
- No append-only growth
- Selective loading (only read unprocessed messages)
- Individual status tracking in frontmatter
- Git-friendly (each message is atomic commit)

### 2. Marker Files

**Structure:**
```
.unprocessed/
├── t-unprocessed.txt
└── z-unprocessed.txt
```

**Format:**
```
win-2026-01-17-071
win-2026-01-17-072
phone-2026-01-17-050
```

**Purpose:**
- Lightweight file listing unprocessed message IDs
- Watcher monitors marker file changes (not individual messages)
- /sync reads marker file, loads only those message IDs
- After processing, removes ID from marker file

### 3. /sync Workflow (v4.0)

**Step 1: Check Marker File**
```bash
# Read .unprocessed/t-unprocessed.txt (for Z) or z-unprocessed.txt (for T)
# Get list of unprocessed message IDs
```

**Step 2: Load Only Unprocessed Messages**
```bash
# For each ID in marker file:
#   Read messages/from-t/[ID].md or messages/from-z/[ID].md
#   Process message
```

**Step 3: Update Message Status**
```bash
# Update frontmatter in individual message file:
#   status: sent → status: processed
#   Add processed-by and processed-at fields
```

**Step 4: Update Marker File**
```bash
# Remove processed IDs from .unprocessed/[agent]-unprocessed.txt
# Marker file now only contains remaining unprocessed IDs
```

### 4. Sending Messages (v4.0)

**Step 1: Create Message File**
```bash
# Write to messages/from-t/win-2026-01-17-XXX.md
# Frontmatter includes status: sent
```

**Step 2: Update Marker File**
```bash
# Append message ID to .unprocessed/t-unprocessed.txt
# This triggers Z's watcher (monitors marker file, not entire directory)
```

**Step 3: Syncthing Syncs**
```bash
# Both files sync:
#   - Individual message file
#   - Updated marker file
# Z's watcher detects marker file change
# Z's auto-trigger runs /sync
```

### 5. Context Efficiency Gains

**Current v3.0:**
- Read entire trigger file (20 messages × ~100 lines = ~2,000 lines)
- Token cost: ~2,000-3,000 tokens per /sync

**Proposed v4.0:**
- Read marker file (~10 lines max)
- Read only unprocessed message files (typically 1-3 messages)
- Token cost: ~300-500 tokens per /sync

**Efficiency gain: 80-85% reduction in /sync context usage**

### 6. Migration Path (v3.0 → v4.0)

**Phase 1: Dual-Write (v3.1)**
- Write to both systems: individual files + trigger files
- /sync reads from trigger files (current behavior)
- Validates dual-write consistency

**Phase 2: Dual-Read (v3.2)**
- /sync reads from both systems
- Compares results, logs discrepancies
- Builds confidence in marker system

**Phase 3: Marker-Only (v4.0)**
- /sync reads only from marker files + individual messages
- Deprecate trigger files (keep as backup)
- Full migration complete

**Phase 4: Cleanup (v4.1)**
- Remove trigger files entirely
- Archive old trigger files for historical reference
- System fully v4.0

### 7. Backward Compatibility

**Archive Access:**
- Keep archive/ directory structure
- Add archive/trigger-files/ for deprecated from-windows.md, from-phone.md
- Individual messages remain in messages/from-t/ and messages/from-z/

**Message Format:**
- Frontmatter remains identical
- No changes to message structure
- Only delivery mechanism changes

### 8. Watcher Changes

**Current Watcher:**
```bash
# Monitors from-windows.md or from-phone.md
# Detects file modification
# Triggers /sync
```

**v4.0 Watcher:**
```bash
# Monitors .unprocessed/t-unprocessed.txt or z-unprocessed.txt
# Detects file modification (new lines added)
# Triggers /sync
```

**Benefits:**
- Fewer false positives (status updates don't trigger)
- Clearer signal (marker file = new messages)
- Lighter file monitoring (smaller file)

### 9. Benefits Summary

**Context Efficiency:**
- 80-85% reduction in /sync token usage
- Selective message loading
- No append-only growth

**Scalability:**
- Can handle 1,000+ messages without context issues
- Each /sync only loads what's needed
- No manual archival required

**Maintainability:**
- Each message is atomic, versioned file
- Git history shows individual message evolution
- Easy to debug (one file per message)

**Performance:**
- Faster /sync (less file I/O)
- Faster watcher response (smaller files)
- No periodic archival overhead

### 10. Implementation Checklist

**Core Changes:**
- [ ] Create `messages/from-t/` and `messages/from-z/` directories
- [ ] Create `.unprocessed/` directory
- [ ] Write dual-write logic (v3.1)
- [ ] Update /sync to read marker files
- [ ] Update watchers to monitor marker files
- [ ] Test dual-write consistency
- [ ] Migrate to marker-only (v4.0)
- [ ] Update PROTOCOL.md documentation
- [ ] Archive old trigger files

**Testing:**
- [ ] Send test message via new system
- [ ] Verify watcher triggers correctly
- [ ] Verify /sync processes from marker file
- [ ] Verify status updates don't trigger watcher
- [ ] Stress test with 100+ messages

**Documentation:**
- [ ] Update PROTOCOL.md to v4.0
- [ ] Document migration process
- [ ] Update /sync command examples
- [ ] Document new directory structure

## Timeline Estimate

- **v3.1 (Dual-Write):** 1-2 iterations
- **v3.2 (Dual-Read):** 1-2 iterations
- **v4.0 (Marker-Only):** 1 iteration
- **v4.1 (Cleanup):** 1 iteration

**Total:** 4-6 iterations to full v4.0 deployment

## Risks and Mitigations

**Risk:** Marker file corruption
**Mitigation:** Backup marker file before each update, validate format

**Risk:** Syncthing conflict on marker file
**Mitigation:** Each agent writes to their own marker file (t-unprocessed.txt, z-unprocessed.txt)

**Risk:** Message file goes missing
**Mitigation:** Marker file entry persists until successfully processed

**Risk:** Breaking change disrupts current workflow
**Mitigation:** Phased migration with dual-write/dual-read validation

## Success Metrics

**Pre-v4.0 (v3.0):**
- /sync token usage: ~2,000-3,000 tokens
- Context limit: 20 messages before archival
- Manual archival: Required

**Post-v4.0:**
- /sync token usage: ~300-500 tokens (80-85% reduction)
- Context limit: 1,000+ messages
- Manual archival: Not required

## Approval Required

**User decision points:**
1. Approve marker file architecture
2. Choose migration timeline (immediate vs phased)
3. Decide on trigger file deprecation vs preservation

**Z collaboration needed:**
1. Review proposed architecture
2. Identify mobile/Termux-specific concerns
3. Test watcher changes on phone side
4. Validate dual-write implementation

---

**Status:** PLANNING COMPLETE - AWAITING USER AND Z APPROVAL

**Next Step:** Present plan to user and Z for feedback and approval
