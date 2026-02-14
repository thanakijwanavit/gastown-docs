---
title: "Infrastructure Dogs: The Cleanup Crew Behind Gas Town"
description: "How Dogs handle cross-rig infrastructure work — cleanup, syncing, migrations, and rebuilding — while polecats focus on features."
slug: infrastructure-dogs
authors: [gastown]
tags: [agents, architecture, operations, concepts]
---

Polecats build features. Dogs clean up messes. This division of labor is fundamental to Gas Town's architecture, but Dogs are often misunderstood. They're not lesser agents — they're the infrastructure backbone that keeps the town running while polecats focus on shipping code.

<!-- truncate -->

## Why Dogs Exist

In a system with 10+ agents running across multiple rigs, infrastructure problems accumulate fast:

- Orphaned worktrees from crashed polecats eating disk space
- Stale branches from abandoned work cluttering repositories
- Configuration drift between rigs after manual edits
- Corrupted beads databases from interrupted writes
- Temp files from build processes nobody cleaned up

These problems don't belong to any single rig or feature. They span the entire town. Polecats can't handle them — they're scoped to one rig and one task. The [Witness](/docs/agents/witness) monitors health but doesn't do manual labor. The [Deacon](/docs/agents/deacon) coordinates but needs workers. For more on the Deacon's role, see [deacon patrol](/blog/deacon-patrol).

Enter Dogs. They're the infrastructure specialists that handle the messy cross-cutting work that doesn't belong to any single feature or rig.

## Dogs vs. Polecats

The distinction is clean and absolute:

```mermaid
graph LR
    subgraph "Polecats"
        P1[Single rig scope]
        P2[One task, then done]
        P3[Submits MRs]
        P4[Has git identity]
        P5[Managed by Witness]
    end

    subgraph "Dogs"
        D1[Cross-rig scope]
        D2[Reusable for multiple tasks]
        D3[Rarely submits MRs]
        D4[No git identity]
        D5[Managed by Deacon]
    end
```

```mermaid
flowchart TD
    subgraph "Task Routing Decision"
        TASK[New Task] --> Q{Task Type?}
        Q -->|Feature/Bug Fix| POL[Route to Polecat]
        Q -->|Cross-Rig Cleanup| DOG[Route to Dog]
        Q -->|Config Sync| DOG
        Q -->|Schema Migration| DOG
        Q -->|Code Change| POL
        POL --> MR[Submits MR]
        DOG --> RPT[Reports to Deacon]
        MR --> MAIN[Code on Main]
        RPT --> NEXT[Returns to Pool]
    end
    style POL fill:#cce5ff
    style DOG fill:#ffe5cc
```

The rule of thumb: **if the work produces a feature branch and a merge request, it's a polecat. If the work maintains infrastructure, it's a dog.**

## What Dogs Do

### Cross-Rig Cleanup

The most common dog task. When the Deacon detects orphaned resources across rigs, it dispatches a dog to clean them all:

```text
Dog receives: "Clean orphaned worktrees across all rigs"
  → Scan rig 1: Remove 3 orphaned directories
  → Scan rig 2: Remove 1 orphaned directory
  → Report results to Deacon
  → Return to idle pool
```

### Configuration Syncing

When a shared configuration changes, a dog propagates it:

```text
Dog receives: "Sync .editorconfig to all rigs"
  → Read canonical config from template
  → Apply to rig 1, rig 2, rig 3
  → Verify consistency
  → Report diffs if any rig needed changes
```

:::info[Cross-Rig Operations Require Town-Level Beads Access]
Unlike polecats which operate within a single rig's beads database, dogs have access to the town-level `.beads/` directory for tracking cross-rig work. This is why dog operations can coordinate state across all rigs — they bypass rig boundaries and work at the infrastructure layer where all rigs are visible.
:::

### System Rebuilding

When infrastructure breaks, dogs rebuild it:

- Recreating corrupted worktrees
- Re-initializing beads databases after schema changes
- Rebuilding agent context files after format updates
- Restoring state from backups

