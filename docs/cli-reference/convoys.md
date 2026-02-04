---
title: "Convoy & Tracking"
sidebar_position: 4
description: "Convoys are Gas Town's primary mechanism for bundling and tracking batches of related work. A convoy groups multiple beads together, monitors their collectiv..."
---

# Convoy & Tracking

Convoys are Gas Town's primary mechanism for bundling and tracking batches of related work. A convoy groups multiple beads together, monitors their collective progress, and auto-closes when all tracked items complete.

---

### `gt convoy create`

Create a new convoy.

```bash
gt convoy create <name> [bead-id...] [options]
```

**Description:** Creates a new convoy with an optional set of initial beads. Convoys are the standard unit for tracking a batch of related work such as a feature set, a bug-fix sprint, or a documentation effort.

**Options:**

| Flag | Description |
|------|-------------|
| `--molecule <id>` | Associated molecule ID |
| `--notify [address]` | Additional address to notify on completion (default: `mayor/` if used without value) |
| `--owner <address>` | Owner who requested convoy (gets completion notification) |

**Example:**

```bash
# Create with initial beads
gt convoy create "Auth System Fixes" gt-a1b2c gt-d3e4f gt-g5h6i
# Created: hq-cv-001

# Create empty convoy (add beads later)
gt convoy create "Q1 Performance Sprint"

# Create with owner and notification
gt convoy create "API Refactor" --owner mayor/ops --notify
```

---

### `gt convoy add`

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

### `gt convoy list`

List all convoys.

```bash
gt convoy list [options]
```

**Options:**

| Flag | Description |
|------|-------------|
| `--json` | Output in JSON format |

**Example:**

```bash
# List all convoys
gt convoy list

# List in JSON format
gt convoy list --json
```

**Sample output:**

```
ID          TITLE                    STATUS     PROGRESS   AGE
hq-cv-001   Auth System Fixes        active     2/3        2h
hq-cv-002   API Refactor             active     0/5        30m
hq-cv-003   Bug Fix Sprint           completed  4/4        1d
```

---

### `gt convoy status`

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

:::note

There is no `gt convoy show` subcommand. Use `gt convoy status <convoy-id>` to view detailed information about a specific convoy.

:::

---

### `gt convoy close`

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

### `gt convoy check`

Check and auto-close completed convoys.

```bash
gt convoy check [convoy-id] [options]
```

**Description:** Checks convoy state and automatically closes convoys where all tracked beads have reached a terminal state. Without an ID, checks all active convoys.

**Options:**

| Flag | Description |
|------|-------------|
| `--json` | Output in JSON format |

**Example:**

```bash
# Check a specific convoy
gt convoy check hq-cv-001

# Check all convoys
gt convoy check
```

---

### `gt convoy stranded`

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

```
CONVOY       TITLE                    STRANDED   TOTAL
hq-cv-002    API Refactor             3          5
hq-cv-004    Documentation Update     1          2
```

:::warning

Stranded convoys indicate work that has fallen through the cracks. The Mayor should be notified to reassign this work, or use `gt sling` to assign it manually.

:::

---

:::note

Synthesis is not a convoy subcommand. To generate a synthesis report, use the top-level command `gt synthesis`. See the [synthesis documentation](/cli-reference/synthesis) for details.

:::
