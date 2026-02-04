---
title: "CLI Reference"
sidebar_position: 0
description: "The gt CLI is the primary interface for interacting with Gas Town. It manages workspaces, agents, work distribution, communication, and diagnostics across yo..."
---

# CLI Reference

The `gt` CLI is the primary interface for interacting with Gas Town. It manages workspaces, agents, work distribution, communication, and diagnostics across your entire multi-agent development environment.

## Usage

```bash
gt <command> [subcommand] [options] [arguments]
```

Global flags available on all commands:

| Flag | Description |
|------|-------------|
| `--help`, `-h` | Show help for any command |
| `--version`, `-v` | Print the Gas Town version |

Many subcommands also support `--json`, `--verbose`, `--quiet`, and `--rig <name>` flags. See individual command documentation for details.

## Command Categories

| Category | Description | Key Commands |
|----------|-------------|--------------|
| [Workspace Management](workspace.md) | Install, initialize, manage services, and configure your Gas Town workspace | `gt install`, `gt start`, `gt up`, `gt down`, `gt shutdown`, `gt status` |
| [Agent Operations](agents.md) | Start, stop, and manage the agent hierarchy | `gt mayor`, `gt deacon`, `gt witness`, `gt polecat`, `gt crew` |
| [Work Management](work.md) | Create, assign, track, and complete work items | `gt sling`, `gt hook`, `gt done`, `gt commit`, `bd create` |
| [Convoy & Tracking](convoys.md) | Bundle and track batches of related work | `gt convoy create`, `gt convoy status`, `gt synthesis` |
| [Communication](communication.md) | Send and receive messages between agents and humans | `gt mail`, `gt nudge`, `gt broadcast`, `gt escalate` |
| [Merge Queue](merge-queue.md) | Manage the refinery merge pipeline | `gt mq list`, `gt mq submit`, `gt mq status` |
| [Rig Management](rigs.md) | Add, configure, and manage project containers | `gt rig add`, `gt rig start`, `gt rig config` |
| [Session & Handoff](sessions.md) | Manage agent sessions, handoffs, and molecules | `gt handoff`, `gt resume`, `gt prime`, `gt mol`, `gt cycle` |
| [Diagnostics](diagnostics.md) | Monitor, audit, and troubleshoot the system | `gt activity`, `gt doctor`, `gt dashboard`, `gt status` |
| [Configuration](configuration.md) | Configure agents, accounts, themes, hooks, and plugins | `gt config`, `gt account`, `gt theme`, `gt hooks`, `gt plugin` |

## Related Tools

Gas Town integrates with the **Beads** issue tracker (`bd` CLI). Beads commands are documented in the [Work Management](work.md) section alongside `gt` work commands.

## Quick Examples

```bash
# Set up a new workspace
gt install ~/gt --git

# Add a project and start working
gt rig add myapp https://github.com/you/app.git
gt start

# Check system status
gt status
gt rig list
gt feed

# Diagnose issues
gt doctor
gt dashboard
```

:::tip[Shell Completions]

Install tab completions for a better CLI experience. See [Workspace Management](workspace.md#gt-completion) for setup instructions.

:::

:::note[Context-Aware Commands]

Many `gt` commands auto-detect the current rig based on your working directory. Use `--rig <name>` to override this when needed.


:::