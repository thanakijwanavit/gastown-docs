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

**Description:** Aggregates ready issues from town beads (hq-* items) and each rig's beads. Ready items have no blockers and can be worked immediately. Results are sorted by priority (highest first).

**Options:**

| Flag | Description |
|------|-------------|
| `--rig <name>` | Filter to a specific rig |
| `--json` | Output in JSON format |

**Example:**

```bash
# Show all ready work across town
gt ready

# Show ready work for a specific rig
gt ready --rig myproject
```

---

### `gt sling`

Assign work to an agent. THE unified work dispatch command.

```bash
gt sling <bead-or-formula> [target] [options]
```

**Description:** The primary command for assigning work. Handles existing agents, auto-spawning polecats, dispatching to dogs, formula instantiation, and auto-convoy creation. When multiple beads are provided with a rig target, each bead gets its own polecat.

**Target resolution:**

| Target | Result |
|--------|--------|
| *(none)* | Self (current agent) |
| `crew` | Crew worker in current rig |
| `myrig` | Auto-spawn polecat in rig |
| `myrig/toast` | Specific polecat |
| `mayor` | Mayor |
| `deacon/dogs` | Auto-dispatch to idle dog |
| `deacon/dogs/alpha` | Specific dog |

**Options:**

| Flag | Description |
|------|-------------|
| `--agent <runtime>` | Override agent runtime (e.g., `claude`, `gemini`, `codex`) |
| `--account <handle>` | Claude Code account handle to use |
| `--args`, `-a` | Natural language instructions for the executor |
| `--create` | Create polecat if it doesn't exist |
| `--force` | Force spawn even if polecat has unread mail |
| `--message`, `-m` | Context message for the work |
| `--subject`, `-s` | Context subject for the work |
| `--no-convoy` | Skip auto-convoy creation |
| `--no-merge` | Skip merge queue on completion (keep branch for review) |
| `--hook-raw-bead` | Hook raw bead without default formula (expert mode) |
| `--on <bead-id>` | Apply formula to existing bead |
| `--var <key=value>` | Formula variable (can be repeated) |
| `--dry-run`, `-n` | Show what would be done |

**Example:**

```bash
# Assign a single bead to a rig (auto-spawns polecat)
gt sling gt-abc12 myproject

# Batch sling (each bead gets its own polecat)
gt sling gt-abc12 gt-def34 gt-ghi56 myproject

# Assign with natural language instructions
gt sling gt-abc12 myproject --args "patch release"

# Sling a formula
gt sling mol-release mayor/

# Apply formula to existing work
gt sling mol-review --on gt-abc12

# Assign with a specific agent
gt sling gt-abc12 myproject --agent cursor
```

:::tip
The Mayor typically handles slinging automatically. Use `gt sling` for manual assignment or when fine-grained control is needed.
:::

---

### `gt hook`

View or attach work to the current agent's hook.

```bash
gt hook [bead-id] [options]
```

**Aliases:** `work`

**Description:** Without arguments, shows what is currently on the agent's hook (alias for `gt mol status`). With a bead ID, attaches that work item to the hook. The hook is Gas Town's durability primitive — work on a hook survives session restarts, compaction, and crashes.

**Subcommands:**

| Subcommand | Description |
|------------|-------------|
| `status` | Show what's on your hook |
| `show` | Show what's on an agent's hook (compact) |

**Options:**

| Flag | Description |
|------|-------------|
| `--json` | Output in JSON format (for status) |
| `--subject`, `-s` | Subject for handoff mail |
| `--message`, `-m` | Message for handoff mail |
| `--force`, `-f` | Replace existing incomplete hooked bead |
| `--clear` | Clear your hook (alias for `gt unhook`) |
| `--dry-run`, `-n` | Show what would be done |

**Example:**

```bash
# Show current hook
gt hook

# Attach work to hook
gt hook gt-abc12

# Attach with context
gt hook gt-abc12 -s "Fix the login bug"
```

**Related commands:**

| Command | Behavior |
|---------|----------|
| `gt hook <bead>` | Just attach (no action) |
| `gt sling <bead>` | Attach + start now (keep context) |
| `gt handoff <bead>` | Attach + restart (fresh context) |

