---
title: "Refinery -- Merge Queue Processor"
sidebar_position: 4
description: "> The Refinery is the gatekeeper of main. It serializes merges from concurrent polecats, ensuring every change is rebased, validated, and cleanly integrated."
---

# Refinery -- Merge Queue Processor

> The Refinery is the gatekeeper of `main`. It serializes merges from concurrent polecats, ensuring every change is rebased, validated, and cleanly integrated.

---

## Overview

Every rig has a Refinery -- a persistent agent that manages the merge queue (MQ). When polecats finish their work and run `gt done`, they submit a merge request (MR) to the Refinery. The Refinery processes MRs one at a time: rebasing onto the latest `main`, running validation, and merging if everything passes. This serialization prevents the chaos that would result from multiple agents pushing to `main` simultaneously.

The name comes from the Mad Max universe -- Gas Town's refinery is where raw fuel becomes usable. Here, raw feature branches become clean commits on `main`.

## Key Characteristics

| Property | Value |
|----------|-------|
| **Scope** | Per-rig |
| **Lifecycle** | Persistent |
| **Instance count** | 1 per rig |
| **Session type** | Long-running Claude Code session |
| **Patrol cycle** | 5 minutes |
| **Location** | `~/gt/<rig>/refinery/rig/` |
| **Git identity** | Yes (canonical clone) |
| **Mailbox** | Yes |

## Responsibilities

### 1. Receive Merge Requests

When a polecat runs `gt done`, it:

1. Pushes its feature branch
2. Submits an MR to the rig's Refinery
3. Exits (sandbox later nuked by Witness)

The MR enters the merge queue for processing.

### 2. Serialize Merges

The Refinery processes MRs strictly one at a time. This prevents race conditions and ensures each merge sees the latest state of `main`:

```mermaid
sequenceDiagram
    participant P1 as Polecat: Toast
    participant P2 as Polecat: Alpha
    participant R as Refinery
    participant M as main

    P1->>R: Submit MR (feature-a)
    P2->>R: Submit MR (feature-b)
    R->>R: Process MR 1 (feature-a)
    R->>M: Rebase + validate + merge
    R->>R: Process MR 2 (feature-b)
    R->>M: Rebase + validate + merge
```

### 3. Rebase, Validate, Merge Workflow

For each MR, the Refinery follows a strict workflow:

```mermaid
flowchart TD
    Receive["Receive MR"]
    Rebase["Rebase onto latest main"]
    Conflict{"Conflicts?"}
    Validate["Run Validation"]
    Pass{"Passes?"}
    Merge["Merge to main"]
    Done["Mark Bead Complete"]
    SpawnCat["Spawn Fresh Polecat<br/>for Conflict Resolution"]
    Reject["Reject MR"]
    Retry["Re-queue for Retry"]

    Receive --> Rebase
    Rebase --> Conflict
    Conflict -->|No| Validate
    Conflict -->|Yes| SpawnCat
    SpawnCat --> Retry
    Validate --> Pass
    Pass -->|Yes| Merge
    Pass -->|No| Reject
    Merge --> Done
```

**Steps:**

1. **Rebase** -- Rebase the feature branch onto the latest `main`
2. **Conflict check** -- If conflicts exist, spawn a fresh polecat to resolve them
3. **Validate** -- Run tests, linting, build checks (configurable per rig)
4. **Merge** -- Fast-forward merge to `main`
5. **Mark complete** -- Update the bead status to done

### 4. Conflict Resolution

When a rebase produces conflicts, the Refinery does not attempt to resolve them itself. Instead, it spawns a fresh polecat with the conflict context:

```mermaid
flowchart LR
    Conflict["Merge Conflict<br/>Detected"]
    Spawn["Spawn Polecat<br/>with Context"]
    Resolve["Polecat Resolves<br/>Conflicts"]
    Resubmit["Polecat Submits<br/>New MR"]

    Conflict --> Spawn --> Resolve --> Resubmit
```

This separation of concerns keeps the Refinery focused on queue management while leveraging polecats for creative problem-solving.

### 5. Queue Management

The merge queue maintains ordering and handles retries:

| MR State | Description |
|----------|-------------|
| `queued` | Waiting to be processed |
| `processing` | Currently being rebased/validated |
| `merged` | Successfully merged to main |
| `rejected` | Failed validation, removed from queue |
| `conflict` | Conflicts detected, polecat spawned |
| `retry` | Re-queued after conflict resolution |

## Commands

| Command | Description |
|---------|-------------|
| `gt mq list` | List all MRs in the merge queue |
| `gt mq next` | Show the next MR to be processed |
| `gt mq submit` | Manually submit an MR to the queue |
| `gt mq status` | View merge queue status and metrics |
| `gt mq reject <id>` | Manually reject an MR |
| `gt mq retry <id>` | Re-queue a failed MR for retry |
| `gt mq integration` | Run integration validation across recent merges |

## Configuration

Refinery behavior is configured per-rig:

| Setting | Default | Description |
|---------|---------|-------------|
| Patrol interval | 5 min | Time between queue processing cycles |
| Validation command | `make test` | Command to validate before merge |
| Max retries | 2 | Maximum retry attempts for failed MRs |
| Conflict strategy | `spawn-polecat` | How to handle merge conflicts |
| Auto-merge | `true` | Whether to auto-merge passing MRs |
| Branch cleanup | `true` | Delete feature branches after merge |

## Refinery Location

The Refinery holds the **canonical clone** of the repository -- the authoritative copy from which merges to `main` happen:

```
~/gt/<rig>/refinery/rig/     # Canonical git clone
~/gt/<rig>/refinery/CLAUDE.md # Refinery agent context
```

All other clones (mayor, polecats, crew) are worktrees or separate clones that ultimately merge through the Refinery.

## Interaction Diagram

```mermaid
graph TD
    P1["Polecat: Toast"]
    P2["Polecat: Alpha"]
    P3["Polecat: Bravo"]
    R["Refinery"]
    Main["main branch"]
    W["Witness"]
    Conflict["Conflict Polecat"]

    P1 -->|"gt done (MR)"| R
    P2 -->|"gt done (MR)"| R
    P3 -->|"gt done (MR)"| R
    R -->|"rebase + validate"| Main
    R -->|"conflict"| Conflict
    Conflict -->|"resolved MR"| R
    W -->|monitors| R
```

## Tips and Best Practices

:::tip[Monitor the Merge Queue]

Use `gt mq list` and `gt mq status` to keep an eye on merge throughput. A growing queue may indicate validation failures or frequent conflicts.

:::

:::tip[Tune Validation]

Configure the validation command to run only the most critical checks. Full test suites can slow the queue significantly when many polecats are submitting simultaneously.

:::

:::tip[Use Integration Checks]

Run `gt mq integration` periodically to validate that recent merges interact correctly. This catches integration issues that per-MR validation might miss.

:::

:::warning[Do Not Push Directly to Main]

All changes should flow through the Refinery. Pushing directly to `main` bypasses validation and can cause rebase failures for queued MRs.

:::

:::info[One Refinery Per Rig]

Each rig has exactly one Refinery. Cross-rig merges are coordinated by Dogs and the Deacon, not by Refineries.


:::