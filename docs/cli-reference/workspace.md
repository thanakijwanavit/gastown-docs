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

Check if the `gt` binary is stale (built from an older commit than current repo HEAD).

```bash
gt stale [options]
```

**Description:** Compares the commit hash embedded in the binary at build time with the current HEAD of the gastown repository. Helps determine when a rebuild is needed.

**Options:**

| Flag | Description |
|------|-------------|
| `--json` | Output in JSON format |
| `--quiet`, `-q` | Exit code only (0=stale, 1=fresh) |

**Exit codes:**

| Code | Meaning |
|------|---------|
| `0` | Binary is stale (needs rebuild) |
| `1` | Binary is fresh (up to date) |
| `2` | Error (could not determine staleness) |

**Example:**

```bash
# Human-readable output
gt stale

# Machine-readable
gt stale --json

# Script usage
gt stale --quiet && echo "needs rebuild"
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

## Services

---

### `gt up`

Start all Gas Town long-lived services.

```bash
gt up [options]
```

**Description:** Idempotent boot command that ensures all infrastructure agents are running: Daemon, Deacon, Mayor, Witnesses, and Refineries. Running `gt up` multiple times is safe — it only starts services that aren't already running. Polecats are not started by this command (they are transient workers spawned on demand).

**Options:**

| Flag | Description |
|------|-------------|
| `--restore` | Also restore crew (from settings) and polecats (from hooks) |
| `--quiet`, `-q` | Only show errors |

**Example:**

```bash
# Bring up all infrastructure
gt up

# Also restore crew and pinned polecats
gt up --restore
```

---

### `gt down`

Stop Gas Town services (reversible pause).

```bash
gt down [options]
```

**Description:** Pauses Gas Town by stopping infrastructure agents. This is a reversible operation — use `gt up` to bring everything back. For permanent cleanup (removing worktrees), use `gt shutdown` instead.

**Options:**

| Flag | Description |
|------|-------------|
| `--polecats`, `-p` | Also stop all polecat sessions |
| `--all`, `-a` | Also stop bd daemons/activity and verify shutdown |
| `--nuke` | Kill entire tmux server (destroys non-GT sessions too) |
| `--force`, `-f` | Force kill without graceful shutdown |
| `--dry-run` | Preview what would be stopped |
| `--quiet`, `-q` | Only show errors |

**Example:**

```bash
# Stop infrastructure only (polecats keep running)
gt down

# Stop everything including polecats
gt down --polecats

# Preview what would stop
gt down --dry-run
```

:::danger
`--nuke` kills the entire tmux server, including non-Gas Town sessions.
:::

---

### `gt shutdown`

Shutdown Gas Town with full cleanup.

```bash
gt shutdown [options]
```

**Description:** The "done for the day" command — stops all agents AND removes polecat worktrees/branches. Polecats with uncommitted work are protected (skipped) unless `--nuclear` is used. For a reversible pause, use `gt down` instead.

**Options:**

| Flag | Description |
|------|-------------|
| `--all`, `-a` | Also stop crew sessions (crew is preserved by default) |
| `--polecats-only` | Only stop polecats (leaves infrastructure running) |
| `--force`, `-f` | Skip confirmation prompt |
| `--yes`, `-y` | Skip confirmation prompt |
| `--graceful`, `-g` | Allow agents time to save state before killing |
| `--wait`, `-w` | Seconds to wait for graceful shutdown (default: `30`) |
| `--nuclear` | Force cleanup even if polecats have uncommitted work |
| `--cleanup-orphans` | Clean up orphaned Claude processes |
| `--cleanup-orphans-grace-secs` | Grace period between SIGTERM and SIGKILL (default: `60`) |

**Example:**

```bash
# Standard shutdown (interactive confirmation)
gt shutdown

# Skip confirmation
gt shutdown --yes

# Graceful shutdown with state saving
gt shutdown --graceful

# Stop only polecats, leave infrastructure running
gt shutdown --polecats-only
```

:::warning
`--nuclear` may cause loss of uncommitted polecat work. Use with caution.
:::

---

### `gt start`

Start Gas Town by launching the Deacon and Mayor.

```bash
gt start [path] [options]
```

**Description:** Launches the Deacon (health-check orchestrator) and Mayor (global coordinator). Other agents (Witnesses, Refineries) are started lazily as needed unless `--all` is specified. Also supports a crew shortcut: `gt start rig/crew/name`.

**Options:**

| Flag | Description |
|------|-------------|
| `--all`, `-a` | Also start Witnesses and Refineries for all rigs |
| `--agent <runtime>` | Override agent runtime for Mayor/Deacon |

**Example:**

```bash
# Start core agents
gt start

# Start everything including per-rig agents
gt start --all

