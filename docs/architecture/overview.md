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

```
myproject/
├── .beads/           # Rig-level issue tracking
├── config.json       # Rig configuration
├── refinery/rig/     # Canonical main clone
├── mayor/rig/        # Mayor's working copy
├── crew/             # Human developer workspaces
│   ├── dave/
│   └── emma/
├── witness/          # Health monitor state
├── polecats/         # Ephemeral worker directories
│   ├── toast/
│   └── alpha/
└── plugins/          # Rig-level plugins
```

### 3. Agents (Workers)

Six agent roles form the hierarchy:

| Agent | Scope | Lifecycle | Purpose |
|-------|-------|-----------|---------|
| **Mayor** | Town | Persistent | Global coordination |
| **Deacon** | Town | Persistent | Health monitoring |
| **Witness** | Per-rig | Persistent | Polecat supervision |
| **Refinery** | Per-rig | Persistent | Merge queue processing |
| **Polecats** | Per-rig | Ephemeral | Feature work |
| **Dogs** | Town | Reusable | Infrastructure tasks |

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

```
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
| Work hooks | Git worktrees | Crashes, restarts |
| Mail | Filesystem JSONL | Session restarts |
| Config | JSON/YAML files | Everything |
| Agent context | CLAUDE.md files | Everything |
| Activity log | `.events.jsonl` | Everything |
