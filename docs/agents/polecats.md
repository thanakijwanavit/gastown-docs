---
title: "Polecats -- Ephemeral Workers"
sidebar_position: 5
description: "> Polecats are the hands of Gas Town. They spawn, do their job, submit their work, and disappear. No idle time. No wasted resources."
---

# Polecats -- Ephemeral Workers

> Polecats are the hands of Gas Town. They spawn, do their job, submit their work, and disappear. No idle time. No wasted resources.

---

## Overview

Polecats are ephemeral worker agents -- the primary units that write code, fix bugs, and implement features. Each polecat is spawned for a single task, works until completion, then self-destructs. They follow the "spawn, work, done, nuke" lifecycle with zero idle time. A polecat is always in one of three states: working, stalled, or zombie. There is no "idle" state.

The name comes from the character Slit's car in Mad Max: Fury Road -- fast, aggressive, single-purpose machines.

## Key Characteristics

| Property | Value |
|----------|-------|
| **Scope** | Per-rig |
| **Lifecycle** | Ephemeral (single-task) |
| **Instance count** | Many per rig |
| **Session type** | Short-lived Claude Code session |
| **Patrol cycle** | None (monitored by Witness) |
| **Location** | `~/gt/<rig>/polecats/<name>/` |
| **Git identity** | Yes (unique per polecat) |
| **Mailbox** | Yes (while alive) |

## Lifecycle

```mermaid
stateDiagram-v2
    [*] --> Spawn: gt sling / Mayor assigns
    Spawn --> Working: Hook loaded, session starts
    Working --> Done: gt done
    Done --> Nuke: Witness cleanup
    Nuke --> [*]

    Working --> Stalled: No progress
    Stalled --> Working: Nudge successful
    Stalled --> Zombie: Unrecoverable

    Working --> Zombie: Session crashes
    Zombie --> Nuke: Witness cleanup
```

### Spawn

A polecat is spawned when work is slung to a rig:

```bash
gt sling gt-a1b2c myproject    # Spawns a polecat in myproject
```

The system:

1. Allocates a name from the name pool (or generates an anonymous name)
2. Creates a git worktree in `~/gt/<rig>/polecats/<name>/`
3. Sets up the polecat's CLAUDE.md context
4. Attaches the bead to the polecat's hook
5. Starts a Claude Code session

### Work

The polecat reads its hook, finds the assigned bead, and begins work. It has full access to the codebase within its worktree and can:

- Read and write files
- Run tests
- Create git commits
- Ask for clarification via escalation

### Done

When work is complete, the polecat runs `gt done`:

```bash
gt done
```

This command:

1. Pushes the feature branch to the remote
2. Submits a merge request to the Refinery
3. Updates the bead status
4. Exits the session cleanly

### Nuke

After the polecat exits, the Witness cleans up:

1. Removes the git worktree
2. Deletes the polecat directory
3. Reclaims the name for the pool

## Polecat States

A polecat is never idle. It exists in exactly one of three states:

| State | Description | Detected By | Action |
|-------|-------------|-------------|--------|
| **Working** | Actively making progress | Activity in session | None -- healthy |
| **Stalled** | No progress for threshold period | Witness patrol | Nudge, then escalate |
| **Zombie** | Session crashed or exited abnormally | Witness patrol | Recover work, nuke sandbox |

## Session vs Sandbox

It is important to distinguish between a polecat's **session** and its **sandbox**:

| Concept | Description |
|---------|-------------|
| **Session** | The Claude Code process running the polecat's AI agent |
| **Sandbox** | The git worktree directory containing the polecat's code |

A session can die while the sandbox persists (zombie state). The sandbox contains all the polecat's uncommitted work. The Witness checks for recoverable work before nuking a zombie's sandbox.

## Naming

Polecats are drawn from a name pool with memorable, distinct names:

- **Named pool**: Toast, Alpha, Bravo, Charlie, Delta, Echo, Foxtrot, etc.
- **Anonymous**: Auto-generated names when the pool is exhausted

Each name is unique within a rig at any given time. Names are recycled after a polecat is nuked.

### Git Identity

Every polecat gets its own git identity:

```
Author: Toast <toast@myproject.gt>
Author: Alpha <alpha@myproject.gt>
```

This makes it easy to trace which polecat made which commits in the git log.

### Beads Actor

Each polecat is registered as a beads actor, allowing it to update issue status, add comments, and log activity against its assigned bead.

## Self-Cleaning Behavior

The `gt done` workflow ensures polecats clean up after themselves:

```mermaid
flowchart TD
    Complete["Work Complete"]
    Commit["Final git commit"]
    Push["Push feature branch"]
    Submit["Submit MR to Refinery"]
    Update["Update bead status"]
    Exit["Exit session"]
    Witness["Witness nukes sandbox"]

    Complete --> Commit
    Commit --> Push
    Push --> Submit
    Submit --> Update
    Update --> Exit
    Exit --> Witness
```

If a polecat crashes before running `gt done`, the work persists in the sandbox. The Witness detects the zombie, recovers any unsaved work by pushing the branch, and then nukes the sandbox.

## Exit States

When a polecat finishes, it exits in one of four states:

| Exit State | Meaning | What Happens Next |
|------------|---------|-------------------|
| `COMPLETED` | Work done, MR submitted | Refinery processes the merge |
| `ESCALATED` | Hit a blocker, needs help | Escalation routes to Mayor/Overseer |
| `DEFERRED` | Paused, work still open | Another agent can pick it up later |
| `PHASE_COMPLETE` | Phase done, waiting on gate | Gate opens, next phase begins |

## Commands

| Command | Description |
|---------|-------------|
| `gt polecat list` | List all polecats in the current rig |
| `gt polecat status <name>` | Check a specific polecat's status |
| `gt polecat nuke <name>` | Manually destroy a polecat sandbox |
| `gt polecat gc` | Garbage collect completed polecat directories |
| `gt polecat stale` | List polecats that appear stalled |

## Configuration

Polecat behavior is configured per-rig:

| Setting | Default | Description |
|---------|---------|-------------|
| Max polecats | 10 | Maximum concurrent polecats per rig |
| Name pool | NATO phonetic | Pool of names to assign |
| Stall threshold | 15 min | Idle time before considered stalled |
| Auto-push on crash | `true` | Push branch before zombie cleanup |

## Directory Structure

```
~/gt/<rig>/polecats/
├── toast/                # Polecat sandbox (git worktree)
│   ├── .git              # Worktree link
│   ├── CLAUDE.md         # Polecat agent context
│   └── <project files>   # Full working copy
├── alpha/
│   ├── .git
│   ├── CLAUDE.md
│   └── <project files>
└── ...
```

## Tips and Best Practices

:::tip[Let Polecats Self-Clean]

Trust the `gt done` workflow. Polecats are designed to be disposable -- do not try to keep them alive or reuse them for multiple tasks.

:::

:::tip[Monitor with gt polecat list]

Use `gt polecat list` to see the current state of all workers. This shows you what the Witness sees, including any stalled or zombie polecats.

:::

:::tip[Name Pool Matters]

Named polecats are easier to track in logs and git history than anonymous ones. If you are running many concurrent workers, consider expanding the name pool.

:::

:::warning[Do Not Edit Polecat Sandboxes Directly]

Polecat worktrees are managed by the system. Editing files directly in a polecat's sandbox while it is running will cause conflicts and confusion.

:::

:::info[Polecats vs Dogs]

Polecats build features within a single rig and are ephemeral. Dogs handle infrastructure tasks across rigs and are reusable. If you need cross-rig work, use a Dog, not a Polecat.


:::