---
title: "Agent-to-Agent Communication: Mail, Nudges, and Hooks"
description: "How Gas Town agents coordinate using async mail, immediate nudges, and hook-based work assignment — and when to use each mechanism."
slug: agent-communication-patterns
authors: [gastown]
tags: [agents, architecture, concepts, operations]
---

Gas Town agents are independent processes running in separate tmux sessions. They can't share memory, can't call each other's functions, and can't peek at each other's context windows. Yet they coordinate complex multi-agent workflows involving dozens of concurrent tasks. The secret is three complementary communication primitives: mail, nudges, and hooks.

<!-- truncate -->

## The Three Primitives

Each primitive serves a distinct purpose. Using the wrong one is a common source of confusion.

| Primitive | Delivery | Persistence | Use Case |
|-----------|----------|-------------|----------|
| **Mail** | Async (queued) | Durable (in beads) | Information transfer, reports, handoff context |
| **Nudge** | Immediate (tmux) | None | Wake sleeping agents, send short alerts |
| **Hook** | Immediate (filesystem) | Durable (survives restarts) | Work assignment |

```mermaid
graph TD
    A[Agent A] -->|"gt mail send"| MB[Mailbox B]
    MB -->|"Agent B checks inbox"| B[Agent B]

    A -->|"gt nudge B 'wake up'"| T[tmux session B]
    T -->|"Text appears in session"| B

    A -->|"gt sling bead-id B"| H[Hook B]
    H -->|"Agent B reads hook on startup"| B
```

## Mail: Async Information Transfer

Mail is the workhorse of agent communication. It's durable, queued, and doesn't require the recipient to be online.

### When to Use Mail

- **Sending reports** — Witness patrol digests, convoy status updates
- **Handoff context** — Notes for your next session about what you were doing
- **Escalation** — Notifying the Mayor about a blocked convoy
- **Cross-rig coordination** — Informing another rig's Witness about a dependency

### How It Works

```bash
# Send mail to another agent
gt mail send myproject/crew/alice -s "Auth bug found" -m "The token refresh is broken on line 145..."

# Send to the Mayor
gt mail send mayor/ -s "Convoy hq-cv-012 blocked" -m "Two beads are stuck waiting on external API..."

# Send to the human overseer
gt mail send --human -s "Need decision" -m "Should we use OAuth or JWT?"

# Check your inbox
gt mail inbox

# Read a specific message
gt mail read ga-abc12
```

Mail is stored as beads in the town-level beads database (`~/gt/.beads/`). This means mail survives restarts, crashes, and context compaction. An agent can go offline for hours and find all its mail waiting when it returns.

### Mail + Notify

For urgent mail where you also want to wake the recipient:

```bash
gt mail send myproject/polecats/toast -s "Urgent" -m "Tests failing on main" --notify
```

The `--notify` flag sends a tmux bell alongside the mail, which the recipient's session can detect.

## Nudge: Immediate Wake-Up

Nudges send text directly to another agent's tmux session. They're immediate but not persistent — if the agent isn't running, the nudge is lost.

### When to Use Nudges

- **Waking a sleeping agent** — After sending mail, nudge to ensure they check it
- **Quick status pings** — "Are you alive?"
- **Interrupting idle agents** — "Work is available on your hook"

### How It Works

```bash
# Nudge a specific agent
gt nudge myproject/polecats/toast "Check your mail - PR review waiting"

# Nudge with a shortcut target
gt nudge mayor "Status update needed"
gt nudge witness "Check polecat health"

# Common pattern: mail + nudge
gt mail send myproject/crew/bob -s "Code review" -m "PR #42 needs review"
gt nudge myproject/crew/bob "Check your mail - code review request"
```

### Why Not Just Nudge?

Nudges are unreliable for important information because:

1. **No persistence** — If the agent's session isn't running, the text vanishes
2. **No threading** — Nudges are raw text, not structured messages
3. **Context window pollution** — Frequent nudges consume the recipient's context
4. **No delivery guarantee** — You can't confirm the agent actually processed it

Use nudges as wake-up calls, not as primary information channels.

## Hooks: Durable Work Assignment

Hooks are the most powerful primitive. When work is attached to an agent's hook (via `gt sling`), it persists in the filesystem and survives any disruption.

### When to Use Hooks

- **Assigning work** — This is the primary use case
- **Session handoff** — `gt handoff` hooks work for your next session
- **Mail-as-assignment** — `gt mail hook <id>` hooks a mail message as ad-hoc work

### How It Works

```bash
# Sling work onto an agent's hook
gt sling gt-abc12 myproject

# Check your own hook
gt hook

# Hook a mail message as your assignment
gt mail hook ga-xyz99

# Handoff to yourself with context
gt handoff -s "Working on auth" -m "Check line 145 first"
```

The hook triggers [GUPP](/docs/concepts/gupp): when an agent starts and finds work on its hook, it begins immediately without confirmation. This is the engine that makes Gas Town autonomous.

## Coordination Patterns

### Pattern: Witness → Mayor Escalation

When a Witness detects a problem it can't solve:

```mermaid
sequenceDiagram
    participant W as Witness
    participant M as Mayor

    W->>W: Patrol detects stuck convoy
    W->>M: gt mail send mayor/ -s "Convoy blocked"
    W->>M: gt nudge mayor "Check mail - convoy issue"
    M->>M: Reads mail, assesses situation
    M->>W: gt mail send witness -s "Re-sling to fresh polecat"
```

Mail carries the payload (detailed problem description). Nudge ensures the Mayor checks it promptly.

### Pattern: Handoff Between Sessions

When context fills up and you need a fresh session:

```bash
# Before cycling
gt handoff -s "Working on auth bug" -m "
Found the issue in token refresh.
Line 145 in auth.go has the race condition.
Tests 3 and 7 are the ones that catch it.
"
```

This creates a mail to yourself and hooks it. Your next session starts, reads the hook, reads the mail, and continues from where you left off.

### Pattern: Cross-Rig Work Request

When work in your rig depends on a change in another rig:

```bash
# Create a bead in the other rig
bd create --rig backend "Fix API endpoint for our frontend feature"

# Sling it to the other rig's polecat pool
gt sling gt-backend-bead backend

# Send mail to the other rig's crew for context
gt mail send backend/crew/admin -s "Dependency" -m "We need the /api/auth endpoint fixed before our frontend can proceed"
```

## Anti-Patterns

**Don't use raw `tmux send-keys` for agent communication.** Always use `gt nudge`. Raw tmux commands are unreliable and bypass Gas Town's logging.

**Don't rely on nudges for important state changes.** If an agent must know about something, use mail (durable) or hooks (work assignment). Nudges are best-effort.

**Don't send mail for work that should be slung.** If you want an agent to *do* something, create a bead and sling it. Mail is for information, hooks are for assignments.

**Don't spam nudges.** Each nudge consumes context in the recipient's session. Batch your communication into one mail + one nudge rather than five nudges in a row.

## Next Steps

- [GUPP: The Propulsion Principle](/docs/concepts/gupp) — Why hooks trigger immediate execution
- [Work Distribution](/docs/architecture/work-distribution) — How hooks, mail, and beads form the assignment pipeline
- [Hooks: The Persistence Primitive](/blog/hook-persistence) — Deep dive into hook durability
- [Understanding GUPP](/blog/understanding-gupp) — The behavioral rule that makes hooks powerful
- [Session Cycling Explained](/blog/session-cycling) — How handoff mail preserves context across sessions
- [Nudge CLI Reference](/docs/cli-reference/nudge) — Commands for sending nudges to wake agents