# Start a crew workspace
gt start myrig/crew/dave
```

---

### `gt status`

Show overall town status.

```bash
gt status [options]
```

**Aliases:** `stat`

**Description:** Displays the current status of the Gas Town workspace including town name, registered rigs, active polecats, and agent status.

**Options:**

| Flag | Description |
|------|-------------|
| `--fast` | Skip mail lookups for faster execution |
| `--watch`, `-w` | Watch mode: refresh status continuously |
| `--interval`, `-n` | Refresh interval in seconds (default: `2`) |
| `--json` | Output as JSON |
| `--verbose`, `-v` | Show detailed multi-line output per agent |

**Example:**

```bash
# Quick status check
gt status

# Fast mode (skip mail)
gt status --fast

# Live monitoring
gt status --watch

# Detailed view
gt status --verbose
```

---

### `gt daemon`

Manage the Gas Town background daemon.

```bash
gt daemon <subcommand>
```

**Description:** The daemon is a Go background process that pokes agents periodically (heartbeat), processes lifecycle requests, and restarts sessions when agents request cycling. It is a "dumb scheduler" — all intelligence is in agents.

**Subcommands:**

| Subcommand | Description |
|------------|-------------|
| `start` | Start the daemon |
| `stop` | Stop the daemon |
| `status` | Show daemon status |
| `logs` | View daemon logs |

**Example:**

```bash
# Check daemon status
gt daemon status

# View daemon logs
gt daemon logs

# Restart the daemon
gt daemon stop && gt daemon start
```

## Plugins

---

### `gt plugin`

Manage plugins that run during Deacon patrol cycles.

```bash
gt plugin <subcommand>
```

**Description:** Plugins are periodic automation tasks defined by `plugin.md` files with TOML frontmatter. They live in `~/gt/plugins/` (town-level) or `<rig>/plugins/` (rig-level).

**Gate types:** `cooldown`, `cron`, `condition`, `event`, `manual`

**Subcommands:**

| Subcommand | Description |
|------------|-------------|
| `list` | List all discovered plugins |
| `show <name>` | Show plugin details |
| `run <name>` | Manually trigger plugin execution |
| `history` | Show plugin execution history |

**Example:**

```bash
# List all plugins
gt plugin list

# Show plugin details
gt plugin show rebuild-gt

# Manually trigger a plugin
gt plugin run rebuild-gt

# JSON output
gt plugin list --json
```

## Utilities

---

### `gt version`

Print version information.

```bash
gt version
```

---

### `gt whoami`

Show current identity for mail commands.

```bash
gt whoami
```

**Description:** Shows the identity that will be used for mail commands. Identity is determined by `GT_ROLE` (agent session) or defaults to overseer (human) when `GT_ROLE` is not set.

**Example:**

```bash
gt whoami
# gastown/polecats/nux

gt mail inbox --identity mayor/  # Override identity
```

---

### `gt commit`

Git commit with automatic agent identity.

```bash
gt commit [flags] [-- git-commit-args...]
```

**Description:** When run by an agent (`GT_ROLE` set), detects the agent identity and runs `git commit` with the correct author name and email. When run without `GT_ROLE` (human), passes through to `git commit` unchanged.

**Example:**

```bash
gt commit -m "Fix bug"        # Commit as current agent
gt commit -am "Quick fix"     # Stage all and commit
gt commit -- --amend          # Amend last commit
```

---

### `gt namepool`

Manage themed name pools for polecats.

```bash
gt namepool [subcommand]
```

**Description:** Polecats get themed names from a configurable pool (default: Mad Max universe). You can change the theme or add custom names.

**Subcommands:**

| Subcommand | Description |
|------------|-------------|
| `themes` | List available themes and their names |
| `set <theme>` | Set the namepool theme for the current rig |
| `add <name>` | Add a custom name to the pool |
| `reset` | Reset pool state (release all names) |

**Options:**

| Flag | Description |
|------|-------------|
| `--list`, `-l` | List available themes |

**Example:**

```bash
# Show current pool status
gt namepool

# List available themes
gt namepool themes

# Switch to minerals theme
gt namepool set minerals

# Add a custom name
gt namepool add ember
```

---

### `gt worktree`

Create a worktree in another rig for cross-rig work.

```bash
gt worktree <rig> [options]
```

**Description:** For crew workers who need to work on another rig's codebase while maintaining their identity. Creates a worktree at `~/gt/<target-rig>/crew/<source-rig>-<name>/`.

**Subcommands:**

| Subcommand | Description |
|------------|-------------|
| `list` | List all cross-rig worktrees owned by current crew member |
| `remove` | Remove a cross-rig worktree |

**Options:**

| Flag | Description |
|------|-------------|
| `--no-cd` | Just print the path without shell commands |

**Example:**

```bash
# Create worktree in another rig
gt worktree beads

# List your cross-rig worktrees
gt worktree list

# Remove a worktree
gt worktree remove beads
```