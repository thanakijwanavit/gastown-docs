---
title: "Convoy & Tracking"
sidebar_position: 4
description: "CLI reference for creating, tracking, and managing convoys that bundle related beads with auto-close and synthesis."
---

# Convoy & Tracking

Convoys are Gas Town's primary mechanism for bundling and tracking batches of related work. A convoy groups multiple beads together, monitors their collective progress, and auto-closes when all tracked items complete.

---

## `gt convoy create`

Create a new convoy.

```bash
gt convoy create <title> [bead-id...] [options]
```

**Description:** Creates a new convoy with an optional set of initial beads. Convoys are the standard unit for tracking a batch of related work such as a feature set, a bug-fix sprint, or a documentation effort.

**Options:**

| Flag | Description |
|------|-------------|
| `--description <text>` | Detailed convoy description |
| `--rig <name>` | Associate with a specific rig |
| `--priority <level>` | Set convoy priority: `critical`, `high`, `medium`, `low` |
| `--deadline <date>` | Set a target completion date |

**Example:**

```bash
# Create with initial beads
gt convoy create "Auth System Fixes" gt-a1b2c gt-d3e4f gt-g5h6i
# Created: hq-cv-001

# Create empty convoy (add beads later)
gt convoy create "Q1 Performance Sprint" --priority high

# Create with description
gt convoy create "API Refactor" --description "Migrate all endpoints from v1 to v2 schema"
```

---

## `gt convoy add`

Add beads to an existing convoy.

```bash
gt convoy add <convoy-id> <bead-id>... [options]
```

**Description:** Adds one or more beads to an existing convoy. The convoy's completion tracking updates automatically.

**Example:**

```bash
# Add a single bead
gt convoy add hq-cv-001 gt-j7k8l

# Add multiple beads
gt convoy add hq-cv-001 gt-j7k8l gt-m9n0o gt-p1q2r
```

:::tip

Beads can belong to multiple convoys. This is useful when a single fix addresses multiple work streams.

:::

---

## `gt convoy list`

List all convoys.

```bash
gt convoy list [options]
```

**Options:**

| Flag | Description |
|------|-------------|
| `--status <status>` | Filter: `active`, `completed`, `stalled`, `cancelled` |
| `--rig <name>` | Filter to a specific rig |
| `--limit <n>` | Maximum number of results |
| `--json` | Output in JSON format |

**Example:**

```bash
# List all convoys
gt convoy list

# List active convoys only
gt convoy list --status active
```

**Sample output:**

```text
ID          TITLE                    STATUS     PROGRESS   AGE
hq-cv-001   Auth System Fixes        active     2/3        2h
hq-cv-002   API Refactor             active     0/5        30m
hq-cv-003   Bug Fix Sprint           completed  4/4        1d
```

---

## `gt convoy status`

Show summary status of all convoys or a specific convoy.

```bash
gt convoy status [convoy-id] [options]
```

**Description:** Without an ID, shows an overview of all active convoys. With a convoy ID, shows detailed progress information.

**Options:**

| Flag | Description |
|------|-------------|
| `--json` | Output in JSON format |

**Example:**

```bash
# Overview of all active convoys
gt convoy status

# Status of a specific convoy
gt convoy status hq-cv-001
```

---

## `gt convoy show`

Show detailed information about a convoy.

```bash
gt convoy show <convoy-id> [options]
```

**Description:** Displays comprehensive convoy details including all tracked beads, their individual statuses, assigned agents, and overall progress metrics.

**Options:**

| Flag | Description |
|------|-------------|
| `--json` | Output in JSON format |
| `--verbose` | Include bead details and history |

**Example:**

```bash
gt convoy show hq-cv-001
```

**Sample output:**

```text
Convoy: hq-cv-001
Title: Auth System Fixes
Status: active
Progress: 2/3 (67%)
Created: 2h ago

BEAD       STATUS         AGENT           TITLE
gt-a1b2c   completed      polecat/toast   Fix login redirect
gt-d3e4f   in_progress    polecat/alpha   Add email validation
gt-g5h6i   pending        -               Update auth docs
```

---

## `gt convoy close`

Manually close a convoy.

```bash
gt convoy close <convoy-id> [options]
```

**Description:** Closes a convoy regardless of whether all tracked beads are complete. Use for administrative cleanup or when remaining items are no longer relevant.

**Options:**

