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

**Description:** Initializes a new HQ (headquarters) with all required structure including `.beads/`, `mayor/`, `deacon/`, `settings/`, and configuration files. This is typically the first command you run.

**Options:**

| Flag | Description |
|------|-------------|
| `--git` | Initialize a git repository in the workspace |
| `--force` | Overwrite an existing workspace |
| `--name`, `-n` | Town name (defaults to directory name) |
| `--no-beads` | Skip town beads initialization |
| `--github <owner/repo>` | Create GitHub repo (private by default) |
| `--public` | Make GitHub repo public (use with `--github`) |
| `--shell` | Install shell integration (sets `GT_TOWN_ROOT`/`GT_RIG` env vars) |
| `--owner <email>` | Owner email for entity identity |
| `--wrappers` | Install `gt-codex`/`gt-opencode` wrapper scripts to `~/bin/` |

**Example:**

```bash
# Standard installation with git
gt install ~/gt --git

# Install with a linked GitHub repo
gt install ~/gt --github=user/repo
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

**Description:** Removes shell integration, wrapper scripts, and state/config/cache directories. The workspace directory (e.g. `~/gt`) is NOT removed unless `--workspace` is specified.

**Options:**

| Flag | Description |
|------|-------------|
| `--force`, `-f` | Skip confirmation prompts |
| `--workspace` | Also remove the workspace directory (DESTRUCTIVE) |

**Example:**

```bash
# Remove Gas Town integration (preserves workspace)
gt uninstall

# Full removal including workspace directory
gt uninstall --workspace --force
```

:::danger

Using `--workspace` permanently deletes the workspace directory and all its contents. This cannot be undone.

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

Enable Gas Town for all agentic coding tools.

```bash
gt enable
```

**Description:** Enable Gas Town for all agentic coding tools. When enabled: shell hooks set `GT_TOWN_ROOT` and `GT_RIG` environment variables, Claude Code SessionStart hooks run `gt prime` for context.

**Example:**

```bash
gt enable
```

---

### `gt disable`

Disable Gas Town for all agentic coding tools.

```bash
gt disable [options]
```

**Description:** Disable Gas Town for all agentic coding tools. The workspace is preserved.

**Options:**

| Flag | Description |
|------|-------------|
| `--clean` | Remove shell integration from RC files |

**Example:**

```bash
gt disable

# Also remove shell integration from RC files
gt disable --clean
```

---

### `gt stale`

Check if the gt binary is stale.

```bash
gt stale [options]
```

**Description:** Checks if the `gt` binary is stale (i.e., built from an older commit than the current repo HEAD). Useful for determining if the binary needs to be rebuilt.

**Options:**

| Flag | Description |
|------|-------------|
| `--json` | Output as JSON |
| `--quiet`, `-q` | Exit code only (0=stale, 1=fresh) |

**Example:**

```bash
gt stale
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

Manage shell integration.

```bash
gt shell [options]
```

**Description:** Manage shell integration for Gas Town. Handles setup and configuration of shell hooks and environment variables.

**Example:**

```bash
gt shell
```

:::note

The Gas Town shell sets the `GT_ROLE` environment variable and configures the prompt to show your current context.


:::