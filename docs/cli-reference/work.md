---
title: "Work Management"
sidebar_position: 3
description: "Commands for creating, assigning, tracking, and completing work items. This includes both gt commands for work orchestration and bd (Beads) commands for issu..."
---

# Work Management

Commands for creating, assigning, tracking, and completing work items. This includes both `gt` commands for work orchestration and `bd` (Beads) commands for issue tracking.

---

## Work Orchestration

### `gt ready`

List work items that are ready for assignment.

```bash
gt ready [options]
```

**Description:** Display all ready work items across the town and all rigs. Aggregates ready issues from town beads (hq-* items) and each rig's beads. Ready items have no blockers.

**Options:**

| Flag | Description |
|------|-------------|
| `--rig <name>` | Filter to a specific rig |
| `--json` | Output in JSON format |

**Example:**

```bash
# Show all ready work
gt ready

# Show ready work for a specific rig
gt ready --rig myproject
```

**Sample output:**

```
ID         PRIORITY   TYPE      TITLE                           RIG
gt-abc12   high       bug       Fix login redirect loop         myproject
gt-def34   medium     feature   Add email validation            myproject
gt-ghi56   low        task      Update API documentation        docs
```

---

### `gt sling`

Assign work to a rig or agent.

```bash
gt sling <bead-id>... <target> [options]
```

**Description:** The primary command for assigning work. Applies a formula to a bead, spawns a polecat in the target rig, and propels the work forward. This is the central work distribution command in Gas Town. When slinging a single issue, a convoy is automatically created unless `--no-convoy` is specified.

**Options:**

| Flag | Description |
|------|-------------|
| `--agent <runtime>` | Override agent/runtime for this sling |
| `--account <handle>` | Claude Code account handle to use |
| `--args`, `-a` | Natural language instructions for the executor |
| `--create` | Create polecat if it doesn't exist |
| `--dry-run`, `-n` | Show what would be done |
| `--force` | Force spawn even if polecat has unread mail |
| `--hook-raw-bead` | Hook raw bead without default formula (expert mode) |
| `--message`, `-m` | Context message for the work |
| `--subject`, `-s` | Context subject for the work |
| `--no-convoy` | Skip auto-convoy creation for single-issue sling |
| `--no-merge` | Skip merge queue on completion (keep work on feature branch) |
| `--on <bead>` | Apply formula to existing bead |
| `--var <key=value>` | Formula variable (can be repeated) |

**Example:**

```bash
# Assign a single bead to a rig (auto-spawns polecat)
gt sling gt-abc12 myproject

# Assign multiple beads
gt sling gt-abc12 gt-def34 myproject

# Assign with a specific agent
gt sling gt-abc12 myproject --agent cursor

# Dry run to preview what would happen
gt sling gt-abc12 myproject --dry-run

# Sling with context message
gt sling gt-abc12 myproject -m "Focus on the auth module"
```

**What happens:**

1. A convoy is auto-created for the work (unless `--no-convoy`)
2. A formula is applied to the bead and a polecat spawns in the rig
3. The polecat propels the work forward following the propulsion principle
4. On completion, the work enters the merge queue (unless `--no-merge`)

:::tip

The Mayor typically handles slinging automatically. Use `gt sling` for manual assignment or when fine-grained control is needed.

:::

---

### `gt hook`

View or attach work to the current agent's hook.

```bash
gt hook [bead-id] [options]
```

**Description:** Without arguments, shows what is currently on the agent's hook. With a bead ID, attaches that work item to the hook. The hook is Gas Town's durability primitive -- work on a hook survives session restarts, compaction, and crashes.

**Alias:** `work`

**Subcommands:**

| Subcommand | Description |
|------------|-------------|
| `show` | Show current hook contents |
| `status` | Show hook status |

**Options:**

| Flag | Description |
|------|-------------|
| `--json` | Output in JSON format |
| `--clear` | Clear the current hook |
| `--dry-run`, `-n` | Show what would be done |
| `--force`, `-f` | Force hook even if hook is occupied |
| `--message`, `-m` | Context message for the work |
| `--subject`, `-s` | Context subject for the work |

**Example:**

```bash
# Show current hook
gt hook

# Attach work to hook
gt hook gt-abc12

# Force attach (replacing current hook contents)
gt hook gt-abc12 --force

# Clear the hook
gt hook --clear
```

**Sample output:**

```
Hook: gt-abc12 "Fix login redirect loop" [in_progress]
  Rig: myproject
  Branch: fix/login-bug
  Convoy: hq-cv-001
  Hooked: 15m ago
```

---

### `gt unsling`

Remove work from a hook without completing it.

```bash
gt unsling <bead-id> [options]
```

