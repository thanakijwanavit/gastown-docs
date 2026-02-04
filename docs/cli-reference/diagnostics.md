---
title: "Diagnostics"
sidebar_position: 9
description: "Commands for monitoring, auditing, and troubleshooting Gas Town. These tools provide visibility into system health, agent activity, resource usage, and opera..."
---

# Diagnostics

Commands for monitoring, auditing, and troubleshooting Gas Town. These tools provide visibility into system health, agent activity, resource usage, and operational state.

---

## Activity & Monitoring

### `gt activity`

Emit and view activity events.

```bash
gt activity [command]
gt activity emit [options]
```

**Description:** Emit and view activity events for the Gas Town activity feed. Events are written to `~/gt/.events.jsonl` and can be viewed with `gt feed`.

**Subcommands:**

| Command | Description |
|---------|-------------|
| `emit` | Emit an activity event |

**Example:**

```bash
# Emit an activity event
gt activity emit

# View activity events
gt activity
```

---

### `gt audit`

Query provenance data.

```bash
gt audit [options]
```

**Description:** Queries provenance data across git commits, beads, and events. Provides an audit trail of who did what, when, and why across the workspace.

**Options:**

| Flag | Description |
|------|-------------|
| `--actor <name>` | Filter by actor (agent address or partial match) |
| `--since <duration>` | Show events since duration (e.g., `1h`, `24h`, `7d`) |
| `--limit`, `-n <count>` | Maximum number of entries to show (default: `50`) |
| `--json` | Output as JSON |

**Example:**

```bash
# Recent audit trail
gt audit

# Audit trail for a specific actor
gt audit --actor polecat/toast

# Last 7 days, limited results
gt audit --since 7d --limit 20

# JSON output for scripting
gt audit --json
```

---

### `gt feed`

Real-time activity dashboard.

```bash
gt feed [options]
```

**Description:** Opens a real-time TUI dashboard showing the activity feed. The dashboard includes an agent tree, convoy panel, and event stream. Press `Ctrl+C` to exit.

**Options:**

| Flag | Description |
|------|-------------|
| `--follow`, `-f` | Stream events in real-time (default) |
| `--no-follow` | Show events once and exit |
| `--plain` | Use plain text output instead of TUI |
| `--window`, `-w` | Open in dedicated tmux window |
| `--since <duration>` | Show events since duration (e.g., `1h`, `30m`) |
| `--rig <name>` | Run from specific rig's beads directory |
| `--limit`, `-n <count>` | Maximum number of events (default: `100`) |
| `--mol <id>` | Filter by molecule/issue ID prefix |
| `--type <type>` | Filter by event type |

**Example:**

```bash
# Open the TUI dashboard
gt feed

# Plain text output, no follow
gt feed --plain --no-follow

# Open in a dedicated tmux window
gt feed --window

# Filter by molecule
gt feed --mol gt-abc12

# Show events from the last hour for a specific rig
gt feed --since 1h --rig myproject
```

---

### `gt trail`

Show recent activity in the workspace.

```bash
gt trail [command] [options]
```

**Aliases:** `recent`, `recap`

**Description:** Show recent activity in the workspace. Without a subcommand, shows recent commits from agents.

**Subcommands:**

| Command | Description |
|---------|-------------|
| `commits` | Show recent commits |
| `beads` | Show recent bead activity |
| `hooks` | Show recent hook activity |

**Options:**

| Flag | Description |
|------|-------------|
| `--since <duration>` | Show activity since duration (e.g., `1h`, `24h`) |
| `--limit <n>` | Maximum number of entries to show |
| `--json` | Output as JSON |
| `--all` | Show all entries |

**Example:**

```bash
# Recent commits from agents
gt trail

# Recent bead activity
gt trail beads

# Recent hooks, last 24 hours
gt trail hooks --since 24h

# Show all recent commits as JSON
gt trail commits --all --json
```

---

### `gt log`

View system logs.

```bash
gt log [options]
```

**Description:** Accesses the raw event log (`.events.jsonl`) with filtering and formatting options. More detailed than `gt activity` -- includes internal system events.

**Options:**