---

### `gt unsling`

Remove work from a hook without completing it.

```bash
gt unsling <bead-id> [options]
```

**Description:** Detaches work from an agent's hook and sets the bead back to an assignable state. Use this when work needs to be reassigned or when a polecat should not continue with a task.

**Options:**

| Flag | Description |
|------|-------------|
| `--release` | Also release the bead back to `open` status |
| `--force` | Force unsling even if the agent is actively working |

**Example:**

```bash
# Unsling from current agent
gt unsling gt-abc12

# Unsling and release back to ready pool
gt unsling gt-abc12 --release
```

---

### `gt done`

Signal work complete and submit to the merge queue.

```bash
gt done [options]
```

**Description:** The standard polecat exit command. Submits the current branch to the merge queue, auto-detects issue ID from branch name, notifies the Witness with the exit outcome, and exits the Claude session.

**Options:**

| Flag | Description |
|------|-------------|
| `--status <status>` | Exit status: `COMPLETED`, `ESCALATED`, or `DEFERRED` (default: `COMPLETED`) |
| `--issue <id>` | Source issue ID (default: parsed from branch name) |
| `--priority`, `-p` | Override priority 0-4 (default: inherit from issue) |
| `--phase-complete` | Signal phase complete — await gate before continuing |
| `--gate <id>` | Gate bead ID to wait on (with `--phase-complete`) |
| `--cleanup-status <status>` | Git cleanup status: `clean`, `uncommitted`, `unpushed`, `stash`, `unknown` |

**Example:**

```bash
# Standard completion
gt done

# Explicit issue ID
gt done --issue gt-abc12

# Escalate a blocker
gt done --status ESCALATED

# Phase complete, waiting on gate
gt done --phase-complete --gate g-abc
```

**Exit states:**

| Status | Meaning |
|--------|---------|
| `COMPLETED` | Work done, MR submitted to Refinery (default) |
| `ESCALATED` | Hit a blocker, needs human intervention |
| `DEFERRED` | Work paused, issue still open |
| `PHASE_COMPLETE` | Phase done, awaiting gate (use `--phase-complete`) |

---

### `gt close`

Close a bead without going through the done workflow.

```bash
gt close <bead-id> [options]
```

**Description:** Manually closes a bead. Useful for closing duplicate issues, items resolved by other means, or administrative cleanup.

**Options:**

| Flag | Description |
|------|-------------|
| `--reason <text>` | Reason for closing |
| `--wontfix` | Close as won't fix |
| `--duplicate <id>` | Close as duplicate of another bead |

**Example:**

```bash
gt close gt-abc12 --reason "Resolved by upstream fix"
gt close gt-def34 --duplicate gt-abc12
gt close gt-ghi56 --wontfix
```

---

### `gt release`

Release stuck in-progress issues back to open status.

```bash
gt release <issue-id>... [options]
```

**Description:** Moves issues from `in_progress` back to `open` status and clears the assignee, allowing another worker to claim and complete them. Implements nondeterministic idempotence — work can be safely retried by releasing and reclaiming stuck steps.

**Options:**

| Flag | Description |
|------|-------------|
| `--reason`, `-r` | Reason for releasing (added as note) |

**Example:**

```bash
gt release gt-abc12
gt release gt-abc12 gt-def34 -r "worker died"
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

**Description:** Displays comprehensive information about a bead including its status, history, assigned agent, convoy membership, and related activity.

**Options:**

| Flag | Description |
|------|-------------|
| `--json` | Output in JSON format |
| `--history` | Include full status change history |
| `--comments` | Include all comments |

**Example:**

```bash
gt show gt-abc12
gt show gt-abc12 --history
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

Display the content of a bead.

```bash
gt cat <bead-id> [options]
```

**Description:** Convenience wrapper around `bd show` that integrates with `gt`. Accepts any bead ID (`bd-*`, `hq-*`, `mol-*`).

**Options:**

| Flag | Description |
|------|-------------|
| `--json` | Output in JSON format |

**Example:**

