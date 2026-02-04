---
title: "Configuration"
sidebar_position: 10
description: "Commands for configuring agent runtimes, account settings, themes, hooks, and issue integration. These settings control how Gas Town operates at the town and..."
---

# Configuration

Commands for configuring agent runtimes, account settings, themes, hooks, and issue integration. These settings control how Gas Town operates at the town and rig levels.

---

## Agent Configuration

### `gt config agent list`

List configured agent runtimes.

```bash
gt config agent list [options]
```

**Description:** Shows all configured agent runtimes and their command mappings. Gas Town supports multiple AI coding agent runtimes.

**Options:**

| Flag | Description |
|------|-------------|
| `--json` | Output in JSON format |

**Example:**

```bash
gt config agent list
```

**Sample output:**

```
AGENT      COMMAND     STATUS      DEFAULT
claude     claude      available   *
gemini     gemini      available
codex      codex       not found
cursor     cursor      available
auggie     auggie      not found
amp        amp         not found
```

---

### `gt config agent get`

Get a specific agent runtime configuration value.

```bash
gt config agent get <agent> [key]
```

**Description:** Without a key, shows all configuration for the specified agent runtime. With a key, shows that specific setting.

**Example:**

```bash
# Show all config for claude
gt config agent get claude

# Get a specific setting
gt config agent get claude model
```

---

### `gt config agent set`

Set an agent runtime configuration value.

```bash
gt config agent set <agent> <key> <value>
```

**Description:** Configures a specific setting for an agent runtime. Use this to set command paths, model preferences, and other runtime-specific options.

**Common keys:**

| Key | Description | Example |
|-----|-------------|---------|
| `command` | Command to invoke the agent | `claude` |
| `model` | Preferred model | `claude-opus-4-5-20251101` |
| `args` | Additional arguments | `--verbose` |
| `timeout` | Session timeout | `3600` |
| `max_tokens` | Maximum token limit | `200000` |

**Example:**

```bash
# Set command for gemini
gt config agent set gemini command "gemini"

# Set model preference
gt config agent set claude model "claude-opus-4-5-20251101"

# Set custom args
gt config agent set cursor args "--no-telemetry"
```

---

### `gt config default-agent`

Get or set the default agent runtime.

```bash
gt config default-agent [agent]
```

**Description:** Without an argument, shows the current default agent. With an argument, sets the default agent runtime used when no `--agent` flag is specified.

**Example:**

```bash
# Show default
gt config default-agent
# Output: claude

# Set default to gemini
gt config default-agent gemini
```

:::tip

The default agent can be overridden at the rig level with `gt rig config <rig> agent <runtime>` or per-command with the `--agent` flag.

:::

---

### `gt config agent remove`

Remove a custom agent configuration.

```bash
gt config agent remove <name>
```

**Example:**

```bash
gt config agent remove my-custom-agent
```

---

### `gt config agent-email-domain`

Get or set the agent email domain.

```bash
gt config agent-email-domain [domain]
```

**Description:** Controls the email domain used for agent git commit identities. Default: `gastown.local`.

**Example:**

```bash
gt config agent-email-domain
gt config agent-email-domain mycompany.local
```

---

## Account Management

### `gt account`

Manage multiple Claude Code accounts for Gas Town.

```bash
gt account [subcommand]
```

**Description:** Enables switching between accounts (e.g., personal vs work) with easy account selection per spawn or globally.

**Subcommands:**

| Subcommand | Description |
|------------|-------------|
| `list` | List registered accounts |
| `add <handle>` | Add a new account |
| `default <handle>` | Set the default account |
| `status` | Show current account info |
| `switch` | Switch to a different account |

**Example:**

```bash
# List registered accounts
gt account list

# Add a new account
gt account add work

# Set default
gt account default work

# Show current account info
gt account status
```

---

## Appearance

### `gt theme`

Manage tmux status bar themes for Gas Town sessions.

```bash
gt theme [name] [options]
```

**Description:** Without arguments, shows the current theme assignment. With a name, sets the theme for the current rig.

**Subcommands:**

| Subcommand | Description |
|------------|-------------|
| `apply` | Apply theme to all running sessions in this rig |
| `cli` | View or set CLI color scheme (`dark`/`light`/`auto`) |

**Options:**

| Flag | Description |
|------|-------------|
| `--list`, `-l` | List available themes |

**Example:**

```bash
# Show current theme
gt theme

# List available themes
gt theme --list

# Set theme
gt theme forest

# Apply to running sessions
gt theme apply
```

---

## Event Hooks

### `gt hooks`

List all Claude Code hooks configured in the workspace.

```bash
gt hooks [options]
```

**Description:** Scans for `.claude/settings.json` files and displays hooks by type. This lists Claude Code hooks (not Gas Town lifecycle hooks).

**Hook types:**

| Type | Description |
|------|-------------|
| `SessionStart` | Runs when Claude session starts |
| `PreCompact` | Runs before context compaction |
| `UserPromptSubmit` | Runs before user prompt is submitted |
| `PreToolUse` | Runs before tool execution |
| `PostToolUse` | Runs after tool execution |
| `Stop` | Runs when Claude session stops |

**Subcommands:**

| Subcommand | Description |
|------------|-------------|
| `install` | Install a hook from the registry |
| `list` | List available hooks from the registry |

**Options:**

| Flag | Description |
|------|-------------|
| `--verbose`, `-v` | Show hook commands |
| `--json` | Output as JSON |

**Example:**

```bash
# List all hooks in workspace
gt hooks

# Show hook commands
gt hooks --verbose

# Install from registry
gt hooks install
```

---

## Issue Integration

### `gt issue`

Manage external issue tracker integration.

```bash
gt issue [subcommand] [options]
```

**Description:** Configure integration between Gas Town beads and external issue trackers (GitHub Issues, Jira, Linear, etc.).

**Subcommands:**

| Subcommand | Description |
|------------|-------------|
| `gt issue link <bead-id> <url>` | Link a bead to an external issue |
| `gt issue unlink <bead-id>` | Remove external issue link |
| `gt issue sync` | Sync bead status with external tracker |
| `gt issue config` | Configure issue tracker integration |

**Example:**

```bash
# Link a bead to a GitHub issue
gt issue link gt-abc12 https://github.com/you/repo/issues/42

# Configure GitHub integration
gt issue config --provider github --repo you/repo --token $GITHUB_TOKEN

# Sync all linked issues
gt issue sync
```

**Configuration options (gt issue config):**

| Flag | Description |
|------|-------------|
| `--provider <name>` | Issue provider: `github`, `jira`, `linear` |
| `--repo <repo>` | Repository identifier |
| `--project <project>` | Project identifier (Jira/Linear) |
| `--token <token>` | API token |
| `--auto-sync` | Enable automatic bidirectional sync |
| `--sync-interval <duration>` | Sync frequency (default: `15m`) |
| `--rig <name>` | Configure for a specific rig |

**Example:**

```bash
# Configure Jira integration
gt issue config --provider jira --project MYPROJ --token $JIRA_TOKEN --auto-sync

# Configure GitHub with auto-sync every 5 minutes
gt issue config --provider github --repo you/repo --token $GITHUB_TOKEN --auto-sync --sync-interval 5m
```

:::tip[Bidirectional Sync]
When `--auto-sync` is enabled, Gas Town will:

- Update external issue status when a bead status changes
- Update bead status when an external issue changes
- Sync comments between beads and external issues
- Map priority levels between systems
:::