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

## Account Management

### `gt account`

Manage Gas Town account settings.

```bash
gt account [subcommand] [options]
```

**Description:** View and manage account-level settings including API keys, user identity, and linked services.

**Subcommands:**

| Subcommand | Description |
|------------|-------------|
| `gt account show` | Show current account settings |
| `gt account set <key> <value>` | Set an account setting |
| `gt account link <service>` | Link an external service (GitHub, Discord, etc.) |
| `gt account unlink <service>` | Unlink an external service |

**Example:**

```bash
# Show account info
gt account show

# Set user name
gt account set name "Dave"

# Set email
gt account set email "dave@example.com"

# Link GitHub
gt account link github

# Link Discord
gt account link discord
```

**Sample output (show):**

```
Gas Town Account
================
Name: Dave
Email: dave@example.com
Linked services:
  GitHub: connected (dave-dev)
  Discord: connected (dave#1234)
  Slack: not linked
```

---

## Appearance

### `gt theme`

Manage terminal theme and display settings.

```bash
gt theme [name] [options]
```

**Description:** Without arguments, shows the current theme. With a name, sets the active theme. Themes control colors, icons, and formatting in the CLI output.

**Options:**

| Flag | Description |
|------|-------------|
| `--list` | List available themes |
| `--preview` | Preview a theme without applying |

**Built-in themes:**

| Theme | Description |
|-------|-------------|
| `default` | Standard terminal colors |
| `dark` | Optimized for dark backgrounds |
| `light` | Optimized for light backgrounds |
| `minimal` | Reduced visual noise |
| `mad-max` | Thematic, full color |

**Example:**

```bash
# Show current theme
gt theme

# List available themes
gt theme --list

# Set theme
gt theme dark

# Preview before applying
gt theme mad-max --preview
```

---

## Event Hooks

### `gt hooks`

Manage lifecycle hooks and event handlers.

```bash
gt hooks [subcommand] [options]
```

**Description:** Configure scripts and actions that run in response to Gas Town lifecycle events. Hooks execute at specific points in the work lifecycle.

**Subcommands:**

| Subcommand | Description |
|------------|-------------|
| `gt hooks list` | List configured hooks |
| `gt hooks add <event> <command>` | Add a hook for an event |
| `gt hooks remove <event> [command]` | Remove a hook |
| `gt hooks enable <event>` | Enable a disabled hook |
| `gt hooks disable <event>` | Disable a hook without removing |
| `gt hooks test <event>` | Test-fire a hook |

**Available events:**

| Event | Fires When |
|-------|-----------|
| `pre-sling` | Before work is assigned |
| `post-sling` | After work is assigned |
| `pre-done` | Before work completion |
| `post-done` | After work completion |
| `pre-merge` | Before a merge is attempted |
| `post-merge` | After a successful merge |
| `agent-start` | When any agent starts |
| `agent-stop` | When any agent stops |
| `escalation` | When an escalation is created |
| `convoy-complete` | When a convoy finishes |
| `polecat-spawn` | When a polecat spawns |
| `polecat-nuke` | When a polecat is nuked |

**Example:**

```bash
# List all hooks
gt hooks list

# Add a hook to notify on merge
gt hooks add post-merge "curl -X POST https://slack.com/webhook -d '{\"text\": \"Merged!\"}'"

# Add a pre-merge test hook
gt hooks add pre-merge "npm test"

# Disable a hook
gt hooks disable pre-merge

# Test a hook
gt hooks test post-merge

# Remove a hook
gt hooks remove pre-merge
```

**Options for `gt hooks add`:**

| Flag | Description |
|------|-------------|
| `--rig <name>` | Apply hook to a specific rig |
| `--global` | Apply hook globally |
| `--async` | Run hook asynchronously (do not block) |
| `--timeout <seconds>` | Hook execution timeout |

:::note

Pre-hooks (pre-sling, pre-done, pre-merge) can abort the operation by returning a non-zero exit code. Post-hooks are informational and do not affect the operation outcome.

:::

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