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

**Description:** Shows beads in `pending` or `open` status that are not currently assigned to any agent. These are available for slinging to workers.

**Options:**

| Flag | Description |
|------|-------------|
| `--rig <name>` | Filter to a specific rig |
| `--priority <level>` | Filter by priority: `critical`, `high`, `medium`, `low` |
| `--type <type>` | Filter by type: `bug`, `feature`, `task`, `chore` |
| `--convoy <id>` | Show only items in a specific convoy |
| `--json` | Output in JSON format |

**Example:**

```bash
# Show all ready work
gt ready

# Show high-priority bugs ready for work
gt ready --priority high --type bug

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

**Description:** The primary command for assigning work. Hooks the bead to the target, updates its status, and spawns a polecat to execute the work. This is the central work distribution command in Gas Town.

**Options:**

| Flag | Description |
|------|-------------|
| `--agent <runtime>` | Agent runtime for the spawned polecat |
| `--name <name>` | Name for the spawned polecat |
| `--priority` | Override bead priority for scheduling |
| `--no-spawn` | Hook the work but do not spawn a polecat |

**Example:**

```bash
# Assign a single bead to a rig (auto-spawns polecat)
gt sling gt-abc12 myproject

# Assign multiple beads
gt sling gt-abc12 gt-def34 myproject

# Assign with a specific agent
gt sling gt-abc12 myproject --agent cursor

# Hook work without spawning (manual pickup later)
gt sling gt-abc12 myproject --no-spawn
```

**What happens:**

1. Bead status changes to `hooked`
2. Work attaches to the target's hook
3. A polecat spawns in the rig (unless `--no-spawn`)
4. The polecat's startup hook finds and begins the work

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

**Options:**

| Flag | Description |
|------|-------------|
| `--json` | Output in JSON format |

**Example:**

```bash
# Show current hook
gt hook

# Attach work to hook
gt hook gt-abc12
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

Mark work as complete and submit a merge request.

```bash
gt done [options]
```

**Description:** The standard polecat exit command. Commits any remaining changes, pushes the branch, creates a merge request for the Refinery, updates the bead status, and exits the polecat session. This is the happy-path completion for any piece of work.

**Options:**

| Flag | Description |
|------|-------------|
| `--message <msg>` | MR description / completion summary |
| `--no-mr` | Complete without creating a merge request |
| `--escalate` | Exit with escalation instead of completion |
| `--defer` | Exit with deferred status (work paused, not done) |
| `--phase` | Exit with phase-complete status (gate point) |

**Example:**

```bash
# Standard completion
gt done --message "Fixed login redirect by correcting OAuth callback URL"

# Complete without MR (e.g., documentation-only changes)
gt done --no-mr --message "Updated local docs only"

# Escalate a blocker
gt done --escalate --message "Blocked: need API credentials for staging"
```

**Exit states:**

| Flag | Exit State | Meaning |
|------|-----------|---------|
| (default) | `COMPLETED` | Work done, MR submitted to Refinery |
| `--escalate` | `ESCALATED` | Hit a blocker, needs human input |
| `--defer` | `DEFERRED` | Paused, another agent can pick up later |
| `--phase` | `PHASE_COMPLETE` | Phase done, waiting for gate |

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

Release a stuck in-progress bead back to the ready pool.

```bash
gt release <bead-id> [options]
```

**Description:** Frees a bead that is stuck in `in_progress` or `hooked` status, making it available for reassignment. Essential for recovering from polecat crashes or stalled work.

**Options:**

| Flag | Description |
|------|-------------|
| `--force` | Release even if an agent appears to still be working on it |

**Example:**

```bash
gt release gt-abc12
gt release gt-abc12 --force
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

Output the raw content of a bead or work artifact.

```bash
gt cat <bead-id> [options]
```

**Description:** Prints the raw bead content, including description, comments, and metadata. Useful for piping into other tools or for programmatic access.

**Options:**

| Flag | Description |
|------|-------------|
| `--field <name>` | Output only a specific field |
| `--format <fmt>` | Output format: `text`, `json`, `yaml` |

**Example:**

```bash
# Full bead content
gt cat gt-abc12

# Just the description
gt cat gt-abc12 --field description

# JSON output for scripting
gt cat gt-abc12 --format json
```

---

### `gt commit`

Git commit with automatic agent identity.

```bash
gt commit [flags] [-- git-commit-args...]
```

**Description:** A git commit wrapper that automatically sets the git author identity for agents. When run by an agent (with `GT_ROLE` set), it detects the agent identity from environment variables and converts it to a git-friendly name and email. When run by a human (no `GT_ROLE`), it passes through to plain `git commit`.

**Example:**

```bash
# Commit as current agent
gt commit -m "Fix bug"

# Stage all and commit
gt commit -am "Quick fix"

# Amend last commit
gt commit -- --amend
```

**Identity mapping:**

```
Agent: gastown/crew/jack  →  Name: gastown/crew/jack
                              Email: gastown.crew.jack@gastown.local
```

:::tip

The email domain is configurable in town settings (`agent_email_domain`). Default: `gastown.local`.

:::

---

### `gt gate`

Gate coordination for async workflows.

```bash
gt gate <subcommand>
```

**Description:** Gates provide async coordination points in workflows. Most gate operations are in the `bd` CLI (`bd gate create`, `bd gate show`, `bd gate list`, `bd gate close`, `bd gate approve`, `bd gate eval`). The `gt gate` command adds Gas Town integration.

**Subcommands:**

| Subcommand | Description |
|------------|-------------|
| `gt gate wake` | Send wake mail to gate waiters after a gate closes |

**Example:**

```bash
gt gate wake <gate-id>
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

### `bd sync`

Synchronize the beads database.

```bash
bd sync [options]
```

**Description:** Syncs the local beads SQLite database with the git-backed storage. Ensures all beads are consistent across agents and workspaces.

**Options:**

| Flag | Description |
|------|-------------|
| `--force` | Force full resync |
| `--rig <name>` | Sync a specific rig's beads only |

**Example:**

```bash
bd sync
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

## See Also

- [Beads](/docs/concepts/beads) — The work tracking primitive
- [Hooks](/docs/concepts/hooks) — How agents claim and track work
- [GUPP](/docs/concepts/gupp) — The propulsion principle behind work assignment
- [gt sling](/docs/cli-reference/sling) — Detailed sling command reference
- [Convoy & Tracking](/docs/cli-reference/convoys) — Batch work management