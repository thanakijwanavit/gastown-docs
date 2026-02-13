---
title: "CLI Reference"
sidebar_position: 0
description: "Complete reference for the gt CLI covering workspaces, agents, work management, communication, merge queues, and diagnostics."
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

## Command Deep Dives

Comprehensive reference for frequently used commands with all flags, subcommands, and examples:

| Command | Description |
|---------|-------------|
| [`gt sling`](sling.md) | Assign work to agents and rigs, with formula support and batch dispatch |
| [`gt nudge`](nudge.md) | Send synchronous messages to running agent sessions |
| [`gt refinery`](refinery-commands.md) | Manage the per-rig merge queue processor |
| [`gt polecat`](polecat-commands.md) | Manage polecat lifecycle: list, nuke, stale detection, identities |
| [`gt session`](session-commands.md) | Manage tmux sessions: start, stop, attach, capture output |
| [`gt seance`](seance.md) | Talk to predecessor sessions for context recovery |
| [`gt orphans`](orphans.md) | Find and recover orphaned commits and processes |
| [`gt warrant`](warrant.md) | Manage death warrants for agent termination |
| [`gt compact`](compact.md) | TTL-based compaction of ephemeral wisps |
| [`gt tap`](tap.md) | Claude Code hook handlers for policy enforcement |
| [`gt town`](town.md) | Town-level session cycling operations |

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

## Commands by Use Case

Not sure which command you need? Find it by scenario:

| I want to... | Command | Reference |
|--------------|---------|-----------|
| Set up a new workspace | `gt install`, `gt start` | [Workspace](workspace.md) |
| Add a project | `gt rig add` | [Rigs](rigs.md) |
| Assign work to an agent | `gt sling` | [Sling](sling.md) |
| Check what an agent is working on | `gt hook` | [Work Management](work.md) |
| Send a message to another agent | `gt nudge` | [Nudge](nudge.md) |
| View the merge queue | `gt mq list` | [Merge Queue](merge-queue.md) |
| Debug a stalled polecat | `gt polecat list`, `gt nudge` | [Polecat](polecat-commands.md) |
| Check system health | `gt doctor`, `gt status` | [Diagnostics](diagnostics.md) |
| Monitor real-time activity | `gt feed`, `gt dashboard` | [Diagnostics](diagnostics.md) |
| Hand off to a fresh session | `gt handoff` | [Sessions](sessions.md) |
| Find orphaned work | `gt orphans` | [Orphans](orphans.md) |

## Related

- **[Core Concepts](../concepts/index.md)** — The primitives behind these commands
- **[Workflows](../workflows/index.md)** — How commands combine into end-to-end workflows
- **[Operations](../operations/index.md)** — Operational patterns using these commands
- **[Guides](../guides/usage-guide.md)** — Practical usage walkthroughs