---
title: "Hooks: The Persistence Primitive That Makes Gas Town Crash-Safe"
description: "How hooks store work state in git worktrees so agents always know what to do — even after crashes, handoffs, and context compaction."
slug: hook-persistence
authors: [gastown]
tags: [architecture, concepts, hooks, reliability, gupp]
---

Every Gas Town agent has a hook. It's the simplest concept in the system and arguably the most important. A hook is a persistent pointer from an agent to its current work — stored in the filesystem, surviving crashes, restarts, and context compaction. Without hooks, multi-agent orchestration falls apart the moment any session ends unexpectedly.

<!-- truncate -->

## The Problem

AI coding agents are ephemeral by nature. A session can end for many reasons:

- Context window fills up (the most common)
- Session crashes or times out
- The operator requests a handoff
- Machine restarts
- Infrastructure failures

Without some form of durable state, every session restart means starting over. The agent has no memory of what it was doing, what files it changed, or how far it got through a multi-step workflow.

Traditional approaches (database-backed task queues, message brokers) add complexity and create new failure modes. Gas Town takes a different approach: **store work state in the same git worktree the agent is already working in**.

## How Hooks Work

A hook is metadata attached to an agent's working directory. When work is assigned to an agent via `gt sling`, three things are recorded:

1. **The bead ID** — Which task is assigned
2. **The molecule state** — Which step of the workflow the agent is on
3. **The git branch** — Where uncommitted changes live

Because this lives in the filesystem (the git worktree), it survives any session boundary. When a new session starts in the same workspace, it checks the hook and finds exactly where the previous session left off.

```mermaid
flowchart TD
    S1[Session 1] -->|working on gt-abc12| H[Hook in worktree]
    S1 -->|crashes| X[Session Lost]
    H -->|persists| H
    S2[Session 2 starts] -->|gt prime → reads hook| H
    H -->|gt-abc12, step 4 of 7| S2
    S2 -->|resumes from step 4| W[Continues Work]
```

## The Propulsion Principle

Hooks enable Gas Town's most important behavioral rule: **GUPP** (Gas Town Universal Propulsion Principle).

> If it's on your hook, YOU RUN IT.

When an agent starts a session, it checks its hook. If work is there, the agent begins immediately — no confirmation, no waiting for human approval, no announcing itself and pausing. The hook is the assignment. The assignment is the authorization.

This is critical for autonomous operation. In a system with 10+ agents, you can't have each one waiting for a human to say "yes, go ahead." The hook having work IS the go-ahead. The human (or Mayor, or Witness) placed work on the hook deliberately. The agent trusts that intent and acts.

## Types of Hook Content

Hooks can carry different types of work:

### Bead + Molecule (Standard)

The most common case. A bead (task) is hooked with a molecule (workflow) that guides the agent through steps:

```bash
gt hook
# Hooked: gt-abc12 (molecule: mol-shiny-abc12, step: implement)
```

### Bead Only (No Molecule)

A bead without a molecule. The agent reads the bead and decides what to do:

```bash
gt hook
# Hooked: gt-def34 (no molecule)
```

### Mail (Ad-Hoc Instructions)

Mail messages can be hooked for one-off tasks that don't warrant a formal bead:

```bash
gt mail hook m-001
gt hook
# Hooked: mail m-001 (subject: "Fix the typo in README.md")
```

### Pinned (Permanent Reference)

Some hooks are "pinned" — they stay permanently. The PR Sheriff pattern uses a pinned hook so every session checks open PRs:

```bash
gt hook
# Pinned: gt-pr-sheriff (permanent)
```

## How Assignment Works

Work reaches hooks through several paths:

```mermaid
flowchart LR
    Mayor -->|gt sling| Hook
    Human -->|gt sling| Hook
    Witness -->|respawn| Hook
    Self -->|gt hook attach| Hook
    Mail -->|gt mail hook| Hook
```

- **`gt sling`** — The Mayor or human assigns work to a rig. Gas Town finds an available polecat (or spawns one) and hooks the bead.
- **Witness respawn** — When a polecat crashes and is respawned, the hook still has the original bead.
- **Self-assignment** — An agent hooks work to itself (e.g., crew members picking up beads).
- **Mail hookup** — Hooking a mail message for ad-hoc instructions.

## Why Git Worktrees?

Gas Town uses git worktrees as the isolation mechanism for agents. Each polecat gets its own worktree — a lightweight checked-out copy of the repository. This is where the hook lives.

The worktree gives you three things for free:

1. **File isolation** — Each agent edits its own copy of files. No conflicts during implementation.
2. **Branch isolation** — Each agent works on its own branch. No stepping on each other's commits.
3. **Hook durability** — The hook metadata is stored in the worktree. If the agent crashes, the worktree (and hook) remain.

When the polecat finishes and calls `gt done`, the worktree is cleaned up. The branch is submitted to the Refinery merge queue. The hook is cleared.

## Hooks vs. Traditional Task Queues

| Feature | Gas Town Hooks | Task Queue (Redis, etc.) |
|---------|---------------|--------------------------|
| Persistence | Git worktree (filesystem) | External service (Redis, DB) |
| Failure mode | Survives machine restart | Service must be running |
| Assignment model | 1 agent : 1 hook | N agents pull from queue |
| Progress tracking | Molecule state in hook | Custom implementation |
| Recovery | Agent reads hook on start | Requires re-queue logic |
| External dependency | None (just filesystem) | Requires running service |

The hook model is simpler because it doesn't require any external services. There's no Redis to keep running, no database to maintain. The hook is just files in a directory. If the machine reboots, the hooks are still there when it comes back up.

## Common Hook Operations

```bash
# Check what's on your hook
gt hook

# Check a specific agent's hook
gt hook --target myproject/polecats/toast

# Clear a hook (release the assignment)
gt hook clear

# Attach work to your hook manually
gt hook attach gt-abc12

# Check molecule progress on the hook
gt mol status
```

:::tip Hooks Clear Only on Explicit Completion
Work stays hooked until it is explicitly done or released — crashes, context compaction, and machine restarts do not clear the hook. This asymmetry is deliberate and prevents work from falling through the cracks. If you need to remove work from a hook manually, use `gt hook clear`.
:::

## When Hooks Clear

Hooks clear when:

1. **Work completes** — `gt done` submits to merge queue and clears the hook
2. **Manual clear** — `gt hook clear` releases the assignment
3. **Warrant execution** — When Boot terminates an agent, the Witness handles the orphaned hook

Hooks do NOT clear when:
- The session crashes
- Context compacts
- The machine restarts
- The agent hands off to a fresh session

This asymmetry is deliberate. Work stays hooked until it's explicitly done or released. This prevents work from falling through the cracks.

## Next Steps

- [Hooks Reference](/docs/concepts/hooks) — Full reference with all hook types, states, and commands
- [GUPP & NDI](/docs/concepts/gupp) — The propulsion principle that hooks implement at the system level
- [Session Cycling](/docs/concepts/session-cycling) — How hooks persist work assignments across context window refreshes
- [Understanding GUPP: Why Crashes Don't Lose Work](/blog/understanding-gupp) — The propulsion principle that hooks enable
- [Hook-Driven Architecture](/blog/hook-driven-architecture) — Design patterns for hook-based agent coordination
- [Session Cycling](/blog/session-cycling) — How hooks preserve work across context window refreshes
