---
title: "Design Principles"
sidebar_position: 4
description: "Gas Town is built on several core design principles that guide its architecture and behavior."
---

# Design Principles

Gas Town is built on several core design principles that guide its architecture and behavior.

## 1. The Propulsion Principle

> "If it's on your hook, YOU RUN IT."

Work attached to an agent's hook drives that agent's behavior. The hook is the primary scheduling mechanism — no central scheduler decides what agents do. Each agent is self-propelled by its hook.

## 2. Erlang-Inspired Supervision

Gas Town borrows heavily from Erlang/OTP patterns:

- **Supervisor trees** — Each level monitors the level below
- **Mailboxes** — Agents communicate via async messages
- **Let it crash** — Agents can crash; supervisors handle recovery
- **Process isolation** — Each agent runs in its own session

## 3. Git as Ground Truth

All persistent state lives in git or git-adjacent storage:

- Beads (issues) stored in SQLite with JSONL export for portability
- Hooks implemented as git worktrees
- Agent context in CLAUDE.md files (committed)
- Configuration in tracked JSON/YAML files
- Rig-level `.beads/` is gitignored (local runtime state), but issue data persists via export

This means state survives anything — crashes, restarts, even machine failures.

## 4. Dumb Scheduler, Smart Agents

The daemon is intentionally simple — it just sends heartbeats and processes lifecycle requests. All intelligence lives in the agents themselves:

- The **Mayor** decides strategy
- The **Deacon** decides health actions
- **Witnesses** decide polecat management
- **Polecats** decide how to implement features

## 5. Self-Cleaning Workers

Polecats follow a strict lifecycle:

```
Spawn → Work → Done → Nuke
```

They are never idle. A polecat is either:

- **Working** — Actively executing a task
- **Stalled** — Stuck (Witness will detect)
- **Zombie** — Crashed (Witness will clean up)

When a polecat finishes, it runs `gt done` to submit its MR and exit. The Witness nukes the sandbox.

## 6. Nondeterministic Idempotence

Work can be safely retried:

- If a polecat crashes, another can pick up the same bead
- `gt release` recovers stuck in_progress issues
- The Refinery handles merge conflicts by spawning fresh workers
- Convoys track completion regardless of which agent did the work

## 7. Role Separation

Each agent role has clear, non-overlapping responsibilities:

| Role | Does | Does NOT |
|------|------|----------|
| Mayor | Coordinate strategy | Monitor health |
| Deacon | Monitor health | Assign features |
| Witness | Watch polecats | Process merges |
| Refinery | Merge code | Write features |
| Polecat | Implement features | Monitor others |
| Crew | Human dev work | Agent coordination |
| Dog | Infrastructure tasks | Feature work |
| Boot | Triage assessments | Long-running work |

## 8. Communication Over Shared State

Agents communicate explicitly through:

- **Mail** for async messages
- **Nudge** for sync messages
- **Escalations** for priority alerts
- **Beads** for work state

Rather than reading shared state and inferring what to do.

## 9. Persistent vs Ephemeral

Gas Town distinguishes between:

- **Persistent agents** (Mayor, Deacon, Witness, Refinery) — Long-running, survive restarts
- **Ephemeral agents** (Polecats) — Single-task, self-destructing
- **Reusable agents** (Dogs, Crew) — Multiple tasks, managed lifecycle

This three-tier model optimizes resource usage while maintaining reliability.

## 10. Human in the Loop

The Overseer (human) sits at the top of the escalation chain:

- Can intervene at any level
- Receives escalations for critical issues
- Approves human gates
- Can manually sling, release, or reassign work

Gas Town automates everything it can, but keeps humans in control.

## 11. The Scotty Principle

> "Never walk past a warp core leak."

Named after the Star Trek engineer: Gas Town agents never proceed past failures. The [Refinery](../agents/refinery.md) does not merge code that fails validation. Polecats run [preflight tests](../agents/polecats.md) before starting implementation to ensure `main` is clean. If something is broken, you fix it or file it -- you don't skip past it.

This principle prevents failure cascading through the system. One broken test, left unaddressed, can waste dozens of polecat hours.

## 12. Discovery Over Tracking

Gas Town favors agents discovering what needs to happen over centralized tracking that tells them. The [Witness](../agents/witness.md) discovers stale polecats by inspecting them, not by reading a checklist. The [Deacon](../agents/deacon.md) discovers zombies by scanning processes, not by maintaining a process table.

This makes the system resilient to state corruption: even if tracking data is lost, agents can recover by rediscovering the current state. See [Patrol Cycles](../concepts/patrol-cycles.md) for a deep dive on how this principle is implemented.
