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

## Command Categories

| Category | Description | Key Commands |
|----------|-------------|--------------|
| [Workspace Management](workspace.md) | Install, initialize, and configure your Gas Town workspace | `gt install`, `gt init`, `gt enable`, `gt disable`, `gt info` |
| [Agent Operations](agents.md) | Start, stop, and manage the agent hierarchy | `gt mayor`, `gt deacon`, `gt witness`, `gt polecat`, `gt crew` |
| [Work Management](work.md) | Create, assign, track, and complete work items | `gt sling`, `gt hook`, `gt done`, `bd create`, `gt bead` |
| [Convoy & Tracking](convoys.md) | Bundle and track batches of related work | `gt convoy create`, `gt convoy status`, `gt convoy stranded` |
| [Communication](communication.md) | Send and receive messages between agents and humans | `gt mail`, `gt nudge`, `gt broadcast`, `gt escalate` |
| [Merge Queue](merge-queue.md) | Manage the refinery merge pipeline | `gt mq list`, `gt mq submit`, `gt mq status` |
| [Rig Management](rigs.md) | Add, configure, and manage project containers | `gt rig add`, `gt rig start`, `gt rig config` |
| [Session & Handoff](sessions.md) | Manage agent sessions, handoffs, and molecules | `gt handoff`, `gt resume`, `gt prime`, `gt mol` |
| [Diagnostics](diagnostics.md) | Monitor, audit, and troubleshoot the system | `gt activity`, `gt doctor`, `gt dashboard`, `gt patrol` |
| [Configuration](configuration.md) | Configure agents, accounts, themes, and hooks | `gt config`, `gt account`, `gt theme`, `gt hooks` |

## Related Tools

Gas Town integrates with the **Beads** issue tracker (`bd` CLI). Beads commands are documented in the [Work Management](work.md) section alongside `gt` work commands.

## Quick Examples

```bash
# Set up a new workspace
gt install ~/gt --git

# Add a project and start working
gt rig add myapp https://github.com/you/app.git
gt mayor attach

# Check system status
gt rig list
gt convoy list
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