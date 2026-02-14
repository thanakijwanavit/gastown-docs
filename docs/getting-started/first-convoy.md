---
title: "Your First Convoy"
sidebar_position: 3
description: "A Convoy is Gas Town's primary unit for tracking batches of related work. This walkthrough takes you through creating and monitoring your first convoy."
---

# Your First Convoy

A **Convoy** is Gas Town's primary unit for tracking batches of related work. This walkthrough takes you through creating and monitoring your first convoy.

## Step 1: Create Issues

First, create some beads (issues) to track:

```bash
bd create --title "Fix login bug" --type bug --priority high
# Created: gt-a1b2c

bd create --title "Add email validation" --type feature
# Created: gt-d3e4f

bd create --title "Update README" --type task
# Created: gt-g5h6i
```

## Step 2: Create a Convoy

Bundle the issues into a convoy:

```bash
gt convoy create "Auth System Fixes" gt-a1b2c gt-d3e4f gt-g5h6i
# Created: hq-cv-xyz
```

## Step 3: Assign Work

Use `gt sling` to assign issues to workers:

```bash
# Assign to a rig (auto-spawns a polecat)
gt sling gt-a1b2c myproject
gt sling gt-d3e4f myproject
gt sling gt-g5h6i myproject
```

Each `gt sling` command:

1. Hooks the bead to the target agent
2. Spawns a polecat worker in the rig
3. The polecat picks up the work immediately

:::tip

You can sling all three at once — each gets its own polecat working in parallel:

```bash
gt sling gt-a1b2c gt-d3e4f gt-g5h6i myproject
```

:::

## Step 4: Monitor Progress

```bash
# Check convoy status
gt convoy list
gt convoy show hq-cv-xyz

# Watch the activity feed
gt feed

# Check individual polecat status
gt polecat list
```

```mermaid
stateDiagram-v2
    [*] --> Pending: bd create
    Pending --> Hooked: gt sling
    Hooked --> InProgress: Polecat starts work
    InProgress --> Done: gt done
    Done --> Merged: Refinery merges
    Merged --> [*]
    InProgress --> Pending: Polecat crashes (auto-recovery)
```

## Step 5: Watch the Merge Queue

```mermaid
flowchart LR
    PC1["Polecat 1\n(done)"] -->|submit MR| MQ["Merge Queue"]
    PC2["Polecat 2\n(done)"] -->|submit MR| MQ
    PC3["Polecat 3\n(done)"] -->|submit MR| MQ
    MQ -->|one at a time| REF["Refinery"]
    REF -->|rebase + test| MAIN["main branch"]
```

As polecats complete work, they submit merge requests to the Refinery:

```bash
# View merge queue
gt mq list

# Check merge status
gt mq status
```

The Refinery:

1. Picks up the next MR
2. Rebases onto latest main
3. Runs validation (tests, builds)
4. Merges if clean
5. If conflict: spawns a fresh polecat to resolve

## Step 6: Convoy Completion

When all tracked issues are done, the convoy auto-closes:

```bash
gt convoy list
# hq-cv-xyz  Auth System Fixes  [COMPLETED]  3/3 done
```

:::info
You can check which polecats are available in a rig before slinging work with `gt polecat list`. If all polecat slots are occupied, new sling commands will queue until a slot opens up.
:::

:::danger[Do Not Sling to Docked Rigs]

Attempting to sling work to a docked or stopped rig will silently fail -- the bead will be marked as hooked but no polecat will spawn to execute it. Always verify the rig is active with `gt rig list` before slinging work.

:::

## Using the Mayor Instead

For a more automated experience, attach to the Mayor and describe the work. For complete details on the Mayor's strategic coordination capabilities, see [The Mayor Workflow](/blog/mayor-workflow).

```bash
gt mayor attach
```

Then tell the Mayor:

> "Fix the login bug, add email validation to registration, and update the README with the new auth flow."

The Mayor handles convoy creation, issue tracking, and agent assignment automatically.

## What Happens Behind the Scenes

Understanding the full flow helps when debugging issues:

```mermaid
sequenceDiagram
    participant You as You (Human)
    participant GT as gt CLI
    participant Rig as Rig (myproject)
    participant PC as Polecat (spawned)
    participant Ref as Refinery

    You->>GT: gt sling gt-a1b2c myproject
    GT->>Rig: Hook bead to new polecat
    Rig->>PC: Spawn polecat in worktree
    PC->>PC: gt prime → gt hook → EXECUTE
    PC->>PC: Work on issue (code, test, commit)
    PC->>Ref: gt done → Submit MR
    Ref->>Ref: Rebase, validate, merge
    Ref->>Rig: Merged to main
    Note over Rig: Polecat worktree nuked
```

