---
title: "Beads (Issue Tracking)"
sidebar_position: 1
description: "Beads is a CLI-first, git-backed issue tracker designed for AI agents, with types, priorities, dependencies, and cross-rig tracking."
---

# Beads (Issue Tracking)

Beads is Gas Town's **AI-native, git-backed issue tracking system**. Instead of a web-based project board, issues live directly in your repository as structured data, managed entirely through the `bd` CLI. This design makes Beads seamlessly usable by AI coding agents that work through the terminal.

---

## Why Beads?

Traditional issue trackers are designed for humans clicking through web UIs. Beads is designed for AI agents executing terminal commands:

| Traditional Trackers | Beads |
|---------------------|-------|
| Web UI required | CLI-first (`bd` command) |
| External service dependency | Lives in your git repo |
| Context switching to browser | Stays in the terminal |
| Manual sync with code | Automatic git sync |
| Human-oriented workflows | AI-agent-native workflows |

:::info[Repository]

Beads is an open-source project. Learn more at [github.com/steveyegge/beads](https://github.com/steveyegge/beads).

:::

## Architecture

### Storage Backend

Beads stores issues in a **SQLite database** located in the `.beads/` directory at the root of each repository (or town):

```text
.beads/
├── beads.db           # SQLite database (primary store)
├── formulas/          # TOML workflow templates
├── README.md          # Onboarding documentation
└── daemon.log         # Daemon activity log
```

The SQLite backend enables fast queries, filtering, and complex joins while remaining portable and easy to back up through git.

### Git Integration

Beads synchronizes with git automatically:

- **`bd sync`** pushes and pulls bead state to/from the remote
- Bead operations are local-first -- they work offline and sync when connected
- The `.beads/` directory is committed alongside your code
- Merge conflicts in bead data are resolved intelligently

## Bead Types

Every bead has a **type** that determines its semantics:

| Type | Purpose | Example |
|------|---------|---------|
| `task` | General work item | "Refactor auth module" |
| `bug` | Defect report | "Login fails with special characters" |
| `feature` | New functionality | "Add email notifications" |
| `message` | Communication record | Internal agent message |
| `escalation` | Priority alert | "CI broken for 2 hours" |
| `merge-request` | Merge queue entry | Polecat branch ready for merge |
| `agent` | Agent state bead | Polecat runtime status |
| `convoy` | Batch tracking | Group of related issues (see [Convoys](convoys.md)) |
| `wisp` | Ephemeral tracking | Temporary [molecule](molecules.md) step |

## Bead Status

Beads progress through a defined lifecycle:

```mermaid
stateDiagram-v2
    [*] --> pending: bd create
    pending --> open: Agent claims
    open --> in_progress: Work begins
    in_progress --> hooked: gt sling
    hooked --> in_progress: Agent picks up
    in_progress --> done: bd close
    done --> [*]
```

| Status | Meaning | Typical Transition |
|--------|---------|-------------------|
| `pending` | Created, not yet assigned | Initial state after `bd create` |
| `open` | Acknowledged, ready for work | Agent or human claims it |
| `in_progress` | Actively being worked on | Agent starts implementation |
| `hooked` | Attached to an agent's [hook](hooks.md) | After `gt sling` assigns it |
| `done` | Completed and closed | After `bd close` or merge |

## Labels, Priorities, and Dependencies

### Labels

Labels are free-form tags that categorize beads:

```bash
bd create --title "Fix auth bug" --labels "auth,security,p1"
bd list --labels "security"
```

### Priorities

Priority levels control escalation routing and work ordering:

| Priority | Code | Escalation Route |
|----------|------|-----------------|
| Critical | P0 | Bead, Mail:Mayor, Email:Human, SMS:Human |
| High | P1 | Bead, Mail:Mayor, Email:Human |
| Medium | P2 | Bead, Mail:Mayor |
| Low | P3 | Bead only |

```bash
bd create --title "Security vulnerability" --priority 0
bd create --title "Minor UI glitch" --priority 3
```

### Dependencies

Beads can declare dependencies on other beads, enabling automatic unblocking when prerequisites complete:

```bash
# Create a dependent bead
bd create --title "Deploy to prod" --depends-on gt-a1b2c

# Check blocked issues
bd blocked
```

## Cross-Project Tracking

Beads supports **cross-prefix tracking**, allowing issues in different rigs to reference each other. Each rig has its own bead prefix (configured in `config.json`):

```text
Town (.beads/)  prefix: hq-
Rig A (.beads/) prefix: gt-
Rig B (.beads/) prefix: bd-
```

A [convoy](convoys.md) with ID `hq-cv-001` can track issues `gt-a1b2c` and `bd-d3e4f` across both [rigs](rigs.md). Dependencies also work cross-prefix.

```mermaid
graph TD
    subgraph "Town (.beads/)"
        CV["hq-cv-001<br/>Convoy"]
    end
    subgraph "Rig A (.beads/)"
        A1["gt-a1b2c<br/>Feature"]
        A2["gt-e5f6g<br/>Bug"]
    end
    subgraph "Rig B (.beads/)"
        B1["bd-d3e4f<br/>Task"]
    end
    CV -->|tracks| A1
    CV -->|tracks| B1
    A1 -->|depends on| A2
    B1 -->|depends on| A1
```

```mermaid
flowchart TD
    P0[P0 Critical] -->|Bead + Mail + Email + SMS| HUMAN[Human notified immediately]
    P1[P1 High] -->|Bead + Mail + Email| MAYOR[Mayor + Human notified]
    P2[P2 Medium] -->|Bead + Mail| MAYOR2[Mayor assigns]
    P3[P3 Low] -->|Bead only| QUEUE[Enters ready queue]
    HUMAN --> SLING[gt sling to agent]
    MAYOR --> SLING
    MAYOR2 --> SLING
    QUEUE --> SLING
    SLING --> WORK[Agent executes]
```

## Essential Commands

### Creating Beads

```bash
# Simple creation
bd create "Add user authentication"

# Full creation with metadata
bd create --title "Fix login bug" \
  --type bug \
  --priority 1 \
  --labels "auth,critical" \
  --description "Login fails when password contains special characters"
```

### Listing and Filtering

```bash
# List all open beads
bd list

# Filter by status
bd list --status in_progress

# Filter by type and labels
bd list --type bug --labels "auth"

# JSON output for programmatic use
bd list --json

# Find ready work
bd ready
```

### Viewing Bead Details

```bash
# Show full bead details
bd show gt-a1b2c

# Show bead as JSON
bd show gt-a1b2c --json
```

### Updating Beads

```bash
# Update status
bd update gt-a1b2c --status in_progress

# Add notes
bd update gt-a1b2c --notes "Fixed the parser, testing now"

# Add labels
bd update gt-a1b2c --labels "reviewed"
```

### Closing Beads

```bash
# Close a completed bead
bd close gt-a1b2c

# Close with a reason
bd close gt-a1b2c --reason "Merged to main at abc1234"
```

### Syncing with Git

```bash
# Sync bead state with remote
bd sync

# Onboard to a repo (first time setup)
bd onboard
```

## Command Reference

| Command | Description |
|---------|-------------|
| `bd create` | Create a new bead |
| `bd list` | List beads with optional filters |
| `bd show <id>` | Show full details of a bead |
| `bd update <id>` | Update bead metadata |
| `bd close <id>` | Close a completed bead |
| `bd sync` | Sync bead state with git remote |
| `bd ready` | Find available work (pending/open beads) |
| `bd onboard` | First-time setup for a repository |
| `bd prime` | Load beads context into agent session |
| `bd blocked` | Show blocked beads waiting on dependencies |
| `bd quickstart` | Interactive getting-started guide |

## When to Use Beads

Beads are the right tool when you need to **track, assign, or coordinate work**:

- **Single task tracking** -- Any work item that an agent or human should pick up, execute, and close. If it needs to be remembered across sessions, make it a bead.
- **Bug reports** -- Discovered a defect? File a `bug` bead so it enters the ready queue and gets picked up.
- **Feature requests** -- New functionality requests become `feature` beads, prioritized and scheduled through the normal work pipeline.
- **Cross-agent coordination** -- When Agent A discovers work that Agent B should do, create a bead and [sling](hooks.md) it. The bead carries the assignment across session boundaries.
- **Audit trail** -- Every bead records who created it, who worked on it, and when it closed. This is your project's permanent work history.

:::note[When NOT to Use Beads]

Don't create beads for trivial, in-flight work that you'll complete in the same session. If you're about to fix a one-line typo, just fix it -- don't create a bead, claim it, close it, and sync it. Beads have overhead; use them for work that benefits from tracking.

:::

## For AI Agents

Beads is specifically designed for AI agent workflows:

:::note[Agent Quick Start]

```bash
bd ready              # Find available work
bd show <id>          # Read the full issue
bd update <id> --status in_progress  # Claim it
# ... do the work ...
bd close <id>         # Mark complete
bd sync               # Push state to remote
```

:::

Agents use `bd ready` at the start of each session to find their next task. Combined with [Hooks](hooks.md), this creates a self-propelling work loop where agents always know what to do.

:::warning[Landing Protocol]

Work is **not complete** until `git push` succeeds. Agents must always push their changes and sync beads before ending a session. See the [AGENTS.md](https://github.com/steveyegge/gastown) landing protocol for the full checklist.

:::

## Related Concepts

- **[Hooks](hooks.md)** -- Hooks attach beads to agents, creating the `hooked` status and enabling crash-safe work assignment
- **[Molecules & Formulas](molecules.md)** -- Molecules track multi-step workflows as a sequence of wisp beads (ephemeral sub-beads)
- **[Convoys](convoys.md)** -- Convoys bundle multiple beads into batches for coordinated tracking
- **[Rigs](rigs.md)** -- Each rig has its own `.beads/` directory with a unique prefix for cross-project identification
- **[Gates](gates.md)** -- Gates can block bead progress, pausing workflow until an external condition is met
- **[GUPP & NDI](gupp.md)** -- Bead statuses follow GUPP's forward-only principle: they progress from `open` to `done` and never go backward

### Blog Posts

- [Why Beads? AI-Native Issue Tracking](/blog/why-beads) -- The design philosophy behind choosing git-backed issues over web-based trackers
- [Your First Convoy: From Idea to Merged Code](/blog/first-convoy) -- End-to-end walkthrough of creating beads, bundling them into a convoy, and watching agents execute
- [Work Distribution Patterns in Gas Town](/blog/work-distribution-patterns) -- How beads flow through the work distribution pipeline from creation to assignment to completion
- [Hook Persistence: Why Agent State Survives Restarts](/blog/hook-persistence) -- How hooked beads persist across crashes and session boundaries so agents always find their assigned work