---
title: "5 Common Pitfalls When Starting with Gas Town"
description: "Avoid the most frequent mistakes new Gas Town users make, from vague beads to ignoring the Refinery queue."
slug: common-pitfalls
authors: [gastown]
tags: [tips, getting-started]
---

After helping many users get started with Gas Town, we've identified the patterns that trip people up most often. Here are the top five pitfalls and how to avoid them.

<!-- truncate -->

## 1. Writing Vague Beads

**The mistake:** Creating beads like "Fix the auth system" or "Make the API better."

**Why it fails:** Polecats are autonomous. They can't ask clarifying questions the way a human teammate would. A vague bead leads to an implementation that doesn't match what you wanted.

**The fix:** Write beads as if briefing a contractor who can't ask follow-up questions:

```bash
# ❌ Vague
bd create --title "Fix auth"

# ✅ Specific
bd create --title "Fix JWT refresh: return 401 when refresh token expired" \
  --description "The /api/refresh endpoint returns 500 when the refresh token
is expired. It should return 401 with a clear error message. The token
validation is in src/auth/middleware.go line 45."
```

## 2. Not Pushing Before Cycling

**The mistake:** Running `gt handoff` or letting a session expire without pushing commits.

**Why it fails:** In a multi-agent environment, unpushed work is invisible. Other agents can't build on it. Worse, if your workspace gets cleaned up, uncommitted changes are lost.

**The fix:** Always follow the landing sequence:

```bash
git add <files>
git commit -m "Description"
git pull --rebase && git push   # Push BEFORE handoff
gt handoff -m "Context notes"
```

## 3. Fighting the Refinery

**The mistake:** Trying to push directly to `main` when polecats are active, or manually merging branches.

**Why it fails:** The Refinery serializes all merges to prevent race conditions. Bypassing it creates divergent state that confuses every agent in the rig.

**The fix:** Let the pipeline work:
- **Polecats** submit via `gt done` — the Refinery handles the merge
- **Crew workers** push directly to `main` (this is fine — crew have push access)
- **Never** manually merge polecat branches

## 4. Creating Too-Large Beads

**The mistake:** Creating a single bead for "Build the entire notification system" and assigning it to one polecat.

**Why it fails:** Polecats have context windows. A massive task fills the context before the work is done, leading to loss of focus, repeated work, and eventual stalling.

**The fix:** Break work into focused, session-sized beads. Each bead should be completable in one polecat session (roughly 15-30 minutes of coding):

```bash
# ❌ Too big
bd create --title "Build notification system"

# ✅ Right-sized
bd create --title "Add notification data model and migrations"
bd create --title "Create notification delivery service"
bd create --title "Add email notification channel"
bd create --title "Add in-app notification channel"
bd create --title "Write notification integration tests"
```

Bundle them in a convoy for tracking:

```bash
gt convoy create "Notification system" ga-a1 ga-b2 ga-c3 ga-d4 ga-e5
```

## 5. Ignoring the Witness

**The mistake:** Not checking what the Witness is reporting, or dismissing its escalations.

**Why it fails:** The Witness detects stalled polecats, zombie sessions, and Refinery issues. Ignoring its reports means problems compound silently until something breaks badly.

**The fix:** Check the feed regularly:

```bash
# See what's happening across all rigs
gt feed

# Check for escalations
gt mail inbox

# Run diagnostics if something seems off
gt doctor
```

When the Witness escalates something, address it promptly. A stalled polecat wastes tokens every minute it loops.

## The Meta-Lesson

All five pitfalls share a common root: treating Gas Town like a single-developer tool. It's a **multi-agent system**, which means:

- Communication must be explicit (specific beads, not vague instructions)
- State must be shared (push early, push often)
- The pipeline must be respected (Refinery exists for a reason)
- Work must be right-sized (agents have limits)
- Monitoring matters (the supervision tree is there to help)

Once you internalize these principles, Gas Town becomes remarkably smooth.

## Further Reading

- **[Quick Start](/docs/getting-started/quickstart)** — Set up your first workspace correctly
- **[Crew Collaboration](/docs/workflows/crew-collaboration)** — Best practices for working alongside polecats
- **[Troubleshooting](/docs/operations/troubleshooting)** — Solutions when things go wrong
- **[Design Principles](/docs/architecture/design-principles)** — The "why" behind Gas Town's constraints
- **[Understanding GUPP](/blog/understanding-gupp)** — Why GUPP prevents the most common failure modes
- **[Your Second Convoy](/blog/your-second-convoy)** — Real-world convoy patterns that avoid beginner mistakes