**Description:** Detaches work from an agent's hook and changes the bead status from `hooked` back to `open`. Use this when work needs to be reassigned or when a polecat should not continue with a task.

**Alias:** `unhook`

**Options:**

| Flag | Description |
|------|-------------|
| `--force` | Force unsling even if the agent is actively working |
| `--dry-run`, `-n` | Show what would be done |

**Example:**

```bash
# Unsling from current agent
gt unsling gt-abc12

# Force unsling even if agent is working
gt unsling gt-abc12 --force
```

---

### `gt done`

Mark work as complete and submit a merge request.

```bash
gt done [options]
```

**Description:** The standard polecat exit command. Commits any remaining changes, pushes the branch, creates a merge request for the Refinery, updates the bead status, and exits the polecat session. This is the happy-path completion for any piece of work.

**Options:**

| Flag | Description |
|------|-------------|
| `--status <state>` | Exit status: `COMPLETED`, `ESCALATED`, or `DEFERRED` (default `COMPLETED`) |
| `--issue <id>` | Source issue ID (default: parse from branch name) |
| `--phase-complete` | Signal phase complete -- await gate before continuing |
| `--gate <id>` | Gate bead ID to wait on (with `--phase-complete`) |
| `--priority`, `-p` | Override priority (0-4) |
| `--cleanup-status` | Git cleanup status (agent-observed) |

**Example:**

```bash
# Standard completion
gt done

# Complete with escalation
gt done --status ESCALATED

# Defer work for later
gt done --status DEFERRED

# Phase complete with gate
gt done --phase-complete --gate gt-gate01
```

**Exit states:**

| `--status` value | Exit State | Meaning |
|------------------|-----------|---------|
| `COMPLETED` (default) | `COMPLETED` | Work done, MR submitted to Refinery |
| `ESCALATED` | `ESCALATED` | Hit a blocker, needs human input |
| `DEFERRED` | `DEFERRED` | Paused, another agent can pick up later |

| Flag | Exit State | Meaning |
|------|-----------|---------|
| `--phase-complete` | `PHASE_COMPLETE` | Phase done, waiting for gate |

---

### `gt close`

Close a bead without going through the done workflow.

```bash
gt close <bead-id> [options]
```

**Description:** Wrapper for `bd close`. Manually closes a bead. All flags supported by `bd close` are passed through.

**Example:**

```bash
gt close gt-abc12
gt close gt-abc12 --reason "Resolved by upstream fix"
```

---

### `gt release`

Release a stuck in-progress bead back to the ready pool.

```bash
gt release <bead-id> [options]
```

**Description:** Frees a bead that is stuck in `in_progress` or `hooked` status, making it available for reassignment. Essential for recovering from polecat crashes or stalled work.

**Options:**

| Flag | Description |
|------|-------------|
| `--reason`, `-r` | Reason for releasing |

**Example:**

```bash
gt release gt-abc12
gt release gt-abc12 --reason "Agent stalled, reassigning"
```

:::tip

The Witness automatically detects stalled polecats and can release their work. Use `gt release` for manual intervention.

:::

---

### `gt show`

Show detailed information about a bead or work item.

```bash
gt show <bead-id> [options]
```

**Description:** Displays comprehensive information about a bead. Delegates to `bd show` -- all `bd show` flags are supported.

**Example:**

```bash
gt show gt-abc12
gt show gt-abc12 --json
```

**Sample output:**

```
Bead: gt-abc12
Title: Fix login redirect loop
Type: bug
Priority: high
Status: in_progress
Rig: myproject
Agent: polecat/toast
Branch: fix/login-bug
Convoy: hq-cv-001
Created: 2h ago
Updated: 15m ago
```

---

### `gt cat`

Output the raw content of a bead or work artifact.

```bash
gt cat <bead-id> [options]
```

**Description:** Display the content of a bead. Convenience wrapper around `bd show`.

**Options:**

| Flag | Description |
|------|-------------|
| `--json` | Output in JSON format |

**Example:**

```bash
# Full bead content
gt cat gt-abc12

# JSON output for scripting
gt cat gt-abc12 --json
```

---

## Beads (Issue Tracking)

Beads is the git-backed issue tracking system integrated into Gas Town. The `bd` CLI manages beads directly.

### `bd create`

Create a new bead (issue).

```bash
bd create [options]
```

**Description:** Creates a new bead in the beads database. Beads are the fundamental work unit in Gas Town.

**Options:**