| Flag | Description |
|------|-------------|
| `--reason <text>` | Reason for manual closure |
| `--force` | Close even if beads are still open |

**Example:**

```bash
# Close a completed convoy
gt convoy close hq-cv-001

# Force-close an incomplete convoy
gt convoy close hq-cv-002 --force --reason "Requirements changed, work no longer needed"
```

:::note

Convoys auto-close when all tracked beads reach a terminal state (completed, closed, or won't-fix). Manual closure is only needed for exceptional situations.

:::

---

## `gt convoy check`

Check convoy health and consistency.

```bash
gt convoy check [convoy-id] [options]
```

**Description:** Validates the convoy state, checking for inconsistencies between convoy tracking and bead statuses. Reports any beads that may be stuck, orphaned, or in an unexpected state.

**Options:**

| Flag | Description |
|------|-------------|
| `--all` | Check all convoys |
| `--fix` | Attempt to fix inconsistencies |
| `--json` | Output in JSON format |

**Example:**

```bash
# Check a specific convoy
gt convoy check hq-cv-001

# Check all convoys and fix issues
gt convoy check --all --fix
```

---

## `gt convoy stranded`

Find convoys with work that is ready but unassigned.

```bash
gt convoy stranded [options]
```

**Description:** Identifies convoys where one or more beads are in a ready state (pending or open) but not assigned to any agent. These represent stalled work that needs attention.

**Options:**

| Flag | Description |
|------|-------------|
| `--json` | Output in JSON format |

**Example:**

```bash
gt convoy stranded
```

**Sample output:**

```text
CONVOY       TITLE                    STRANDED   TOTAL
hq-cv-002    API Refactor             3          5
hq-cv-004    Documentation Update     1          2
```

:::warning

Stranded convoys indicate work that has fallen through the cracks. The Mayor should be notified to reassign this work, or use `gt sling` to assign it manually.

:::

---

## `gt synthesis`

Manage convoy synthesis steps.

```bash
gt synthesis <subcommand> <convoy-id>
```

**Description:** Synthesis is the final step in a convoy workflow that combines outputs from all parallel legs into a unified deliverable. This is a top-level command separate from `gt convoy synthesis` (which generates reports).

**Aliases:** `synth`

**Subcommands:**

| Subcommand | Description |
|------------|-------------|
| `gt synthesis status <convoy-id>` | Check if convoy is ready for synthesis |
| `gt synthesis start <convoy-id>` | Start synthesis for a convoy (checks all legs complete) |
| `gt synthesis close <convoy-id>` | Close convoy after synthesis complete |

**Example:**

```bash
# Check readiness
gt synthesis status hq-cv-abc

# Start synthesis step
gt synthesis start hq-cv-abc

# Close after synthesis
gt synthesis close hq-cv-abc
```

---

## `gt convoy synthesis`

Generate a synthesis report for a convoy.

```bash
gt convoy synthesis <convoy-id> [options]
```

**Description:** Produces a summary report of the convoy's progress, including what was accomplished, what remains, any blockers encountered, and time metrics. Useful for status updates and retrospectives.

**Options:**

| Flag | Description |
|------|-------------|
| `--format <fmt>` | Output format: `text`, `markdown`, `json` |
| `--verbose` | Include per-bead details |

**Example:**

```bash
# Generate text synthesis
gt convoy synthesis hq-cv-001

# Generate markdown report
gt convoy synthesis hq-cv-001 --format markdown

# Detailed synthesis
gt convoy synthesis hq-cv-001 --verbose
```

**Sample output:**

```text
Convoy Synthesis: Auth System Fixes (hq-cv-001)
================================================

Progress: 2/3 completed (67%)
Duration: 2h 15m
Agents used: 3 polecats

Completed:
  - gt-a1b2c: Fix login redirect loop (polecat/toast, 45m)
  - gt-d3e4f: Add email validation (polecat/alpha, 1h 10m)

Remaining:
  - gt-g5h6i: Update auth docs (pending, unassigned)

Blockers: none
Merge status: 2 merged, 0 in queue
```

## Related

- [Convoys (Concept)](../concepts/convoys.md) -- What convoys are and how they track work
- [Manual Convoy Workflow](../workflows/manual-convoy.md) -- Step-by-step guide for running convoys
- [gt sling](./sling.md) -- Assigning work to agents (auto-creates convoys)
- [Work Distribution](../architecture/work-distribution.md) -- How work flows through Gas Town
