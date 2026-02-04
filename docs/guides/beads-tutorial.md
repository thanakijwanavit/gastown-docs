---
title: "Beads Tutorial"
sidebar_position: 7
description: "A hands-on tutorial for using the Beads issue tracking system. Learn to create, track, and manage work items through the bd CLI with practical examples."
---

# Beads Tutorial

This tutorial walks through the Beads issue tracking system with practical examples. By the end, you will be able to create beads, track them through their lifecycle, use priorities and dependencies, and understand how beads fit into the larger Gas Town workflow.

For the concept overview, see [Beads (Issue Tracking)](/docs/concepts/beads/). For the full command reference, see [Work Management CLI](/docs/cli-reference/work/).

---

## Getting Started

Beads is managed through the `bd` CLI. Every rig in Gas Town has its own `.beads/` directory with a SQLite database.

### Check System Health

```bash
# Verify beads is working
bd doctor

# See available work
bd ready

# See all open issues
bd list --status=open
```

---

## Creating Beads

### Basic Creation

The simplest way to create a bead:

```bash
bd create --title "Fix login timeout issue"
```

This creates a bead with default type (`task`), default priority (`P2`), and `pending` status.

### Specifying Type and Priority

Every bead has a **type** and a **priority**:

```bash
# Bug with high priority
bd create --title "Login fails with special characters" --type bug --priority 1

# Feature request, medium priority
bd create --title "Add email notifications" --type feature --priority 2

# Low-priority task
bd create --title "Clean up test fixtures" --type task --priority 3
```

**Types:**

| Type | When to Use |
|------|------------|
| `task` | General work items, refactoring, chores |
| `bug` | Something is broken |
| `feature` | New functionality |
| `epic` | Large initiative containing sub-tasks |

**Priorities:**

| Code | Level | Meaning |
|------|-------|---------|
| P0 | Critical | System down, data loss risk |
| P1 | High | Major functionality broken |
| P2 | Medium | Default; degraded but workable |
| P3 | Low | Cosmetic, minor, or nice-to-have |
| P4 | Backlog | Track for later |

:::warning

Priority values are numeric (0-4), not strings. Use `--priority 0` not `--priority critical`.

:::

### Adding Description and Labels

```bash
bd create \
  --title "Implement OAuth2 flow" \
  --type feature \
  --priority 1 \
  --description "Replace basic auth with OAuth2. Support Google and GitHub providers." \
  --label "auth,security"
```

---

## Viewing and Filtering Beads

### Listing Beads

```bash
# All open beads
bd list --status=open

# All beads in progress
bd list --status=in_progress

# All bugs
bd list --type=bug

# Ready work (no blockers, not assigned)
bd ready
```

### Showing Bead Details

```bash
bd show gt-abc12
```

Sample output:

```
? gt-abc12 · Fix login timeout issue   [? P1 · IN_PROGRESS]
Owner: mayor · Assignee: polecat/toast · Type: bug
Created: 2026-02-03 · Updated: 2026-02-04

DESCRIPTION
Login times out after 30s when server is under load.
Increase timeout and add retry logic.
```

### Finding Your Work

```bash
# What's on your hook? (for agents)
gt hook

# What's ready to be picked up?
bd ready

# What's blocked?
bd blocked
```

---

## The Bead Lifecycle

Beads progress through a defined set of states:

```
pending → open → in_progress → hooked → done
```

### State Transitions

| From | To | How | Who |
|------|-----|-----|-----|
| `pending` | `open` | `bd update <id> --status=open` | Agent or human claims it |
| `open` | `in_progress` | `bd update <id> --status=in_progress` | Agent starts work |
| `in_progress` | `hooked` | `gt sling <id> <rig>` | Mayor assigns to polecat |
| `hooked` | `in_progress` | Polecat picks up work | Automatic on spawn |
| `in_progress` | `done` | `bd close <id>` | Agent completes work |

### Practical Workflow

Here is the typical flow for working on a bead:

```bash
# 1. Find available work
bd ready

# 2. Review the issue
bd show gt-abc12

# 3. Claim it
bd update gt-abc12 --status=in_progress

# 4. Do the work
# ... write code, run tests ...

# 5. Mark complete
bd close gt-abc12

# 6. Sync state
bd sync --flush-only
```

For polecats (autonomous agents), steps 1-3 happen automatically when work is slung to them. The polecat's startup protocol checks the hook and begins work immediately.

---

## Updating Beads

### Changing Status

```bash
bd update gt-abc12 --status=in_progress
```

### Adding Notes and Context

Use `--notes` to record progress or context:

```bash
bd update gt-abc12 --notes "Fixed the parser. Need to update tests next."
```

### Reassigning

```bash
bd update gt-abc12 --assignee=polecat/toast
```

### Closing with Context

Always provide a reason when closing to leave a trail for future reference:

```bash
bd close gt-abc12 --reason="Fixed in commit abc1234. Timeout increased to 60s with retry."
```

Close multiple beads at once:

```bash
bd close gt-abc12 gt-def34 gt-ghi56
```

---

## Dependencies and Blocking

Beads can depend on other beads. A blocked bead cannot be worked on until its dependencies are resolved.

### Adding Dependencies

```bash
# "Deploy to prod" depends on "Write migration script"
bd dep add gt-deploy gt-migration
```

:::tip[Think "X needs Y"]

The syntax is `bd dep add <issue> <depends-on>`. Read it as: "issue **needs** depends-on to be done first."

Common mistake: thinking temporally ("Phase 1 before Phase 2") instead of in terms of requirements ("Phase 2 **needs** Phase 1").

