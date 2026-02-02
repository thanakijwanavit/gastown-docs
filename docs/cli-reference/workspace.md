---
title: "Workspace Management"
sidebar_position: 1
description: "Commands for installing, initializing, and managing your Gas Town workspace (the \"Town\"). These commands handle the foundational setup that all other operati..."
---

# Workspace Management

Commands for installing, initializing, and managing your Gas Town workspace (the "Town"). These commands handle the foundational setup that all other operations depend on.

---

### `gt install`

Create a new Gas Town workspace.

```bash
gt install <directory> [options]
```

**Description:** Initializes a new town directory with all required structure including `.beads/`, `mayor/`, `deacon/`, `settings/`, and configuration files. This is typically the first command you run.

**Options:**

| Flag | Description |
|------|-------------|
| `--git` | Initialize a git repository in the workspace |
| `--force` | Overwrite an existing workspace |
| `--agent <runtime>` | Set default agent runtime (default: `claude`) |
| `--no-daemon` | Skip daemon setup |

**Example:**

```bash
# Standard installation with git
gt install ~/gt --git

# Install with Gemini as default agent
gt install ~/gt --git --agent gemini
```

**Created structure:**

```
~/gt/
├── .beads/          # Town-level issue tracking
├── .claude/         # Claude Code integration
├── mayor/           # Mayor agent context
├── deacon/          # Deacon agent context
├── settings/        # Configuration files
├── scripts/         # Utility scripts
├── plugins/         # Town-level plugins
├── CLAUDE.md        # Project context file
└── .events.jsonl    # Activity log
```

:::warning

Running `gt install` on an existing workspace without `--force` will abort to prevent accidental data loss.

:::

---

### `gt init`

Initialize Gas Town in an existing directory.

```bash
gt init [options]
```

**Description:** Sets up Gas Town structure in the current directory without creating a new directory. Useful for adding Gas Town to an existing project layout.

**Options:**

| Flag | Description |
|------|-------------|
| `--git` | Initialize a git repository |
| `--force` | Overwrite existing Gas Town configuration |
| `--minimal` | Create only essential directories |

**Example:**

```bash
cd ~/my-workspace
gt init --git
```

---

### `gt uninstall`

Remove Gas Town from a workspace.

```bash
gt uninstall [directory] [options]
```

**Description:** Removes Gas Town configuration and infrastructure from a workspace. Does not remove your project source code or git repositories by default.

**Options:**

| Flag | Description |
|------|-------------|
| `--all` | Remove everything including rig source directories |
| `--keep-beads` | Preserve the beads database |
| `--force` | Skip confirmation prompts |
| `--dry-run` | Show what would be removed without removing it |

**Example:**

```bash
# Remove Gas Town but keep project files
gt uninstall ~/gt

# Full removal
gt uninstall ~/gt --all --force
```

:::danger

Using `--all` permanently deletes all rig data, worktrees, and agent state. This cannot be undone.

:::

---

### `gt git-init`

Initialize or repair git configuration for a Gas Town workspace.

```bash
gt git-init [options]
```

**Description:** Sets up git tracking for the town workspace, including `.gitignore` rules, `.gitattributes`, and initial commit structure. Also useful for repairing corrupted git state.

**Options:**

| Flag | Description |
|------|-------------|
| `--repair` | Repair existing git configuration |
| `--force` | Overwrite existing git setup |

**Example:**

```bash
# Initialize git in an existing town
gt git-init

# Repair corrupted git state
gt git-init --repair
```

---

### `gt enable`

Enable a Gas Town feature or plugin.

```bash
gt enable <feature> [options]
```

**Description:** Enables optional features, plugins, or integrations in the workspace.

**Options:**

| Flag | Description |
|------|-------------|
| `--rig <name>` | Enable for a specific rig only |
| `--global` | Enable globally for all rigs |

**Example:**

```bash
# Enable Discord integration
gt enable discord

# Enable a plugin for a specific rig
gt enable eslint-plugin --rig myproject
```

---

### `gt disable`

Disable a Gas Town feature or plugin.

```bash
gt disable <feature> [options]
```

**Description:** Disables a previously enabled feature, plugin, or integration.

**Options:**

| Flag | Description |
|------|-------------|
| `--rig <name>` | Disable for a specific rig only |
| `--global` | Disable globally for all rigs |

**Example:**

```bash
gt disable discord
gt disable eslint-plugin --rig myproject
```

---

### `gt stale`

Find and report stale resources in the workspace.

```bash
gt stale [options]
```

**Description:** Identifies stale worktrees, abandoned hooks, zombie processes, orphaned polecats, and other resources that may need cleanup. Useful for periodic maintenance.

**Options:**

| Flag | Description |
|------|-------------|
| `--cleanup` | Automatically clean up stale resources |
| `--rig <name>` | Check a specific rig only |
| `--age <duration>` | Stale threshold (default: `24h`) |
| `--json` | Output in JSON format |

**Example:**

```bash
# Report stale resources
gt stale

# Auto-cleanup resources older than 12 hours
gt stale --cleanup --age 12h
```

---

### `gt info`

Display information about the current workspace or rig.

```bash
gt info [target] [options]
```

**Description:** Shows detailed information about the town, a specific rig, an agent, or the overall system. When run without arguments, shows town-level summary.

**Options:**

| Flag | Description |
|------|-------------|
| `--json` | Output in JSON format |
| `--verbose` | Show extended details |

**Example:**

```bash
# Show town info
gt info

# Show rig info
gt info myproject

# Show agent info
gt info mayor

# Machine-readable output
gt info --json
```

**Sample output:**

```
Gas Town v1.2.0
Workspace: /home/user/gt
Rigs: 3 (2 active, 1 parked)
Agents: Mayor (running), Deacon (running)
Active polecats: 4
Open convoys: 2
Pending beads: 7
```

---

### `gt help`

Display help information for any command.

```bash
gt help [command] [subcommand]
```

**Description:** Shows usage, options, and examples for any `gt` command. When called without arguments, displays the top-level help with all available commands.

**Example:**

```bash
# Top-level help
gt help

# Help for a specific command
gt help sling

# Help for a subcommand
gt help convoy create

# Alternative syntax
gt convoy create --help
```

---

### `gt completion`

Generate shell completion scripts.

```bash
gt completion <shell>
```

**Description:** Generates tab-completion scripts for bash, zsh, fish, or PowerShell. These scripts enable tab completion for all `gt` commands, subcommands, and flags.

**Supported shells:** `bash`, `zsh`, `fish`, `powershell`

**Example:**

```bash
# Bash
gt completion bash > /etc/bash_completion.d/gt

# Zsh
gt completion zsh > "${fpath[1]}/_gt"

# Fish
gt completion fish > ~/.config/fish/completions/gt.fish

# PowerShell
gt completion powershell > gt.ps1
```

:::tip

After installing completions, restart your shell or source the completion file for immediate effect.

:::

---

### `gt shell`

Launch an interactive Gas Town shell.

```bash
gt shell [options]
```

**Description:** Opens an interactive shell session with Gas Town context pre-loaded. Provides enhanced tab completion, prompt integration showing current rig and agent status, and shorthand command aliases.

**Options:**

| Flag | Description |
|------|-------------|
| `--rig <name>` | Start in the context of a specific rig |
| `--role <agent>` | Set the shell role identity |

**Example:**

```bash
# Launch Gas Town shell
gt shell

# Launch in context of a specific rig
gt shell --rig myproject
```

:::note

The Gas Town shell sets the `GT_ROLE` environment variable and configures the prompt to show your current context.


:::