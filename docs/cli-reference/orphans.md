---
title: "gt orphans"
sidebar_position: 16
description: "Find and recover orphaned commits and processes. Detects work lost from killed sessions, failed merges, and network issues."
---

# gt orphans

Find orphaned commits that were never merged to main.

```bash
gt orphans [flags]
gt orphans [command]
```

## Description

Polecat work can get lost when:

- Session killed before merge
- Refinery fails to process
- Network issues during push

This command uses `git fsck --unreachable` to find dangling commits, filters to recent ones, and shows details to help recovery.

## Subcommands

| Command | Description |
|---------|-------------|
| [`kill`](#gt-orphans-kill) | Remove all orphans (commits and processes) |
| [`procs`](#gt-orphans-procs) | Manage orphaned Claude processes |

## Flags

| Flag | Description |
|------|-------------|
| `--days <n>` | Show orphans from last N days (default: 7) |
| `--all` | Show all orphans (no date filter) |
| `--rig <name>` | Target rig name (required when not in a rig directory) |

## Examples

```bash
gt orphans                    # Last 7 days, infers rig from cwd
gt orphans --rig=gastown      # Target a specific rig
gt orphans --days=14          # Last 2 weeks
gt orphans --all              # Show all orphans (no date filter)
```

---

## gt orphans kill

Remove orphaned commits and kill orphaned Claude processes.

```bash
gt orphans kill [flags]
```

Performs a complete orphan cleanup:

1. Finds orphaned commits (same as `gt orphans`)
2. Finds orphaned Claude processes (same as `gt orphans procs`)
3. Shows what will be removed/killed
4. Asks for confirmation (unless `--force`)
5. Runs `git gc` and kills processes

:::warning

This operation is irreversible. Once commits are pruned, they cannot be recovered. Use `--dry-run` first to preview.

:::

**Flags:**

| Flag | Description |
|------|-------------|
| `--days <n>` | Kill orphans from last N days (default: 7) |
| `--all` | Kill all orphans (no date filter) |
| `--dry-run` | Preview without deleting |
| `--force` | Skip confirmation prompt |

**Examples:**

```bash
gt orphans kill               # Kill orphans from last 7 days
gt orphans kill --days=14     # Kill orphans from last 2 weeks
gt orphans kill --dry-run     # Preview without deleting
gt orphans kill --force       # Skip confirmation prompt
```

---

## gt orphans procs

Find and kill Claude processes that have become orphaned (PPID=1).

```bash
gt orphans procs [flags]
gt orphans procs [command]
```

Orphaned processes are those that survived session termination and are now parented to init/launchd. They consume resources and should be killed.

**Subcommands:**

| Command | Description |
|---------|-------------|
| `list` | List orphaned Claude processes |
| `kill` | Kill orphaned Claude processes |

**Flags:**

| Flag | Description |
|------|-------------|
| `--aggressive` | Use tmux session verification to find ALL orphans, not just PPID=1 |

Use `--aggressive` to detect all orphaned Claude processes by cross-referencing against active tmux sessions. Any Claude process NOT in a `gt-*` or `hq-*` session is considered an orphan.

**Examples:**

```bash
gt orphans procs              # List orphaned processes (PPID=1 only)
gt orphans procs --aggressive # List ALL orphaned processes
gt orphans procs kill         # Kill orphaned processes
```
