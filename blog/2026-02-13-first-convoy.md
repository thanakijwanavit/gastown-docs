---
title: "Your First Convoy in 5 Minutes"
description: "A quick walkthrough of creating beads, bundling a convoy, and watching polecats deliver code to main."
slug: first-convoy
authors: [gastown]
tags: [tutorial, getting-started]
---

A step-by-step walkthrough of the core Gas Town workflow: create beads, bundle them into a convoy, sling work to a rig, and watch polecats deliver code to `main`.

<!-- truncate -->

## Prerequisites

You'll need Gas Town installed and initialized with at least one rig. If you haven't done that yet, see the [Installation guide](/docs/getting-started/installation) and [Quick Start](/docs/getting-started/quickstart).

## Step 1: Create Your Beads

Beads are the atomic units of work in Gas Town. Each one is a trackable issue that an agent will pick up and implement.

```bash
# Create three focused tasks
bd create --title "Add input validation to /api/users" --type task --priority 1
# → Created: ga-a1b2c

bd create --title "Write unit tests for user validation" --type task --priority 2
# → Created: ga-d3e4f

bd create --title "Update API docs with validation rules" --type task --priority 2
# → Created: ga-g5h6i
```

Good beads are **specific and self-contained** — each one should be completable by a single polecat in one session.

## Step 2: Bundle Into a Convoy

A convoy groups related beads so you can track them as a batch:

```bash
gt convoy create "User validation" ga-a1b2c ga-d3e4f ga-g5h6i
# → Created convoy: hq-cv-001
```

The convoy tracks overall progress. When all three beads are done, the convoy auto-closes.

## Step 3: Sling Work to a Rig

Now send the beads to a rig where polecats will pick them up:

```bash
gt sling ga-a1b2c myproject
gt sling ga-d3e4f myproject
gt sling ga-g5h6i myproject
```

Each `sling` creates a polecat, assigns the bead to its hook, and starts execution. Within seconds, you'll have three polecats working in parallel.

```mermaid
sequenceDiagram
    participant Y as You
    participant MY as Mayor
    participant P as Polecats
    participant RF as Refinery
    Y->>MY: gt sling beads to rig
    MY->>P: Spawn 3 polecats
    P->>P: Implement + Test
    P->>RF: gt done (submit MRs)
    RF->>RF: Rebase + Merge to main
```

## Step 4: Watch It Happen

Monitor the convoy's progress:

```bash
# Live activity feed
gt feed

# Convoy progress
gt convoy status hq-cv-001

# Check individual polecat status
gt polecat list --rig myproject
```

You'll see polecats move through their molecule steps: loading context, setting up branches, running preflight tests, implementing, self-reviewing, and submitting.

:::info The `gt feed` Command Is Your Best Friend
During your first convoy, keep `gt feed` running in a separate terminal. It shows a real-time stream of events across all agents -- bead assignments, molecule step transitions, merge queue activity, and escalations. This live view is the fastest way to understand what Gas Town is actually doing under the hood.
:::

## Step 5: Code Lands on Main

As each polecat finishes, it runs `gt done` to submit a merge request. The Refinery picks up each MR, rebases onto latest `main`, runs validation, and merges. You'll see commits appearing on `main` within minutes.

```bash
# See what's been merged
cd ~/gt/myproject/crew/myname
git pull
git log --oneline -5
```

## What Just Happened?

```mermaid
flowchart LR
    A[Create Beads] --> B[Bundle Convoy]
    B --> C[Sling to Rig]
    C --> D[Polecats Execute]
    D --> E[Refinery Merges]
    E --> F[Code on Main]
```

In five minutes, you:

1. **Created** three focused work items (beads)
2. **Bundled** them into a tracked convoy
3. **Assigned** each to a parallel worker (polecat)
4. **Watched** autonomous implementation, testing, and merge
5. **Received** validated code on `main`

This is the core Gas Town loop. The Mayor can automate steps 1-3 for you (just describe what you want in natural language), but understanding the manual flow helps you debug and fine-tune later.

