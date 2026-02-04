---
title: "Agent Operations"
sidebar_position: 2
description: "Commands for starting, stopping, monitoring, and managing the Gas Town agent hierarchy. Each agent role has dedicated lifecycle commands, plus there are cros..."
---

# Agent Operations

Commands for starting, stopping, monitoring, and managing the Gas Town agent hierarchy. Each agent role has dedicated lifecycle commands, plus there are cross-cutting commands for role management.

---

## General Agent Commands

### `gt agents`

Display a popup menu of core Gas Town agent sessions.

```bash
gt agents [options]
```

**Aliases:** `ag`

**Description:** Shows Mayor, Deacon, Witnesses, Refineries, and Crew workers in a tmux popup for quick session switching. Polecats are hidden by default (use `gt polecat list` to see them).

**Subcommands:**

| Subcommand | Description |
|------------|-------------|
| `list` | List agent sessions (no popup) |
| `check` | Check for identity collisions and stale locks |
| `fix` | Fix identity collisions and clean up stale locks |
| `state` | Get or set operational state on agent beads |

**Options:**

| Flag | Description |
|------|-------------|
| `--all`, `-a` | Include polecats in the menu |

**Example:**

```bash
# Open session switcher popup
gt agents

# Include polecats
gt agents --all

# List without popup
gt agents list
```

---

### `gt role`

Display or set the current agent role context.

```bash
gt role [role-name]
```

**Description:** Without arguments, displays the current role set by `GT_ROLE`. With an argument, sets the role for the current session. The role determines which identity and capabilities the current agent session operates under.

**Valid roles:** `mayor`, `deacon`, `witness`, `refinery`, `polecat`, `dog`, `crew`, `overseer`

**Example:**

```bash
# Show current role
gt role

# Set role
gt role witness
```

:::warning

Changing roles mid-session can cause unexpected behavior. This is primarily used during `gt prime` initialization.

:::

---

## Mayor

The Mayor is the top-level coordinator for the entire town. It receives instructions from the human overseer, creates work plans, and delegates to other agents.

### `gt mayor start`

Start the Mayor agent.

```bash
gt mayor start [options]
```

**Options:**

| Flag | Description |
|------|-------------|
| `--attach` | Start and immediately attach to the session |
| `--agent <runtime>` | Agent runtime to use (default: configured default) |
| `--resume` | Resume from a previous session checkpoint |

**Example:**

```bash
gt mayor start
gt mayor start --attach
gt mayor start --agent claude
```

---

### `gt mayor stop`

Stop the Mayor agent.

```bash
gt mayor stop [options]
```

**Options:**

| Flag | Description |
|------|-------------|
| `--force` | Force stop without graceful shutdown |
| `--checkpoint` | Save a checkpoint before stopping |

**Example:**

```bash
gt mayor stop
gt mayor stop --checkpoint
```

---

### `gt mayor status`

Show Mayor status and current activity.

```bash
gt mayor status [options]
```

**Options:**

| Flag | Description |
|------|-------------|
| `--json` | Output in JSON format |
| `--verbose` | Show extended status including mail queue and hook |

**Example:**

```bash
gt mayor status
```

**Sample output:**

```
Mayor: running (PID 1234)
Session: sess-abc123
Uptime: 2h 15m
Hook: empty
Inbox: 3 unread
Active convoys: 2
```

---

## Deacon

The Deacon is the health monitoring supervisor for the town. It runs patrol cycles, monitors all Witnesses, and handles lifecycle requests.

### `gt deacon start`

Start the Deacon agent.

```bash
gt deacon start [options]
```

**Options:**

| Flag | Description |
|------|-------------|
| `--attach` | Start and attach to the session |
| `--agent <runtime>` | Agent runtime to use |

**Example:**

```bash
gt deacon start
```

---

### `gt deacon stop`

Stop the Deacon agent.

```bash
gt deacon stop [options]
```

**Options:**

