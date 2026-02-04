---
title: "Rig Management"
sidebar_position: 7
description: "Commands for adding, configuring, starting, stopping, and managing rigs. A rig is a project container that wraps a git repository with the full Gas Town agen..."
---

# Rig Management

Commands for adding, configuring, starting, stopping, and managing rigs. A rig is a project container that wraps a git repository with the full Gas Town agent infrastructure.

---

### `gt rig list`

List all rigs in the town.

```bash
gt rig list [options]
```

**Description:** Shows all rigs with their current status, agent counts, and activity summary.

**Options:**

| Flag | Description |
|------|-------------|
| `--status <status>` | Filter: `active`, `parked`, `docked`, `stopped` |
| `--json` | Output in JSON format |
| `--verbose` | Show extended details |

**Example:**

```bash
gt rig list
gt rig list --status active
```

**Sample output:**

```
RIG          STATUS    POLECATS   QUEUE   OPEN BEADS   BRANCH
myproject    active    3          2       7            main
docs         active    1          0       2            main
backend      parked    0          0       4            main
```

---

### `gt rig add`

Add a new rig to the town.

```bash
gt rig add <name> <git-url> [options]
```

**Description:** Clones the repository, creates the rig directory structure, initializes beads, and sets up agent workspaces (witness, refinery, mayor, polecats).

**Options:**

| Flag | Description |
|------|-------------|
| `--adopt` | Adopt an existing directory instead of creating new |
| `--branch <name>` | Default branch name (default: auto-detected from remote) |
| `--force` | With `--adopt`, register even if git remote cannot be detected |
| `--local-repo <path>` | Local repo path to share git objects (optional) |
| `--prefix <prefix>` | Beads issue prefix (default: derived from name) |
| `--url <url>` | Git remote URL for `--adopt` (default: auto-detected) |

**Example:**

```bash
# Add a rig
gt rig add myproject https://github.com/you/repo.git

# Add with SSH URL and specific branch
gt rig add backend git@github.com:you/backend.git --branch develop

# Adopt an existing directory
gt rig add myproject --adopt --url https://github.com/you/repo.git
```

**Created structure:**

```
~/gt/myproject/
├── config.json      # Rig configuration
├── .beads/          # Rig-level issue tracking
├── plugins/         # Rig-level plugins
├── refinery/rig/    # Canonical main clone
├── mayor/rig/       # Mayor's working copy
├── crew/            # Human developer workspaces
├── witness/         # Health monitor state
└── polecats/        # Ephemeral worker directories
```

---

### `gt rig remove`

Remove a rig from the registry.

```bash
gt rig remove <name> [options]
```

**Description:** Remove a rig from the registry. Does not delete files on disk.

**Example:**

```bash
gt rig remove myproject
```

---

### `gt rig start`

Start witness and refinery on patrol for one or more rigs.

```bash
gt rig start <name> [options]
```

**Description:** Start witness and refinery on patrol for one or more rigs.

**Example:**

```bash
gt rig start myproject
```

---

### `gt rig stop`

Stop one or more rigs (shutdown semantics).

```bash
gt rig stop <name> [options]
```

**Description:** Stop one or more rigs (shutdown semantics).

**Options:**

| Flag | Description |
|------|-------------|
| `--force` | Force stop without graceful shutdown |

**Example:**

```bash
gt rig stop myproject
gt rig stop myproject --force
```

---

### `gt rig shutdown`

Gracefully stop all rig agents.

```bash
gt rig shutdown <name> [options]
```

**Description:** Gracefully stop all rig agents.

**Options:**

| Flag | Description |
|------|-------------|
| `--force` | Skip confirmation and force shutdown |

**Example:**

```bash
gt rig shutdown myproject
```

---

### `gt rig status`

Show detailed status for a rig.

```bash
gt rig status <name> [options]
```

**Description:** Displays comprehensive rig information including agent status, polecat activity, merge queue depth, open beads, and resource usage.

**Options:**

| Flag | Description |
|------|-------------|
| `--json` | Output in JSON format |
| `--verbose` | Show extended details |

**Example:**

```bash
gt rig status myproject
```

**Sample output:**

```
Rig: myproject
Repository: https://github.com/you/repo.git
Branch: main
Status: active

Agents:
  Witness:  running (PID 1240)
  Refinery: running (PID 1250)

Polecats: 3 running
  toast    running   gt-abc12   fix/login-bug          15m
  alpha    running   gt-def34   feat/email-validation   10m
  bravo    running   gt-ghi56   refactor/auth-module    5m

Merge Queue: 2 pending, 1 processing
Open Beads: 7
Active Convoy: hq-cv-001 (2/3)
```