:::info Dogs Report Results to the Deacon, Not to You
Dogs do not surface their output directly to the operator. When a dog completes a cross-rig cleanup or migration, it reports results to the Deacon, which aggregates them into its patrol digest. Check the Deacon's patrol summary with `gt deacon digest` to see what infrastructure work was performed and whether any tasks failed.
:::

### Migrations

When Gas Town itself updates, dogs handle the transition:

- Schema migrations for the beads database
- Configuration format updates across all rigs
- Plugin upgrades that need cross-rig coordination

```mermaid
flowchart TD
    UPD[Gas Town Update Released] --> SM[Schema Migration]
    UPD --> CF[Config Format Update]
    UPD --> PU[Plugin Upgrade]
    SM --> R1[Apply to Rig 1 DB]
    SM --> R2[Apply to Rig 2 DB]
    CF --> R1V[Update Rig 1 Configs]
    CF --> R2V[Update Rig 2 Configs]
    PU --> R1P[Upgrade Rig 1 Plugins]
    PU --> R2P[Upgrade Rig 2 Plugins]
    R1 & R2 & R1V & R2V & R1P & R2P --> VER[Verify Consistency]
    VER --> RPT[Report to Deacon]
```

## Dog Task Types at a Glance

| Task Type | Description | Example Commands / Actions | Typical Duration | Frequency |
|---|---|---|---|---|
| **Cross-rig cleanup** | Remove orphaned worktrees, stale branches, and temp files across all rigs | `gt cleanup --all-rigs`; scan each rig for orphaned directories; report totals to Deacon | 1-3 minutes | Multiple times daily (triggered by Deacon patrol) |
| **Configuration sync** | Propagate shared config changes to every rig | Read canonical template; apply `.editorconfig`, linter configs, or shared settings to each rig; verify consistency | 30 seconds - 2 minutes | On config change (event-driven) |
| **System rebuild** | Recreate corrupted infrastructure components | Rebuild worktrees, re-initialize beads databases, restore agent context files from backups | 2-10 minutes | Rare (after crashes or corruption) |
| **Schema migration** | Update data formats when Gas Town itself upgrades | Migrate beads database schema; update config file formats; upgrade plugin manifests across all rigs | 5-15 minutes | Per Gas Town release (infrequent) |
| **Warrant processing** | Execute death warrants for stuck agents (Boot only) | Read pending warrants; terminate stuck polecats or dogs; clean up their resources | 10-30 seconds per warrant | Every daemon tick (continuous) |

:::tip Dogs Are Reusable Across Sequential Tasks
Unlike polecats which are one-and-done (spawn, work, submit, die), dogs return to the idle pool after completing a task and can be reused for the next infrastructure job. This makes them more efficient for batch operations like cleaning orphaned worktrees across all rigs — a single dog handles the entire sweep rather than spawning a new agent for each rig.
:::

## The Deacon-Dog Relationship

Dogs don't operate independently. The [Deacon](/docs/agents/deacon) manages their entire lifecycle:

```mermaid
sequenceDiagram
    participant Dc as Deacon
    participant Dog as Dog
    participant R1 as Rig 1
    participant R2 as Rig 2

    Dc->>Dc: Patrol detects orphaned worktrees
    Dc->>Dog: Spawn with cleanup task
    Dog->>R1: Clean 3 orphaned directories
    Dog->>R2: Clean 1 orphaned directory
    Dog->>Dc: Report: 4 items cleaned
    Dc->>Dog: Assign next task (sync configs)
    Dog->>R1: Apply config update
    Dog->>R2: Apply config update
    Dog->>Dc: Report: configs synced
    Dc->>Dog: No more work → return to idle pool
```

The Deacon:
1. **Spawns** dogs when infrastructure work accumulates
2. **Assigns** tasks with clear scope and completion criteria
3. **Monitors** progress and applies timeouts
4. **Reuses** dogs for sequential tasks (unlike polecats which are one-and-done)
5. **Warrants** stuck dogs that exceed their timeout

## Boot: The Special Dog