| Flag | Description |
|------|-------------|
| `--level <level>` | Filter: `debug`, `info`, `warn`, `error` |
| `--since <duration>` | Time filter |
| `--limit <n>` | Maximum entries |
| `--follow`, `-f` | Follow the log in real time |
| `--json` | Raw JSON output |

**Example:**

```bash
# Recent errors
gt log --level error

# Follow log in real time
gt log -f

# Debug output for the last 30 minutes
gt log --level debug --since 30m
```

---

### `gt doctor`

Diagnose system health issues.

```bash
gt doctor [options]
```

**Description:** Runs a comprehensive health check of the Gas Town installation, verifying dependencies, configuration, agent state, database integrity, and common issues.

**Options:**

| Flag | Description |
|------|-------------|
| `--fix` | Attempt to automatically fix issues |
| `--verbose`, `-v` | Show detailed output |
| `--rig <name>` | Check specific rig only |
| `--restart-sessions` | Restart patrol sessions when fixing |
| `--slow [threshold]` | Highlight slow checks (optional threshold) |

**Example:**

```bash
# Run health check
gt doctor

# Run and attempt fixes
gt doctor --fix

# Verbose check for a specific rig
gt doctor --verbose --rig myproject

# Fix and restart sessions
gt doctor --fix --restart-sessions
```

**Sample output:**

```
Gas Town Doctor
===============

[OK]  Git version
[OK]  Tmux version
[OK]  Claude Code available
[OK]  Workspace structure valid
[OK]  Beads database integrity
[OK]  Sessions healthy
[WARN] Stale polecat worktree: myproject/polecats/toast (2d old)

6 checks passed, 1 warning, 0 errors
```

:::tip

Run `gt doctor` after installation, after upgrading Gas Town, or whenever something seems wrong. It catches most common configuration issues.

:::

---

### `gt dashboard`

Start the convoy tracking web dashboard.

```bash
gt dashboard [options]
```

**Description:** Start a web server that displays the convoy tracking dashboard. The dashboard shows real-time convoy status with progress tracking and auto-refresh via htmx.

**Options:**

| Flag | Description |
|------|-------------|
| `--port <port>` | HTTP port to listen on (default: `8080`) |
| `--open` | Open browser automatically |

**Example:**

```bash
# Start the dashboard on default port
gt dashboard

# Start on a custom port and open browser
gt dashboard --port 3000 --open
```

---

### `gt costs`

Display Claude Code session costs.

```bash
gt costs [command] [options]
```

**Description:** Display costs for Claude Code sessions in Gas Town. Costs are calculated from Claude Code transcript files.

**Subcommands:**

| Command | Description |
|---------|-------------|
| `record` | Record cost data from transcripts |
| `digest` | Generate a cost digest |
| `migrate` | Migrate cost data format |

**Options:**

| Flag | Description |
|------|-------------|
| `--today` | Show today's total from session events |
| `--week` | Show this week's total |
| `--by-rig` | Show breakdown by rig |
| `--by-role` | Show breakdown by role |
| `--json` | Output as JSON |
| `--verbose`, `-v` | Show debug output |

**Example:**

```bash
# Today's costs
gt costs --today

# This week's costs broken down by rig
gt costs --week --by-rig

# Costs broken down by role
gt costs --by-role

# JSON output for scripting
gt costs --today --json
```

---

### `gt cleanup`

Clean up temporary files and stale resources.

```bash
gt cleanup [options]
```

**Description:** Removes temporary files, stale worktrees, dead session artifacts, and other accumulated debris. A more action-oriented companion to `gt stale`.

**Options:**

| Flag | Description |
|------|-------------|
| `--rig <name>` | Clean up a specific rig |
| `--all` | Clean up across all rigs |
| `--dry-run` | Show what would be cleaned without doing it |
| `--force` | Skip confirmation |
| `--age <duration>` | Only clean items older than this (default: `24h`) |

**Example:**

```bash
# Preview cleanup
gt cleanup --dry-run

# Clean up everything
gt cleanup --all --force

# Clean up a specific rig
gt cleanup --rig myproject --age 12h
```

---

### `gt patrol digest`

Generate a patrol cycle digest.

```bash
gt patrol digest [options]
```

**Description:** Summarizes the results of recent patrol cycles run by persistent agents (Deacon, Witnesses, Refinery). Shows what was detected and what actions were taken.

