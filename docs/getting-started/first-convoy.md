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

## Step 5: Watch the Merge Queue

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

## Using the Mayor Instead

For a more automated experience, attach to the Mayor and describe the work:

```bash
gt mayor attach
```

Then tell the Mayor:

> "Fix the login bug, add email validation to registration, and update the README with the new auth flow."

The Mayor handles convoy creation, issue tracking, and agent assignment automatically.

## Tips

- Use `gt convoy show` frequently to track progress
- If a polecat stalls, the Witness will detect and handle it
- Use `gt escalate` for issues that need human attention
- Convoys can span multiple rigs for cross-project work

:::note

Convoys auto-close when all tracked beads complete. You do not need to manually close them unless you want to cancel remaining work.

:::
