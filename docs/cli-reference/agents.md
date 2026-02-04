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

**Alias:** `gt ag`

**Description:** Display a popup menu of core Gas Town agent sessions. Shows Mayor, Deacon, Witnesses, Refineries, and Crew workers. Polecats are hidden (use `gt polecat list` to see them).

**Options:**

| Flag | Description |
|------|-------------|
| `--all`, `-a` | Include polecats in the menu |

**Subcommands:**

| Subcommand | Description |
|------------|-------------|
| `gt agents check` | Check for identity collisions |
| `gt agents fix` | Fix identity collisions |
| `gt agents list` | List agent sessions (no popup) |
| `gt agents state` | Get or set operational state |

**Example:**

```bash
# Open the agent session popup menu
gt agents

# Include polecats in the menu
gt agents --all

# List agent sessions without the popup
gt agents list

# Check for identity collisions
gt agents check
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

The Deacon ("daemon beacon") is the only agent that receives mechanical heartbeats from the daemon. It monitors system health across all rigs, watches all Witnesses, manages Dogs, and handles lifecycle requests.

**Alias:** `gt dea`

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

### `gt deacon attach`

Attach to the Deacon session.

```bash
gt deacon attach
```

---

### `gt deacon restart`

Restart the Deacon session.

```bash
gt deacon restart [options]
```

---

### `gt deacon heartbeat`

Update the Deacon heartbeat.

```bash
gt deacon heartbeat
```

---

### `gt deacon pause` / `gt deacon resume`

Pause or resume patrol actions.

```bash
gt deacon pause
gt deacon resume
```

---

### `gt deacon cleanup-orphans`

Clean up orphaned claude subagent processes.

```bash
gt deacon cleanup-orphans
```

---

### `gt deacon force-kill`

Force-kill an unresponsive agent session.

```bash
gt deacon force-kill <session>
```

---

### `gt deacon health-check` / `gt deacon health-state`

Health monitoring commands.

```bash
gt deacon health-check
gt deacon health-state
```

---

### `gt deacon stale-hooks`

Find and unhook stale hooked beads.

```bash
gt deacon stale-hooks
```

---

### `gt deacon zombie-scan`

Find zombie Claude processes.

```bash
gt deacon zombie-scan
```

---

### `gt deacon trigger-pending`

Trigger pending polecat spawns.

```bash
gt deacon trigger-pending
```

---

## Witness

Witnesses are per-rig supervisors that monitor polecats, detect stalls, and manage worker lifecycle within a single rig.

### `gt witness start`

Start a Witness agent for the current rig.

```bash
gt witness start [options]
```

**Description:** Starts the Witness for the current rig (auto-detected from working directory). Does not take a `<rig>` argument.

**Options:**

| Flag | Description |
|------|-------------|
| `--attach` | Start and attach to the session |
| `--agent <runtime>` | Agent runtime to use |

**Example:**

```bash
gt witness start
```

---

### `gt witness stop`

Stop a Witness agent.

```bash
gt witness stop [options]
```

**Description:** Stops the Witness for the current rig (auto-detected from working directory). Does not take a `<rig>` argument.

**Options:**

| Flag | Description |
|------|-------------|
| `--force` | Force stop without graceful shutdown |

**Example:**

```bash
gt witness stop
```

---

### `gt witness attach`

Attach to the Witness session.

```bash
gt witness attach
```

---

### `gt witness restart`

Restart the Witness session.

```bash
gt witness restart [options]
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

## Refinery

The Refinery processes the merge queue for a rig, rebasing, validating, and merging pull requests onto the main branch.

**Alias:** `gt ref`

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

### `gt refinery attach`

Attach to the Refinery session.

```bash
gt refinery attach
```

---

### `gt refinery restart`

Restart the Refinery session.

```bash
gt refinery restart [options]
```

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

### `gt refinery blocked`

List MRs blocked by open tasks.

```bash
gt refinery blocked
```

---

### `gt refinery claim`

Claim an MR for processing.

```bash
gt refinery claim <mr>
```

---

### `gt refinery queue`

Show the merge queue.

```bash
gt refinery queue
```

---

### `gt refinery ready`

List MRs ready for processing.

```bash
gt refinery ready
```

---

### `gt refinery release`

Release a claimed MR.

```bash
gt refinery release <mr>
```

---

### `gt refinery unclaimed`

List unclaimed MRs.