**Options:**

| Flag | Description |
|------|-------------|
| `--since <duration>` | Time period (default: `1h`) |
| `--agent <name>` | Filter to a specific agent's patrols |
| `--json` | Output in JSON format |

**Example:**

```bash
gt patrol digest
gt patrol digest --since 6h --agent witness
```

---

## Orphan Management

### `gt orphans`

Find orphaned resources.

```bash
gt orphans [options]
```

**Description:** Identifies orphaned resources across the town -- processes without parent agents, worktrees without polecats, branches without beads, and other disconnected artifacts.

**Options:**

| Flag | Description |
|------|-------------|
| `--json` | Output in JSON format |
| `--verbose` | Show detailed information about each orphan |

**Example:**

```bash
gt orphans
```

**Sample output:**

```
Orphaned Resources
==================

Processes (2):
  PID 4521  claude session (no parent agent)
  PID 4789  claude session (no parent agent)

Worktrees (1):
  myproject/polecats/ghost/  (no active polecat)

Branches (3):
  fix/old-bug         (no associated bead)
  feat/abandoned       (no associated bead)
  tmp/experiment       (no associated bead)
```

---

### `gt orphans procs`

List orphaned processes specifically.

```bash
gt orphans procs [options]
```

**Options:**

| Flag | Description |
|------|-------------|
| `--json` | Output in JSON format |

**Example:**

```bash
gt orphans procs
```

---

### `gt orphans kill`

Terminate orphaned processes.

```bash
gt orphans kill [options]
```

**Description:** Kills orphaned processes that have no parent agent managing them. These are typically leftover sessions from crashed agents.

**Options:**

| Flag | Description |
|------|-------------|
| `--force` | Kill without confirmation |
| `--dry-run` | Show what would be killed |

**Example:**

```bash
gt orphans kill --dry-run
gt orphans kill --force
```

:::warning

Verify orphans are truly orphaned before killing. Use `gt orphans procs` first to review, then `gt orphans kill --dry-run` to preview the action.

:::

---

## Peek & Sessions

### `gt peek`

Capture recent terminal output from an agent session.

```bash
gt peek <rig/polecat> [count] [options]
```

**Description:** Capture and display recent terminal output from an agent session. Ergonomic alias for `gt session capture`.

**Options:**

| Flag | Description |
|------|-------------|
| `--lines`, `-n <count>` | Number of lines to capture (default: `100`) |

**Example:**

```bash
# Capture last 100 lines from an agent
gt peek greenplace/furiosa

# Capture last 50 lines
gt peek greenplace/furiosa 50

# Capture with explicit line count flag
gt peek greenplace/furiosa --lines 200
```

---

### `gt session list`

List all agent sessions.

```bash
gt session list [options]
```

**Options:**

| Flag | Description |
|------|-------------|
| `--status <status>` | Filter: `running`, `stopped`, `crashed` |
| `--rig <name>` | Filter by rig |
| `--json` | Output in JSON format |

**Example:**

```bash
gt session list
gt session list --status running
```

---

### `gt session status`

Show status of a specific session.

```bash
gt session status <session-id> [options]
```

**Options:**

| Flag | Description |
|------|-------------|
| `--json` | Output in JSON format |

**Example:**

```bash
gt session status sess-abc123
```

---

### `gt session start`

Start a new agent session.

```bash
gt session start <agent> [options]
```

**Description:** Starts a new session for the specified agent. Lower-level than the agent-specific start commands (e.g., `gt mayor start`).

**Options:**

| Flag | Description |
|------|-------------|
| `--attach` | Attach to the session after starting |
| `--agent <runtime>` | Agent runtime |

**Example:**

```bash
gt session start witness --rig myproject
```

---

### `gt session stop`

Stop an agent session.

```bash
gt session stop <session-id> [options]
```

**Options:**

| Flag | Description |
|------|-------------|
| `--force` | Force stop |

**Example:**

```bash
gt session stop sess-abc123
```

---

### `gt session at`

Show what an agent session is currently working on.

```bash
gt session at <session-id>
```

**Description:** Quick view of the session's current task and hook state.

**Example:**

```bash
gt session at sess-abc123
```