| Flag | Description |
|------|-------------|
| `--force` | Force stop without graceful shutdown |

---

### `gt deacon status`

Show Deacon status.

```bash
gt deacon status [options]
```

**Options:**

| Flag | Description |
|------|-------------|
| `--json` | Output in JSON format |

**Example:**

```bash
gt deacon status
```

---

## Witness

Witnesses are per-rig supervisors that monitor polecats, detect stalls, and manage worker lifecycle within a single rig.

### `gt witness start`

Start a Witness agent for a rig.

```bash
gt witness start <rig> [options]
```

**Options:**

| Flag | Description |
|------|-------------|
| `--attach` | Start and attach to the session |
| `--agent <runtime>` | Agent runtime to use |

**Example:**

```bash
gt witness start myproject
```

---

### `gt witness stop`

Stop a Witness agent.

```bash
gt witness stop <rig> [options]
```

**Options:**

| Flag | Description |
|------|-------------|
| `--force` | Force stop without graceful shutdown |

**Example:**

```bash
gt witness stop myproject
```

---

### `gt witness status`

Show Witness status for a rig.

```bash
gt witness status [rig] [options]
```

**Options:**

| Flag | Description |
|------|-------------|
| `--all` | Show all Witnesses across all rigs |
| `--json` | Output in JSON format |

**Example:**

```bash
gt witness status myproject
gt witness status --all
```

---

### `gt witness attach`

Attach to the Witness tmux session.

```bash
gt witness attach <rig>
```

---

### `gt witness restart`

Restart the Witness.

```bash
gt witness restart <rig>
```

---

## Refinery

The Refinery processes the merge queue for a rig, rebasing, validating, and merging work branches onto main. If conflicts arise, it spawns a fresh polecat to re-implement.

### `gt refinery start`

Start the Refinery agent for a rig.

```bash
gt refinery start <rig> [options]
```

**Options:**

| Flag | Description |
|------|-------------|
| `--attach` | Start and attach to the session |
| `--agent <runtime>` | Agent runtime to use |

**Example:**

```bash
gt refinery start myproject
```

---

### `gt refinery stop`

Stop the Refinery agent.

```bash
gt refinery stop <rig> [options]
```

**Options:**

| Flag | Description |
|------|-------------|
| `--force` | Force stop without graceful shutdown |

---

### `gt refinery status`

Show Refinery status for a rig.

```bash
gt refinery status [rig] [options]
```

**Options:**

| Flag | Description |
|------|-------------|
| `--all` | Show all Refineries across all rigs |
| `--json` | Output in JSON format |

---

### `gt refinery attach`

Attach to the Refinery tmux session.

```bash
gt refinery attach <rig>
```

---

### `gt refinery restart`

Restart the Refinery.

```bash
gt refinery restart <rig>
```

---

### `gt refinery queue`

Show the merge queue.

```bash
gt refinery queue [rig]
```

---

### `gt refinery ready`

List MRs ready for processing (unclaimed and unblocked).

```bash
gt refinery ready [rig]
```

---

### `gt refinery blocked`

List MRs blocked by open tasks.

```bash
gt refinery blocked [rig]
```

---

## Polecats

Polecats are ephemeral worker agents. They spawn, execute a single task, submit their work, and exit. Managed by the Witness.

### `gt polecat list`

List all polecats.

```bash
gt polecat list [options]
```

**Options:**

| Flag | Description |
|------|-------------|
| `--rig <name>` | Filter to a specific rig |
| `--status <state>` | Filter by status: `running`, `stalled`, `zombie`, `completed` |
| `--json` | Output in JSON format |

**Example:**

```bash
# List all polecats
gt polecat list

# List running polecats in a rig
gt polecat list --rig myproject --status running
```

**Sample output:**

```
NAME     RIG          STATUS    BEAD       AGE     BRANCH
toast    myproject    running   gt-abc12   15m     fix/login-bug
alpha    myproject    running   gt-def34   10m     feat/email-validation
bravo    docs         running   gt-ghi56   5m      docs/update-readme
```