```bash
gt refinery unclaimed
```

---

## Polecats

Polecats are ephemeral worker agents. They spawn, execute a single task, submit their work, and exit. Managed by the Witness.

**Aliases:** `gt polecat`, `gt polecats`

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

List polecats that appear to be stalled or unresponsive.

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

### `gt polecat identity`

Manage polecat identities.

```bash
gt polecat identity [options]
```

---

### `gt polecat remove`

Remove polecats from a rig.

```bash
gt polecat remove <name> [options]
```

---

### `gt polecat sync`

Sync beads for a polecat.

```bash
gt polecat sync <name>
```

:::note

This subcommand is deprecated with the Dolt backend.

:::

---

## Dogs

Dogs are reusable workers for infrastructure and cleanup. Cats build features (one rig, ephemeral). Dogs clean up messes (cross-rig, reusable).

**Alias:** `gt dogs`

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

**Example:**

```bash
gt dog add fetch
gt dog add lint --agent claude
```

---

### `gt dog call`

Wake idle dog(s) for work.

```bash
gt dog call [name]
```

---

### `gt dog dispatch`

Dispatch plugin execution to a dog.

```bash
gt dog dispatch <name> <plugin>
```

---

### `gt dog done`

Mark dog as done and return to idle.

```bash
gt dog done <name>
```

---

### `gt dog remove`

Remove dogs from the kennel.

```bash
gt dog remove <name> [options]
```

---

## Boot

Boot is a special dog that runs fresh on each daemon tick. It observes the system state and decides whether to start/wake/nudge/interrupt the Deacon.

### `gt boot spawn`

Spawn the Boot agent.

```bash
gt boot spawn
```

**Description:** Starts the Boot dog to observe system state and decide whether to start, wake, nudge, or interrupt the Deacon.

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

### `gt boot triage`

Run Boot triage.

```bash
gt boot triage
```

---

## Crew

Crew members are persistent workspaces for human developers. They get their own git clone within a rig and can run agent sessions.

### `gt crew start`

Start an agent session in a crew workspace.

```bash
gt crew start <name> [options]
```

**Description:** Starts a crew agent session. The rig is auto-detected from the current working directory.

**Options:**

| Flag | Description |
|------|-------------|
| `--attach` | Start and attach to the session |
| `--agent <runtime>` | Agent runtime to use |

**Example:**

```bash
gt crew start dave --attach
```

---

### `gt crew stop`

Stop a crew agent session.

```bash
gt crew stop <name> [options]
```

**Options:**

| Flag | Description |
|------|-------------|
| `--force` | Force stop |

---

### `gt crew add`

Add a new crew member workspace to a rig.

```bash
gt crew add <name> [options]
```

**Description:** Creates a new persistent git clone for a human developer within the current rig.

**Options:**

| Flag | Description |
|------|-------------|
| `--agent <runtime>` | Default agent runtime for this crew member |

**Example:**

```bash
gt crew add dave
gt crew add emma
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
gt crew at <name>
```

**Example:**

```bash
gt crew at dave
```

---

### `gt crew remove`

Remove a crew member workspace.

```bash
gt crew remove <name> [options]
```

**Options:**

| Flag | Description |
|------|-------------|
| `--force` | Skip confirmation and force removal |
| `--keep-branch` | Preserve the git branch |

**Example:**

```bash
gt crew remove dave
```

---

### `gt crew refresh`

Refresh a crew workspace by pulling latest changes.

```bash
gt crew refresh <name> [options]
```

**Options:**

| Flag | Description |
|------|-------------|
| `--rebase` | Rebase local changes onto latest main |
| `--all` | Refresh all crew workspaces in the rig |

**Example:**

```bash
gt crew refresh dave --rebase
```

---

### `gt crew restart`

Restart a crew agent session.

```bash
gt crew restart <name> [options]
```

**Description:** Stops and restarts the agent session for a crew member, preserving hook state and context.

**Options:**

| Flag | Description |
|------|-------------|
| `--agent <runtime>` | Switch to a different agent runtime |

**Example:**

```bash
gt crew restart dave
```

---

### `gt crew pristine`

Sync crew workspaces with remote.

```bash
gt crew pristine [name]
```

---

### `gt crew rename`

Rename a crew workspace.

```bash
gt crew rename <old-name> <new-name>
```

---

### `gt crew status`

Show detailed workspace status.

```bash
gt crew status [name]
```