---

### `gt rig reset`

Reset rig state (handoff content, mail, stale issues).

```bash
gt rig reset <name> [options]
```

**Description:** Reset rig state (handoff content, mail, stale issues).

**Options:**

| Flag | Description |
|------|-------------|
| `--force` | Skip confirmation |

**Example:**

```bash
gt rig reset myproject
gt rig reset myproject --force
```

---

### `gt rig boot`

Start witness and refinery for a rig.

```bash
gt rig boot <name> [options]
```

**Description:** Start witness and refinery for a rig.

**Example:**

```bash
gt rig boot myproject
```

---

### `gt rig reboot`

Reboot a running rig.

```bash
gt rig reboot <name> [options]
```

**Description:** Performs a stop-then-start cycle for the rig. Agents are stopped gracefully, state is preserved, and agents are restarted.

**Options:**

| Flag | Description |
|------|-------------|
| `--force` | Force reboot without waiting for graceful shutdown |

**Example:**

```bash
gt rig reboot myproject
```

---

### `gt rig restart`

Restart one or more rigs.

```bash
gt rig restart <name> [options]
```

**Description:** Restart one or more rigs (stop then start).

**Example:**

```bash
gt rig restart myproject
```

---

### `gt rig park`

Park a rig (suspend without removing).

```bash
gt rig park <name> [options]
```

**Description:** Stops all agents and marks the rig as parked. Parked rigs consume no resources but retain all configuration and state. Work can be resumed later with `gt rig unpark`.

**Options:**

| Flag | Description |
|------|-------------|
| `--reason <text>` | Reason for parking |

**Example:**

```bash
gt rig park backend --reason "Waiting for API spec finalization"
```

---

### `gt rig unpark`

Resume a parked rig.

```bash
gt rig unpark <name> [options]
```

**Description:** Restarts agents and resumes work in a previously parked rig.

**Example:**

```bash
gt rig unpark backend
```

---

### `gt rig dock`

Dock a rig (deep storage mode).

```bash
gt rig dock <name> [options]
```

**Description:** Places a rig in deep storage. Docking is more aggressive than parking: it cleans up worktrees, removes polecat directories, and minimizes disk usage while preserving configuration and beads history.

**Options:**

| Flag | Description |
|------|-------------|
| `--force` | Skip confirmation |

**Example:**

```bash
gt rig dock backend
```

---

### `gt rig undock`

Restore a docked rig.

```bash
gt rig undock <name> [options]
```

**Description:** Restores a docked rig by recreating worktrees, agent directories, and starting agents.

**Example:**

```bash
gt rig undock backend
```

---

### `gt rig config`

View or modify rig configuration.

```bash
gt rig config <name> [key] [value] [options]
```

**Description:** Without a key, shows all configuration for the rig. With a key, shows that specific setting. With a key and value, sets the configuration.

**Options:**

| Flag | Description |
|------|-------------|
| `--json` | Output in JSON format |
| `--reset` | Reset configuration to defaults |

**Common configuration keys (example defaults; actual defaults may vary):**

| Key | Description | Default |
|-----|-------------|---------|
| `agent` | Default agent runtime | `claude` |
| `max_polecats` | Maximum concurrent polecats | `5` |
| `merge_strategy` | Merge strategy: `rebase`, `merge`, `squash` | `rebase` |
| `auto_witness` | Auto-start witness on rig start | `true` |
| `auto_refinery` | Auto-start refinery on rig start | `true` |
| `branch` | Main branch name | `main` |

**Example:**

```bash
# Show all config
gt rig config myproject

# Get a specific setting
gt rig config myproject max_polecats

# Set a value
gt rig config myproject max_polecats 8

# Reset to defaults
gt rig config myproject --reset
```

---

### `gt rig settings`

Manage advanced rig settings.

```bash
gt rig settings <name> [options]
```

**Description:** Access and modify advanced rig settings that are not part of the standard configuration. Includes validation rules, plugin settings, and integration configuration.

**Options:**

| Flag | Description |
|------|-------------|
| `--show` | Display all settings |
| `--set <key=value>` | Set a setting |
| `--unset <key>` | Remove a setting |
| `--json` | Output in JSON format |

**Example:**

```bash
# Show all settings
gt rig settings myproject --show

# Set a custom setting
gt rig settings myproject --set "validation.timeout=300"

# Remove a setting
gt rig settings myproject --unset "validation.timeout"
```