:::

### Checking What's Blocked

```bash
# Show all blocked beads
bd blocked

# Show what blocks a specific bead
bd show gt-deploy
```

### Unblocking

When you close a dependency, the dependent bead automatically becomes unblocked:

```bash
# Close the migration script bead
bd close gt-migration --reason="Migration script tested and ready"

# Now gt-deploy is unblocked and appears in bd ready
bd ready
```

### Dependency Chains

Dependencies can chain. If A depends on B and B depends on C, then A is blocked until both B and C are complete:

```bash
bd create --title "Deploy to prod"           # gt-deploy
bd create --title "Run integration tests"    # gt-tests
bd create --title "Write migration script"   # gt-migration

bd dep add gt-deploy gt-tests      # Deploy needs tests
bd dep add gt-tests gt-migration   # Tests need migration

# Only gt-migration is ready to work on
bd ready
# -> gt-migration

# After closing gt-migration, gt-tests becomes ready
bd close gt-migration
bd ready
# -> gt-tests

# After closing gt-tests, gt-deploy becomes ready
bd close gt-tests
bd ready
# -> gt-deploy
```

---

## Working with Convoys

A **convoy** groups related beads for coordinated tracking. When the Mayor creates a batch of work (like "implement feature X"), it creates a convoy to track all the pieces together.

### How Convoys Work

Convoys are themselves beads (type: `convoy`) that contain references to their member beads. The convoy tracks overall progress: how many members are done, how many are in progress, and how many are blocked.

```bash
# View convoy details
gt convoy show hq-cv-001

# List all active convoys
gt convoy list

# Find stranded convoys (with unassigned work)
gt convoy stranded
```

### Convoy Lifecycle

1. **Mayor creates** a convoy with member beads
2. **Beads are slung** to rigs for execution
3. **Polecats work** on individual beads
4. **Convoy tracks** overall progress
5. **When all members close**, the convoy completes

You typically do not create convoys manually -- the Mayor handles this. But understanding convoys helps when monitoring work progress or debugging stalled pipelines.

---

## Wisps and Molecules

### Wisps

A **wisp** is an ephemeral bead used as a step in a molecule (multi-step workflow). Wisps are created automatically when a molecule runs and are closed as each step completes.

You rarely interact with wisps directly. They appear in `bd list` output with type `wisp` and are associated with their parent molecule.

### Molecules

A **molecule** is a multi-step workflow defined by a formula. Each step becomes a wisp bead:

```bash
# Check your workflow steps
bd ready

# Shows something like:
#   mol-abc.step-1: Set up environment     [ready]
#   mol-abc.step-2: Implement feature      [blocked by step-1]
#   mol-abc.step-3: Write tests            [blocked by step-2]
```

Polecats follow molecule steps sequentially:

```bash
# Work on current step
bd show mol-abc.step-1

# Mark step complete
bd close mol-abc.step-1

# Next step becomes ready
bd ready
# -> mol-abc.step-2
```

When all steps are done, the molecule is automatically squashed and closed.

For more on molecules, see [Molecules & Formulas](/docs/concepts/molecules/).

---

## Common Patterns

### Filing a Bug You Discovered

While working on a task, you discover a bug in different code:

```bash
# File it in the rig that owns the code
bd create --title "Race condition in cache invalidation" \
  --type bug \
  --priority 1 \
  --description "Found while working on gt-abc12. The cache TTL expires mid-request."

# Continue with your original task
```

### Splitting a Large Task

If a task turns out to be larger than expected, split it:

```bash
# Create sub-tasks
bd create --title "Refactor auth: extract token service" --type task --priority 2
bd create --title "Refactor auth: add token rotation" --type task --priority 2
bd create --title "Refactor auth: update tests" --type task --priority 2

# Set dependencies
bd dep add gt-rotation gt-extract    # Rotation needs extract done first
bd dep add gt-tests gt-rotation      # Tests need rotation done first
```

### Escalating a Blocker

When you hit something you cannot resolve:

```bash
gt escalate "Need API credentials for staging" -s HIGH -m "Issue: gt-abc12
Tried: checked .env files, asked in mail
Need: staging API key from infra team"
```

### Checking Project Health

```bash
# How many issues are open?
bd stats

# What's blocked?
bd blocked

# What's ready to work on?
bd ready
```

---

## Quick Reference

| Command | Purpose |
|---------|---------|
| `bd create --title "..." --type task` | Create a new bead |
| `bd list --status=open` | List open beads |
| `bd show <id>` | View bead details |
| `bd ready` | Find available work |
| `bd update <id> --status=in_progress` | Claim work |
| `bd close <id>` | Mark work complete |
| `bd close <id1> <id2> ...` | Close multiple beads |
| `bd blocked` | Show blocked beads |
| `bd dep add <issue> <depends-on>` | Add a dependency |
| `bd stats` | Project statistics |
| `bd sync --flush-only` | Export state to JSONL |
| `bd doctor` | Check database health |

---

## Next Steps

- **[Beads Concept Guide](/docs/concepts/beads/)** -- Deeper dive into architecture and design
- **[Work Management CLI](/docs/cli-reference/work/)** -- Full command reference for `bd` and `gt` work commands
- **[Hooks](/docs/concepts/hooks/)** -- How hooks connect beads to agents
- **[Convoys](/docs/concepts/convoys/)** -- Coordinated batch tracking
- **[Molecules & Formulas](/docs/concepts/molecules/)** -- Multi-step workflow automation
