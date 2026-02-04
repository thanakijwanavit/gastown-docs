---
title: "Merge Queue"
sidebar_position: 6
description: "Commands for managing the Refinery's merge queue. The Refinery processes merge requests (MRs) submitted by polecats, rebasing them onto the latest main branc..."
---

# Merge Queue

Commands for managing the Refinery's merge queue. The Refinery processes merge requests (MRs) submitted by polecats, rebasing them onto the latest main branch, running validation, and merging clean code.

:::info[Alias]

`gt mr` is equivalent to `gt mq`. All subcommands work with either prefix.

:::

---

### `gt mq list`

List items in the merge queue for a rig.

```bash
gt mq list <rig> [flags]
```

**Description:** Shows merge requests in the queue for the specified rig, including their position, status, and associated branch.

**Options:**

| Flag | Description |
|------|-------------|
| `--json` | Output as JSON |
| `--ready` | Show only ready-to-merge (no blockers) |
| `--status <status>` | Filter by status: `open`, `in_progress`, `closed` |
| `--worker <name>` | Filter by worker name |
| `--epic <id>` | Show MRs targeting `integration/<epic>` |

**Example:**

```bash
# List queue for a rig
gt mq list myproject

# Show only ready-to-merge items
gt mq list myproject --ready

# Filter by status
gt mq list myproject --status open

# Show MRs targeting an epic's integration branch
gt mq list myproject --epic 42
```

**Sample output:**

```
POS  ID       BEAD       BRANCH                  STATUS       RIG          AGE
1    mr-001   gt-abc12   fix/login-bug           in_progress  myproject    5m
2    mr-002   gt-def34   feat/email-validation   open         myproject    2m
3    mr-003   gt-ghi56   docs/update-readme      open         myproject    1m
```

---

### `gt mq next`

Show the next item in the merge queue.

```bash
gt mq next [options]
```

**Description:** Without options, shows what the Refinery will process next. The Refinery typically calls this automatically during its patrol cycle.

**Options:**

| Flag | Description |
|------|-------------|
| `--rig <name>` | Target a specific rig |
| `--json` | Output in JSON format |

**Example:**

```bash
# Show next item
gt mq next

# Show next item for a specific rig
gt mq next --rig myproject
```

---

### `gt mq submit`

Submit a merge request to the queue.

```bash
gt mq submit [flags]
```

**Description:** Adds a branch to the merge queue for processing by the Refinery. Auto-detects the source branch, issue, worker, rig, target branch, and priority from the current context. This is typically called by `gt done` automatically, but can be used manually for crew workspaces or special cases.

**Options:**

| Flag | Description |
|------|-------------|
| `--branch` | Source branch (default: current branch) |
| `--issue` | Source issue ID (default: parsed from branch name) |
| `--epic` | Target epic's integration branch instead of main |
| `--priority`, `-p` | Override priority (0-4, default: inherit from issue) |
| `--no-cleanup` | Don't auto-cleanup after submit (for polecats) |

**Example:**

```bash
# Submit current branch (auto-detects everything)
gt mq submit

# Submit a specific branch with priority override
gt mq submit --branch fix/critical-bug --priority 4

# Submit targeting an epic's integration branch
gt mq submit --epic 42

# Submit without post-submit cleanup
gt mq submit --no-cleanup
```

:::tip

The standard polecat workflow uses `gt done` which handles `gt mq submit` automatically. When a polecat submits, its workspace is auto-cleaned up after submission unless `--no-cleanup` is specified. Use `gt mq submit` directly for crew (human developer) workflows or manual submissions.

:::

---

### `gt mq status`

Show overall merge queue status.

```bash
gt mq status [options]
```

**Description:** Displays a summary of the merge queue including queue depth, processing rate, and any current issues.

**Options:**

| Flag | Description |
|------|-------------|
| `--rig <name>` | Status for a specific rig |
| `--all` | Status across all rigs |
| `--json` | Output in JSON format |

**Example:**

```bash
gt mq status
gt mq status --all
```

**Sample output:**

```
Merge Queue Status: myproject
  Queue depth: 3
  Currently processing: mr-001 (fix/login-bug)
  Merged today: 7
  Rejected today: 1
  Avg merge time: 3m 20s
  Refinery: running (PID 1250)
```

---

### `gt mq reject`

Reject a merge request.

```bash
gt mq reject <mr-id> [options]
```

**Description:** Removes a merge request from the queue and marks it as rejected. The associated bead is updated and the submitting agent is notified.

**Options:**

| Flag | Description |
|------|-------------|
| `--reason <text>` | Rejection reason |
| `--reassign` | Release the bead for reassignment |

**Example:**

```bash
gt mq reject mr-002 --reason "Fails integration tests, needs rework"
gt mq reject mr-003 --reason "Superseded by mr-005" --reassign
```

---

### `gt mq retry`

Retry a failed or rejected merge request.

```bash
gt mq retry <mr-id> [options]
```

**Description:** Re-queues a previously failed or rejected merge request for another processing attempt. Useful after the underlying issue has been resolved (e.g., flaky test fixed, conflict resolved).

**Options:**

| Flag | Description |
|------|-------------|
| `--priority` | Retry with priority processing |
| `--rebase` | Force a fresh rebase before retrying |

**Example:**

```bash
gt mq retry mr-002
gt mq retry mr-002 --rebase --priority
```

---

### `gt mq integration`

Manage integration branches for batch work on epics.

```bash
gt mq integration <subcommand> [options]
```

**Description:** Manage integration branches for batch work on epics. Integration branches allow multiple MRs for an epic to target a shared branch instead of main. Once all work for the epic is complete, the integration branch is landed to main as a single merge.

**Subcommands:**

| Subcommand | Description |
|------------|-------------|
| `create` | Create an integration branch for an epic |
| `land` | Merge an integration branch to main |
| `status` | Show integration branch status |

**Example:**

```bash
# Create an integration branch for epic 42
gt mq integration create --epic 42

# Check status of an integration branch
gt mq integration status --epic 42

# Land a completed integration branch to main
gt mq integration land --epic 42
```

:::note[Merge Process]

The Refinery processes each MR through these steps:

1. **Rebase** -- Rebase the branch onto latest main
2. **Validate** -- Run all enabled integration checks
3. **Merge** -- Fast-forward merge to main if all checks pass
4. **Notify** -- Update bead status and notify the submitting agent

If a merge conflict occurs during rebase, the Refinery can spawn a fresh polecat to resolve the conflict before retrying.


:::