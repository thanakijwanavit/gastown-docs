---
title: "System Overview"
sidebar_position: 1
description: "Gas Town consists of five layers:"
---

# System Overview

## Components

Gas Town consists of five layers:

### 1. The Town (Workspace)

The town is the root directory (typically `~/gt/`) containing all projects and coordination state. It holds:

- Town-level beads database for cross-project tracking
- Configuration and settings
- Mayor and Deacon agent contexts
- Daemon process state

### 2. Rigs (Project Containers)

Each rig wraps a git repository with the full agent infrastructure:

```text
myproject/
├── .beads/           # Rig-level issue tracking (SQLite + JSONL export)
├── metadata.json     # Rig configuration and identity
├── AGENTS.md         # Agent role descriptions
├── refinery/         # Refinery merge queue processing
├── mayor/            # Mayor's coordination workspace
├── crew/             # Human developer workspaces
│   ├── dave/
│   └── emma/
├── witness/          # Rig-level health monitor
├── polecats/         # Ephemeral worker directories (git worktrees)
│   ├── toast/
│   └── alpha/
└── plugins/          # Rig-level plugins
```

### 3. Agents (Workers)

Seven agent roles form the hierarchy:

| Agent | Scope | Lifecycle | Purpose |
|-------|-------|-----------|---------|
| **Mayor** | Town | Persistent | Global coordination and strategy |
| **Deacon** | Town | Persistent | Health monitoring and lifecycle |
| **Witness** | Per-rig | Persistent | Polecat supervision |
| **Refinery** | Per-rig | Persistent | Merge queue processing |
| **Polecats** | Per-rig | Ephemeral | Feature work (self-cleaning) |
| **Crew** | Per-rig | Managed | Human developer workspaces |
| **Dogs** | Town | Reusable | Infrastructure tasks |

Additionally, the **Boot** dog is a special triage agent spawned by the Deacon to assess new work or problems.

### 4. Daemon (Scheduler)

A simple Go process that:

- Sends periodic heartbeats to the Deacon
- Processes lifecycle requests (start/stop agents)
- Restarts sessions when requested
- Polls external services (Discord, etc.)

The daemon is intentionally "dumb" — all intelligence lives in the agents.

### 5. Communication Layer

Agents communicate through:

- **Mail** — Async message passing between agents
- **Nudge** — Synchronous message delivery
- **Escalations** — Priority-routed alerts
- **Hooks** — Persistent work state attachment
- **Beads** — Shared issue tracking state

## Data Flow

```text
Human gives Mayor instructions
    → Mayor creates beads + convoy
    → Mayor slings work to rigs
    → Polecats spawn and execute
    → Polecats submit MRs via gt done
    → Refinery processes merge queue
    → Code lands on main branch
    → Witness cleans up polecat sandbox
    → Convoy auto-closes when all done
```

## State Management

All state is persisted in git or the filesystem:

| State | Storage | Survives |
|-------|---------|----------|
| Issues | `.beads/beads.db` (SQLite) | Everything |
| Issue export | `.beads/issues.jsonl` | Everything |
| Work hooks | Git worktrees | Crashes, restarts |
| Mail | Filesystem JSONL | Session restarts |
| Config | `metadata.json`, `.beads/config.yaml` | Everything |
| Agent context | CLAUDE.md files | Everything |
| Activity log | `.events.jsonl` | Everything |

## Related

- [Agent Hierarchy](agent-hierarchy.md) -- Supervision tree, monitoring chain, and escalation paths between agents
- [Design Principles](design-principles.md) -- The twelve core principles that guide Gas Town's architecture
- [Architecture Guide](../guides/architecture.md) -- Narrative walkthrough of how all the pieces fit together
- [Rigs](../concepts/rigs.md) -- Project containers that wrap git repositories with full agent infrastructure