| Flag | Description |
|------|-------------|
| `--title <text>` | Bead title (required) |
| `--type <type>` | Type: `bug`, `feature`, `task`, `chore`, `epic` |
| `--priority <level>` | Priority: `0-4` or `P0-P4` (0=highest, default P2) |
| `--description <text>` | Detailed description |
| `--rig <name>` | Create issue in a different rig |
| `--prefix` | Create issue in rig by prefix |
| `--labels`, `-l` | Labels (comma-separated) |
| `--assignee`, `-a` | Assignee |
| `--notes` | Additional notes |
| `--design` | Design notes |
| `--parent <id>` | Set parent bead for hierarchical tracking |
| `--convoy <id>` | Add to an existing convoy |
| `--silent` | Output only the issue ID |
| `--ephemeral` | Create as ephemeral |

**Example:**

```bash
bd create --title "Fix login bug" --type bug --priority P0
# Created: gt-abc12

bd create --title "Add email validation" --type feature --description "Validate email format on registration form" --rig myproject
# Created: gt-def34

bd create --title "Auth epic" --type epic --labels "auth,security"
# Created: gt-epc01
```

---

### `bd list`

List beads with optional filters.

```bash
bd list [options]
```

**Options:**

| Flag | Description |
|------|-------------|
| `--status <status>` | Filter: `open`, `in_progress`, `closed`, `pending`, `hooked` |
| `--type <type>` | Filter by type |
| `--priority <level>` | Filter by priority |
| `--rig <name>` | Filter by rig |
| `--label <label>` | Filter by label |
| `--limit <n>` | Maximum number of results |
| `--sort <field>` | Sort by: `created`, `updated`, `priority` |
| `--json` | Output in JSON format |

**Example:**

```bash
# List all open beads
bd list --status open

# List high-priority bugs
bd list --type bug --priority high

# List recent 10 beads
bd list --limit 10 --sort updated
```

---

### `bd show`

Show detailed information about a bead.

```bash
bd show <bead-id> [options]
```

**Options:**

| Flag | Description |
|------|-------------|
| `--json` | Output in JSON format |
| `--comments` | Include comments |

**Example:**

```bash
bd show gt-abc12
```

---

### `bd update`

Update a bead's fields.

```bash
bd update <bead-id> [options]
```

**Options:**

| Flag | Description |
|------|-------------|
| `--title <text>` | Update title |
| `--priority <level>` | Update priority |
| `--type <type>` | Update type |
| `--status <status>` | Update status |
| `--description <text>` | Update description |
| `--label <label>` | Add a label |
| `--remove-label <label>` | Remove a label |
| `--comment <text>` | Add a comment |
| `--assign <agent>` | Assign to an agent |

**Example:**

```bash
bd update gt-abc12 --priority critical --comment "This is blocking production"
bd update gt-def34 --status in_progress --assign polecat/toast
```

---

### `bd close`

Close a bead.

```bash
bd close <bead-id> [options]
```

**Options:**

| Flag | Description |
|------|-------------|
| `--reason <text>` | Closure reason |
| `--comment <text>` | Add a final comment |

**Example:**

```bash
bd close gt-abc12 --reason "Fixed in PR #42"
```

---

### `bd sync`

Synchronize the beads database.

```bash
bd sync [options]
```

**Description:** Exports the beads database to JSONL for git synchronization. Ensures all beads are consistent across agents and workspaces.

**Options:**

| Flag | Description |
|------|-------------|
| `--full` | Force full sync (legacy full sync behavior) |
| `--flush-only` | Only flush pending changes |
| `--import` | Import beads from JSONL |
| `--import-only` | Import only, do not export |
| `--status` | Show sync status |
| `--rig <name>` | Sync a specific rig's beads only |

**Example:**

```bash
bd sync
bd sync --rig myproject
bd sync --flush-only
bd sync --import
```

---

## Bead Subcommands (gt)

### `gt bead show`

Show bead details through the `gt` interface.

```bash
gt bead show <bead-id> [options]
```

**Description:** Similar to `bd show` but integrates with Gas Town context, showing additional information like hook status, convoy membership, and agent assignment.

**Options:**

| Flag | Description |
|------|-------------|
| `--json` | Output in JSON format |
| `--verbose` | Show extended details |

**Example:**

```bash
gt bead show gt-abc12
```

---

### `gt bead read`

Read a bead's full content into the agent context.

```bash
gt bead read <bead-id>
```

**Description:** Loads the complete bead content (description, comments, history) into the current agent's working context. Primarily used by agents to understand their assigned work.

**Example:**

```bash
gt bead read gt-abc12
```

---

### `gt bead move`

Move a bead between rigs.

```bash
gt bead move <bead-id> <target-rig> [options]
```

**Description:** Transfers a bead from one rig to another. Useful when work is reassigned to a different project.

**Options:**

| Flag | Description |
|------|-------------|
| `--force` | Move even if the bead is currently hooked |

**Example:**

```bash
gt bead move gt-abc12 docs
gt bead move gt-def34 myproject --force
```

:::note

Moving a hooked bead without `--force` will fail. Unsling it first, or use `--force` to automatically unsling before moving.


:::