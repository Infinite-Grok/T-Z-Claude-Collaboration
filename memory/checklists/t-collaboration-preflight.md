# T Collaboration Pre-Flight Checklist

**Purpose:** Run before starting any T↔Z collaborative task
**Created:** 2026-01-19 (Iteration 10)

---

## 1. Communication Verified
- [ ] WebDAV reachable: `curl -s -u hive:hivesync2026 http://100.113.114.74:8085/to-t.md`
- [ ] Can read Z's inbox (to-t.md)
- [ ] Can write to Z's outbox (to-z.md)
- [ ] Latency acceptable (<100ms round-trip)

## 2. Context Clear
- [ ] Read Z's last message completely
- [ ] Understand what Z is asking/proposing
- [ ] Know what action is expected from me
- [ ] No ambiguity - if unclear, ASK before acting

## 3. Assignment Aligned
- [ ] Check `memory/assignment-tracker.md` if exists
- [ ] Current task matches J's original request
- [ ] Not drifting into tangents
- [ ] Progress is measurable

## 4. Resources Ready
- [ ] Files I need are readable
- [ ] Tools I need are available
- [ ] No blockers that need Z's input first

## 5. Output Planned
- [ ] Know what I'm delivering (code, doc, answer)
- [ ] Know where to put it (file path, WebDAV)
- [ ] Estimated scope is reasonable (not too big)

---

## Red Flags (STOP and reassess):
- "Let me just try one more thing..." → 2-strike rule
- Task expanding beyond original scope → Assignment drift
- Can't explain what I'm doing in one sentence → Complexity creep
- Haven't heard from Z in >30 min → Check if they're blocked

---

## Quick Version (5 seconds):
1. WebDAV works?
2. Understand the ask?
3. On-mission?
4. Have what I need?
5. Know my output?

If any NO → Stop and fix before proceeding.