```mermaid
stateDiagram-v2
    [*] --> Created: bd create
    Created --> Bundled: gt convoy create
    Bundled --> Slung: gt sling
    Slung --> In_Progress: Polecat picks up
    In_Progress --> Submitted: gt done
    Submitted --> Merged: Refinery merges
    Merged --> [*]: Convoy auto-closes
```

```mermaid
pie title Time Breakdown for a Typical Convoy
    "Bead creation + bundling" : 5
    "Polecat context loading" : 10
    "Implementation" : 50
    "Testing + self-review" : 20
    "Refinery merge" : 15
```

## Behind the Scenes

When you sling a bead to a rig, several things happen automatically:

1. **Polecat spawning** — The Deacon creates a new tmux session, clones the repo into a fresh workspace under `polecats/`, and starts a Claude Code session
2. **Hook assignment** — The bead is placed on the polecat's hook via `gt mol attach`, so when the agent starts it immediately finds its work
3. **Molecule execution** — The polecat follows its molecule (workflow state machine), progressing through steps like context loading, implementation, testing, and self-review
4. **Merge request** — When done, `gt done` creates a merge request in the Refinery's queue
5. **Serialized merge** — The Refinery rebases the MR onto latest `main`, runs validation, and fast-forward merges

:::tip Understanding the pipeline
The key insight is that polecats never push directly to `main`. The Refinery serializes all merges, which is what prevents the merge conflicts that plague naive multi-agent setups. See the [Refinery Deep Dive](/blog/refinery-deep-dive) for the full story.
:::

:::note Polecats Never Push Directly to Main
All polecat work goes through the Refinery's merge queue. This serialized merge process is what prevents the merge conflicts that would otherwise plague parallel agents. Even if a polecat finishes its work instantly, the code still passes through rebase, validation, and fast-forward merge before appearing on `main`.
:::

:::caution Keep Beads Small and Focused
If a bead's scope is too large, the polecat may exhaust its context window before finishing the implementation. A good rule of thumb is that each bead should be completable in a single agent session — if you find yourself writing more than two sentences to describe it, consider splitting it into multiple beads with explicit dependencies.
:::

## Troubleshooting Your First Convoy

A few things that might go wrong on your first run:

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| Polecat never starts | Rig not initialized | Run `gt rig init` first |
| Polecat stalls at "loading context" | Missing `CLAUDE.md` or large repo | Add project instructions, check clone size |
| Merge rejected by Refinery | Tests fail on rebase | Check `gt mq list`, read the failure log |
| Convoy stuck at partial completion | One polecat errored | Check `gt feed`, re-sling the failed bead |

For deeper troubleshooting, see the [Troubleshooting guide](/docs/operations/troubleshooting) and the [Common Pitfalls](/blog/common-pitfalls) blog post.

## Scaling Beyond Your First Convoy

Once you've run a manual convoy successfully, you're ready to let the Mayor take over. Instead of creating beads and slinging them yourself, just describe what you want:

```bash
gt mayor "Add user validation to the API with unit tests and docs"
```

The Mayor will decompose your request into right-sized beads, set up dependencies between them, bundle a convoy, and sling work to the appropriate rig — all automatically. This is where Gas Town starts to feel like a superpower.

## Next Steps

- **[Mayor Workflow](/docs/workflows/mayor-workflow)** — Let the Mayor handle decomposition and assignment automatically
- **[Crew Collaboration](/docs/workflows/crew-collaboration)** — Work alongside polecats in real-time
- **[Convoys](/docs/concepts/convoys)** — Deep dive into batch tracking and cross-rig convoys
- **[GUPP & NDI](/docs/concepts/gupp)** — Understand why crashes don't lose work
- **[Session Cycling](/docs/concepts/session-cycling)** — How agents maintain continuity across restarts
- **[Your Second Convoy](/blog/your-second-convoy)** — Level up with dependencies and cross-rig coordination
- **[Work Distribution Patterns](/blog/work-distribution-patterns)** — When to use convoys vs Mayor vs formula workflows
- **[Common Pitfalls](/blog/common-pitfalls)** — Avoid the 5 most common mistakes with your first convoy
- [First Convoy Tutorial](/docs/getting-started/first-convoy) — Step-by-step guide to running your first convoy
