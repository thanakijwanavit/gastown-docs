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

Set a custom command for an agent runtime.

```bash
gt config agent set <name> <cmd>
```

**Description:** Sets the command used to invoke a named agent runtime. Use this to configure the shell command that Gas Town executes when launching the specified agent.

**Example:**

```bash
# Set the command for the claude agent
gt config agent set claude "claude"

# Set a custom command for gemini
gt config agent set gemini "/usr/local/bin/gemini-cli"

# Set a wrapper script as the command
gt config agent set cursor "./scripts/run-cursor.sh"
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

### `gt config agent-email-domain`

Get or set the agent email domain.

```bash
gt config agent-email-domain [domain]
```

**Description:** Without an argument, shows the current agent email domain. With an argument, sets the email domain used for agent identities.

**Example:**

```bash
# Show current domain
gt config agent-email-domain

# Set domain
gt config agent-email-domain example.com
```

---

## Account Management

### `gt account`

Manage Claude Code accounts.

```bash
gt account [subcommand]
```

**Description:** Manage Claude Code accounts used by Gas Town.

**Example:**

```bash
gt account
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

List all Claude Code hooks in the workspace.

```bash
gt hooks
```

**Description:** Lists all Claude Code hooks configured in the workspace. Hooks are defined in `.claude/settings.json` and run at specific points in the Claude Code lifecycle.

**Example:**

```bash
gt hooks
```

---

## Issue Display

### `gt issue`

Manage current issue for status line display.

```bash
gt issue [issue-id]
```

**Description:** Manage which issue ID is shown in the status line. Without an argument, shows the current issue. With an argument, sets the issue displayed in the status line.

**Example:**

```bash
# Show current issue
gt issue

# Set the current issue
gt issue PROJ-123
```