Each polecat:
1. Gets its own isolated git worktree (no conflicts with other polecats)
2. Reads the bead from its hook to understand the task
3. Executes a molecule (workflow template) that guides its work
4. Submits to the Refinery when done, which merges to main serially

## Convoy Progress Overview

A convoy tracks the aggregate state of all its beads, providing a single dashboard view.

```mermaid
graph TD
    CV["Convoy: hq-cv-xyz<br/>Auth System Fixes"]
    CV --> B1["gt-a1b2c<br/>Fix login bug"]
    CV --> B2["gt-d3e4f<br/>Email validation"]
    CV --> B3["gt-g5h6i<br/>Update README"]
    B1 --> D1["DONE"]
    B2 --> D2["IN PROGRESS"]
    B3 --> D3["PENDING"]
    style D1 fill:#2d5a2d
    style D2 fill:#5a5a2d
    style D3 fill:#5a2d2d
```

:::caution[Convoy Creation Timing]

Create the convoy before slinging work, not after. If you sling beads first and then create a convoy, the convoy cannot track work that is already in progress. The recommended order is: create beads, create convoy, then sling beads.

:::

:::tip[Your First Convoy Should Be Simple]

For your very first convoy, choose 2-3 small, independent tasks that touch different files. This reduces merge conflicts and lets you focus on learning the workflow rather than debugging interactions. Save complex multi-file refactors for your second or third convoy.

:::

## Common First-Convoy Issues

| Problem | Cause | Fix |
|---------|-------|-----|
| Polecat not starting | No free slots in rig | Check `gt polecat list` — rig may be at max capacity |
| Work not progressing | Polecat confused by bead description | Add more detail: `bd update gt-a1b2c --description "..."` |
| Merge conflict | Two polecats touched same files | Refinery handles this — it spawns a resolution polecat |
| Convoy stuck at 2/3 | One polecat stalled | Check `gt polecat list` and `gt feed` for errors |

```mermaid
pie title First Convoy Common Issues
    "Polecat not starting (slots full)" : 30
    "Vague bead descriptions" : 25
    "Merge conflicts" : 20
    "Stalled polecats" : 15
    "Convoy created after slinging" : 10
```

:::warning
Write detailed bead descriptions. Vague descriptions like "fix the bug" force polecats to waste context figuring out what to do. Include the specific behavior, where it occurs, and what the expected outcome should be.
:::

## Tips

- Use `gt convoy show` frequently to track progress
- If a polecat stalls, the Witness will detect and handle it
- Use `gt escalate` for issues that need human attention
- Convoys can span multiple rigs for cross-project work

:::note

Convoys auto-close when all tracked beads complete. You do not need to manually close them unless you want to cancel remaining work.

:::

### First Convoy Step-by-Step

The six steps to creating and completing your first convoy follow a clear progression.

```mermaid
graph LR
    S1["Step 1<br/>Create Issues"] --> S2["Step 2<br/>Create Convoy"]
    S2 --> S3["Step 3<br/>Sling Work"]
    S3 --> S4["Step 4<br/>Monitor Progress"]
    S4 --> S5["Step 5<br/>Merge Queue"]
    S5 --> S6["Step 6<br/>Convoy Completes"]
```

## Related

- [Convoys](../concepts/convoys.md) -- Full documentation of convoy tracking, dependencies, and auto-close
- [Beads](../concepts/beads.md) -- The atomic work units that convoys track through the system
- [Manual Convoy Workflow](../workflows/manual-convoy.md) -- Advanced convoy patterns with cross-rig coordination
- [Mayor Workflow](../workflows/mayor-workflow.md) -- Let the Mayor handle convoy creation and assignment automatically

### Blog Posts

- [Your First Convoy](/blog/first-convoy) -- Blog walkthrough with tips and real-world examples
- [The Mayor Workflow](/blog/mayor-workflow) -- How to let the Mayor automate convoy creation and assignment
- [Your Second Convoy](/blog/your-second-convoy) -- Dependencies, cross-rig work, and stuck polecat recovery
- [Advanced Convoy Patterns](/blog/advanced-convoy-patterns) -- Parallel dispatch, wave-based execution, and cross-rig convoys for when you're ready to level up
- [Work Distribution Patterns: Manual Convoy vs. Mayor vs. Formula](/blog/work-distribution-patterns) -- Understanding how convoys fit into the larger work distribution landscape