[Boot](/docs/agents/boot) is a specialized dog with a unique lifecycle. Unlike regular dogs that the Deacon spawns on demand, Boot runs fresh on every daemon tick. Its primary job is processing [death warrants](/docs/cli-reference/warrant) — the structured cleanup requests for stuck agents.

Boot doesn't sit in the idle pool. It spawns, processes warrants, and exits. Think of it as the town's janitor who does a sweep every few minutes rather than waiting for a dispatch.

:::warning Never Use Dogs for Feature Work
Dogs bypass the merge queue and code review process entirely. If you need a feature implemented, sling it to a polecat via `gt sling`. The rule of thumb: if the work produces a feature branch and a merge request, it belongs to a polecat. Dogs are strictly for infrastructure maintenance.
:::

:::caution Dogs Cannot Access Parked or Docked Rigs
If a rig is parked or docked, dogs dispatched for cross-rig operations will skip it silently or fail. Before running infrastructure-wide sweeps like orphaned worktree cleanup or configuration syncing, verify all target rigs are active with `gt rig list`. Unpark any rigs that need to be included in the maintenance operation.
:::

```mermaid
stateDiagram-v2
    [*] --> Idle: Dog in Pool
    Idle --> Assigned: Deacon Dispatches Task
    Assigned --> Working: Scanning Rigs
    Working --> Reporting: Task Complete
    Reporting --> Idle: Return to Pool
    Reporting --> Warranted: Timeout Exceeded
    Warranted --> Terminated: Boot Processes Warrant
    Terminated --> [*]
```

## Anti-Patterns

**Don't use dogs for feature work.** Dogs bypass the merge queue and code review process. If you need a feature implemented, sling it to a polecat via `gt sling`.

**Don't manually spawn dogs for routine work.** The Deacon handles dog lifecycle automatically. Manual dog creation (`gt dog add`) should be reserved for emergencies.

**Don't confuse dogs with cross-rig polecats.** If you need to work on another rig's codebase as a crew member, use `gt worktree` to create a worktree in the target rig. Dogs are for infrastructure, not development.

## Troubleshooting

### No Idle Dogs Available

If the Deacon has work queued but no dogs to dispatch:

```bash
gt dog list                # See active dogs
gt dog add emergency-dog   # Manually add one
```

The Deacon should auto-spawn, but if it's down or overloaded, manual intervention helps.

### Dog Stuck on a Task

Dogs that exceed their timeout get death warrants from the Deacon:

```bash
gt dog list                # Look for "warrant pending" status
gt dog status <id>         # Check what it's stuck on
```

Boot will process the warrant on the next daemon tick.

### Infrastructure Task Not Completing

If a cross-rig cleanup or migration seems to hang, check whether the dog has access to all target rigs:

```bash
gt rig list                # Are all target rigs active?
gt rig status <rig>        # Is any rig parked or docked?
```

Parked or docked rigs block dog operations. Unpark them first with `gt rig unpark <rig>` before retrying the infrastructure task.

## Next Steps

- [Dogs Documentation](/docs/agents/dogs) — Full reference for dog types, commands, and patterns
- [Boot Agent](/docs/agents/boot) — The specialized dog for warrant processing
- [Deacon Documentation](/docs/agents/deacon) — How the Deacon manages the dog pool
- [The Deacon: Gas Town's Background Coordinator](/blog/deacon-patrol) — Deep dive into the Deacon's patrol cycle
- [Death Warrants: Structured Agent Termination](/blog/death-warrants) — How warrants handle stuck dogs and polecats
- [Boot Dogs: The Triage Engine](/blog/boot-dogs) — How Boot performs initial triage before dispatching infrastructure dogs
- [Lifecycle Management](/blog/lifecycle-management) — How rig lifecycle states affect dog operations and infrastructure maintenance
- [Agent CLI Reference](/docs/cli-reference/agents) — Commands for listing, inspecting, and managing all agent types
- [Orphan CLI Reference](/docs/cli-reference/orphans) — Commands for finding and cleaning orphaned resources
