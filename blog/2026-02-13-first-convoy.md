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

## Step 5: Code Lands on Main

As each polecat finishes, it runs `gt done` to submit a merge request. The Refinery picks up each MR, rebases onto latest `main`, runs validation, and merges. You'll see commits appearing on `main` within minutes.

```bash
# See what's been merged
cd ~/gt/myproject/crew/myname
git pull
git log --oneline -5
```

## What Just Happened?

In five minutes, you:

1. **Created** three focused work items (beads)
2. **Bundled** them into a tracked convoy
3. **Assigned** each to a parallel worker (polecat)
4. **Watched** autonomous implementation, testing, and merge
5. **Received** validated code on `main`

This is the core Gas Town loop. The Mayor can automate steps 1-3 for you (just describe what you want in natural language), but understanding the manual flow helps you debug and fine-tune later.

## Next Steps

- **[Mayor Workflow](/docs/workflows/mayor-workflow)** — Let the Mayor handle decomposition and assignment automatically
- **[Crew Collaboration](/docs/workflows/crew-collaboration)** — Work alongside polecats in real-time
- **[Convoys](/docs/concepts/convoys)** — Deep dive into batch tracking and cross-rig convoys
- **[GUPP & NDI](/docs/concepts/gupp)** — Understand why crashes don't lose work
- **[Your Second Convoy](/blog/your-second-convoy)** — Level up with dependencies and cross-rig coordination
- **[Work Distribution Patterns](/blog/work-distribution-patterns)** — When to use convoys vs Mayor vs formula workflows
