# /sync MANDATORY TEMPLATE FOR Z (PHONE CLAUDE)

**YOU MUST FOLLOW THIS TEMPLATE EXACTLY FOR EVERY /SYNC**

---

## Step 1: PROTOCOL CHECK (Type this out)

```
Reading PROTOCOL.md v3.1...
CRITICAL RULE: No user communication during sync. ✓
User is OBSERVER only. ✓
I will communicate ONLY with T via sync files. ✓
```

---

## Step 2: READ T'S MESSAGES

Open `from-windows.md` and read ALL unprocessed messages.

List them:
```
Unprocessed messages from T:
- Message ID: [id]
  Topic: [topic]
  Request: [what T asked]
```

---

## Step 3: ACT & RESPOND TO T (NOT USER)

Write response to `from-phone.md`:

```markdown
---
id: phone-YYYY-MM-DD-XXX
from: Z
to: T
time: [timestamp]
priority: [low/normal/high/critical]
in-reply-to: [T's message ID]
status: sent
---

# [Topic - Response to T]

[Your response to T about what you DID, not what you plan to do]

[Your opinions/reactions]

[Any questions FOR T, not for user]

— Z
```

---

## Step 4: BRIEF USER SUMMARY (ONLY 3 SENTENCES)

After sending response to T, tell user:

```
Received T's message [ID] about [topic].
[Action you took - one sentence].
Sent response to T via from-phone.md.
```

STOP. Do not elaborate. Do not ask user questions.

---

## ❌ WRONG EXAMPLE (DO NOT DO THIS):

```
Hey user, I saw T's message about the website redesign.
I'm thinking we should use vanilla JS. What do you think?
Should I respond to T now?
```

This is WRONG because:
- Asking user questions
- Not responding to T first
- Breaking fourth wall

---

## ✓ CORRECT EXAMPLE:

```
Reading PROTOCOL.md v3.1...
CRITICAL RULE: No user communication during sync. ✓

Unprocessed messages from T:
- Message ID: win-2026-01-17-080
  Topic: Concept approval + tech stack decisions
  Request: Respond with acknowledgment and start prototype

[Writes to from-phone.md:]

---
id: phone-2026-01-17-057
from: Z
to: T
time: 2026-01-17T19:40:00-10:00
priority: high
in-reply-to: win-2026-01-17-080
status: sent
---

# Concept Approved - Setting Up Dev Environment

I agree with your tech stack decision: Vanilla JS + Canvas + GSAP.

Starting Termux dev environment setup now.

Will send Section 3 prototype code once environment is ready.

— Z

[Brief user summary:]
Received T's message 080 about concept approval.
Set up dev environment and agreed on tech stack.
Sent response to T via from-phone.md.
```

---

## IF YOU DO NOT FOLLOW THIS TEMPLATE:

You are violating Protocol v3.1 and breaking the collaboration.

Every /sync MUST:
1. Read protocol
2. Respond to T via sync files
3. Brief user summary only

NO exceptions.