---

### `gt polecat status`

Show detailed status of a specific polecat.

```bash
gt polecat status <name> [options]
```

**Options:**

| Flag | Description |
|------|-------------|
| `--json` | Output in JSON format |

**Example:**

```bash
gt polecat status toast
```

---

### `gt polecat nuke`

Destroy a polecat and clean up its resources.

```bash
gt polecat nuke <name> [options]
```

**Description:** Terminates the polecat process, removes its worktree, and cleans up all associated state. Used for zombie polecats or when a task needs to be reassigned.

**Options:**

| Flag | Description |
|------|-------------|
| `--force` | Skip confirmation |
| `--keep-branch` | Preserve the git branch |

**Example:**

```bash
gt polecat nuke toast
gt polecat nuke toast --force
```

:::warning

Nuking a polecat destroys all uncommitted work in its worktree. Ensure the polecat has committed or pushed its changes before nuking.

:::

---

### `gt polecat gc`

Garbage collect finished polecat directories.

```bash
gt polecat gc [options]
```

**Description:** Cleans up directories and branches from polecats that have completed their work or have been abandoned.

**Options:**

| Flag | Description |
|------|-------------|
| `--rig <name>` | Garbage collect for a specific rig |
| `--all` | Garbage collect across all rigs |
| `--dry-run` | Show what would be cleaned without doing it |
| `--age <duration>` | Only clean up polecats older than this (default: `1h`) |

**Example:**

```bash
gt polecat gc --all
gt polecat gc --rig myproject --dry-run
```

---

### `gt polecat stale`

Detect stale polecats that may need cleanup.

```bash
gt polecat stale [options]
```

**Options:**

| Flag | Description |
|------|-------------|
| `--rig <name>` | Check a specific rig |
| `--age <duration>` | Stale threshold (default: `30m`) |
| `--json` | Output in JSON format |

**Example:**

```bash
gt polecat stale
gt polecat stale --age 15m
```

---

### `gt polecat remove`

Remove polecats from a rig.

```bash
gt polecat remove <name>... [options]
```

**Example:**

```bash
gt polecat remove toast
```

---

### `gt polecat identity`

Manage polecat identities.

```bash
gt polecat identity [options]
```

---

### `gt polecat check-recovery`

Check if a polecat needs recovery vs is safe to nuke.

```bash
gt polecat check-recovery <name>
```

---

### `gt polecat git-state`

Show git state for pre-kill verification.

```bash
gt polecat git-state <name>
```

---

## Dogs

Dogs are reusable agents that handle infrastructure and cross-rig tasks. They persist between tasks, unlike ephemeral polecats.

### `gt dog list`

List all dogs and their current status.

```bash
gt dog list [options]
```

**Options:**

| Flag | Description |
|------|-------------|
| `--json` | Output in JSON format |

**Example:**

```bash
gt dog list
```

**Sample output:**

```
NAME     STATUS    CURRENT TASK     SINCE
boot     idle      -                -
fetch    running   sync-upstream    5m
lint     idle      -                -
```

---

### `gt dog status`

Show detailed status of a specific dog.

```bash
gt dog status <name> [options]
```

**Options:**

| Flag | Description |
|------|-------------|
| `--json` | Output in JSON format |

**Example:**

```bash
gt dog status boot
```

---

### `gt dog add`

Register a new dog agent.

```bash
gt dog add <name> [options]
```

**Description:** Creates a new dog with a specific name and optional configuration. Dogs persist in the `deacon/dogs/` directory.

**Options:**

| Flag | Description |
|------|-------------|
| `--agent <runtime>` | Agent runtime for this dog |
| `--role <purpose>` | Dog's specialization (e.g., `triage`, `infrastructure`) |

**Example:**

```bash
gt dog add fetch --role infrastructure
gt dog add lint --agent claude
```

---

## Boot