```bash
gt cat gt-abc12
gt cat hq-xyz789
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
| `--priority <level>` | Priority: `critical`, `high`, `medium`, `low` |
| `--description <text>` | Detailed description |
| `--rig <name>` | Assign to a specific rig |
| `--label <label>` | Add labels (can be repeated) |
| `--parent <id>` | Set parent bead for hierarchical tracking |
| `--convoy <id>` | Add to an existing convoy |

**Example:**

```bash
bd create --title "Fix login bug" --type bug --priority high
# Created: gt-abc12

bd create --title "Add email validation" --type feature --description "Validate email format on registration form" --rig myproject
# Created: gt-def34

bd create --title "Auth epic" --type epic
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

### `bd ready`

Show issues ready to work (no blockers, open or in_progress).

```bash
bd ready [options]
```

**Description:** Lists issues that have no blocking dependencies and can be worked immediately.

**Example:**

```bash
bd ready
```

---

### `bd blocked`

Show blocked issues.

```bash
bd blocked [options]
```

**Description:** Lists issues that are blocked by unresolved dependencies.

**Example:**

```bash
bd blocked
```

---

### `bd search`

Search issues by text query.

```bash
bd search <query> [options]
```

**Description:** Full-text search across issue titles, descriptions, and comments.

**Options:**

| Flag | Description |
|------|-------------|
| `--from <agent>` | Filter by author |
| `--since <time>` | Filter by date |
| `--limit <n>` | Maximum results |
| `--json` | Output in JSON format |

**Example:**

```bash
bd search "login bug"
bd search "authentication" --limit 5
```

---

### `bd dep`

Manage dependencies between issues.

```bash
bd dep <subcommand> <issue-id> <depends-on-id>
```

**Description:** Add or remove dependency relationships. When issue A depends on issue B, A is blocked until B is closed.

**Subcommands:**

| Subcommand | Description |
|------------|-------------|
| `add <issue> <depends-on>` | Add dependency (issue depends on depends-on) |
| `rm <issue> <depends-on>` | Remove dependency |

**Example:**

```bash
# "Write tests" depends on "Implement feature"
bd dep add gt-tests gt-feature

# Show what's blocked
bd blocked
```

:::warning
Think "X needs Y", not "X comes before Y". Temporal language inverts dependencies.
:::

---

### `bd delete`

Delete one or more issues and clean up references.

```bash
bd delete <bead-id>... [options]
```

**Description:** Permanently removes issues from the database and cleans up dependency references.

**Example:**

```bash
bd delete gt-abc12
bd delete gt-abc12 gt-def34
```

---

### `bd reopen`

Reopen one or more closed issues.

```bash
bd reopen <bead-id>... [options]
```

**Example:**

```bash
bd reopen gt-abc12
```

---

### `bd comments`

View or manage comments on an issue.

```bash
bd comments <bead-id> [options]
```

**Example:**

```bash
bd comments gt-abc12
```

---

### `bd label`

Manage issue labels.

```bash
bd label <subcommand> [options]
```

**Description:** Add, remove, or list labels on issues.

**Example:**

```bash
bd label add gt-abc12 bug
bd label rm gt-abc12 wontfix
```

---

### `bd graph`

Display issue dependency graph.

```bash
bd graph [options]
```

**Description:** Visualizes issue dependency relationships as a graph.

**Example:**

```bash
bd graph
```

---

### `bd epic`

Epic management commands.

```bash
bd epic <subcommand> [options]
```

**Description:** Manage epics — parent issues that group related work.

**Example:**

```bash
bd epic list
bd epic show gt-epc01
```

---

### `bd sync`

Export database to JSONL (sync with git).

```bash
bd sync [options]
```

**Description:** Exports the beads SQLite database to JSONL format for git-based persistence. Use `--flush-only` to export without importing.

**Options:**

| Flag | Description |
|------|-------------|
| `--force` | Force full resync |
| `--rig <name>` | Sync a specific rig's beads only |
| `--flush-only` | Export to JSONL only (no import) |

**Example:**

```bash
bd sync
bd sync --flush-only
bd sync --rig myproject
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