The Boot agent is a special triage dog that spawns to assess and route incoming work.

### `gt boot spawn`

Spawn the Boot triage agent.

```bash
gt boot spawn [options]
```

**Description:** Starts the Boot dog to perform triage on pending work items, assess complexity, and recommend assignment strategies.

**Options:**

| Flag | Description |
|------|-------------|
| `--attach` | Attach to the Boot session |

**Example:**

```bash
gt boot spawn
```

---

### `gt boot status`

Show Boot agent status.

```bash
gt boot status [options]
```

**Options:**

| Flag | Description |
|------|-------------|
| `--json` | Output in JSON format |

---

## Crew

Crew workers are persistent workspaces for human developers. Unlike ephemeral polecats (Witness-managed, auto-nuked), crew workspaces are user-managed and persist until explicitly removed. They are full git clones with Gas Town integration (mail, nudge, handoff).

### `gt crew start`

Start crew worker(s) in a rig.

```bash
gt crew start <name> [options]
```

**Options:**

| Flag | Description |
|------|-------------|
| `--attach` | Start and attach to the session |
| `--agent <runtime>` | Agent runtime to use |

**Example:**

```bash
gt crew start myproject dave --attach
```

---

### `gt crew stop`

Stop a crew agent session.

```bash
gt crew stop <rig> <member> [options]
```

**Options:**

| Flag | Description |
|------|-------------|
| `--force` | Force stop |

---

### `gt crew add`

Add a new crew member workspace to a rig.

```bash
gt crew add <rig> <name> [options]
```

**Description:** Creates a new persistent git clone for a human developer within the specified rig.

**Options:**

| Flag | Description |
|------|-------------|
| `--branch <name>` | Check out a specific branch |
| `--agent <runtime>` | Default agent runtime for this crew member |

**Example:**

```bash
gt crew add myproject dave
gt crew add myproject emma --branch develop
```

---

### `gt crew list`

List crew members.

```bash
gt crew list [rig] [options]
```

**Options:**

| Flag | Description |
|------|-------------|
| `--all` | List crew across all rigs |
| `--json` | Output in JSON format |

**Example:**

```bash
gt crew list myproject
gt crew list --all
```

---

### `gt crew at`

Show what a crew member is currently working on.

```bash
gt crew at <rig> <member>
```

**Example:**

```bash
gt crew at myproject dave
```

---

### `gt crew remove`

Remove a crew member workspace.

```bash
gt crew remove <rig> <name> [options]
```

**Options:**

| Flag | Description |
|------|-------------|
| `--force` | Skip confirmation and force removal |
| `--keep-branch` | Preserve the git branch |

**Example:**

```bash
gt crew remove myproject dave
```

---

### `gt crew refresh`

Context cycle with mail-to-self handoff.

```bash
gt crew refresh <rig> <member> [options]
```

**Options:**

| Flag | Description |
|------|-------------|
| `--rebase` | Rebase local changes onto latest main |
| `--all` | Refresh all crew workspaces in the rig |

**Example:**

```bash
gt crew refresh myproject dave --rebase
```

---

### `gt crew restart`

Kill and restart a crew workspace session.

```bash
gt crew restart <rig> <member> [options]
```

**Description:** Stops and restarts the agent session for a crew member fresh.

**Options:**

| Flag | Description |
|------|-------------|
| `--agent <runtime>` | Switch to a different agent runtime |

**Example:**

```bash
gt crew restart myproject dave
```

---

### `gt crew status`

Show detailed workspace status.

```bash
gt crew status <name>
```

**Example:**

```bash
gt crew status dave
```

---

### `gt crew rename`

Rename a crew workspace.

```bash
gt crew rename <old-name> <new-name>
```

**Example:**

```bash
gt crew rename dave david
```

---

### `gt crew pristine`

Sync crew workspaces with remote.

```bash
gt crew pristine <name>
```

**Example:**

```bash
gt crew pristine dave
```
