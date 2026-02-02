---
title: "Mayor -- Global Coordinator"
sidebar_position: 1
description: "> The Mayor is the brain of Gas Town. It receives instructions from the human overseer, decomposes them into actionable work, and orchestrates the entire age..."
---

# Mayor -- Global Coordinator

> The Mayor is the brain of Gas Town. It receives instructions from the human overseer, decomposes them into actionable work, and orchestrates the entire agent hierarchy to deliver results.

---

## Overview

The Mayor is the primary human-facing agent in Gas Town. When you run `gt mayor attach`, you are talking directly to the Mayor. It understands your goals, creates issues (beads), bundles them into convoys, assigns work to rigs, and tracks progress through completion. The Mayor is the only agent that bridges the gap between natural language instructions and the structured work system.

## Key Characteristics

| Property | Value |
|----------|-------|
| **Scope** | Town-level (all rigs) |
| **Lifecycle** | Persistent |
| **Instance count** | 1 per town |
| **Session type** | Long-running Claude Code session |
| **Patrol cycle** | On-demand (not periodic) |
| **Location** | `~/gt/mayor/` and `~/gt/<rig>/mayor/rig/` |
| **Git identity** | Yes |
| **Mailbox** | Yes |

## Responsibilities

### 1. Receive Human Instructions

The Mayor is your interface to Gas Town. You describe what you want built, fixed, or changed in natural language:

```
> Fix the 5 failing tests in auth and add input validation to registration.
```

The Mayor parses this into discrete work items.

### 2. Create Issues and Convoys

For each piece of work, the Mayor creates a bead (issue) in the tracking system, then bundles related beads into a convoy for batch tracking:

```bash
# The Mayor does this internally:
bd create --title "Fix auth test: login_expired" --type bug --priority high
bd create --title "Add email validation to registration" --type feature
gt convoy create "Auth Improvements" gt-a1b2c gt-d3e4f
```

### 3. Assign Work to Rigs

The Mayor uses `gt sling` to assign beads to rigs, which triggers polecat spawning:

```bash
gt sling gt-a1b2c myproject    # Assigns issue to rig, spawns polecat
gt sling gt-d3e4f myproject    # Another issue, another polecat
```

### 4. Route Escalations

When agents encounter problems they cannot solve, escalations flow upward to the Mayor. The Mayor either resolves them, reassigns the work, or escalates to the human overseer.

### 5. Track Convoy Progress

The Mayor monitors convoy completion, ensuring all assigned work reaches the finish line:

```bash
gt convoy list
gt convoy show hq-cv-001
```

### 6. Strategic Direction to Deacon

The Mayor provides high-level direction to the Deacon for health monitoring priorities and lifecycle decisions.

## Mayor Workflow (MEOW)

The Mayor Execution and Orchestration Workflow (MEOW) is the standard operating procedure for the Mayor agent:

```mermaid
flowchart TD
    Start["Receive Instructions"]
    Analyze["Analyze & Decompose"]
    Create["Create Beads"]
    Convoy["Bundle into Convoy"]
    Assign["Sling to Rigs"]
    Monitor["Monitor Progress"]
    Escalation{"Escalation?"}
    Resolve["Resolve or Reassign"]
    Complete{"All Done?"}
    Report["Report to Overseer"]

    Start --> Analyze
    Analyze --> Create
    Create --> Convoy
    Convoy --> Assign
    Assign --> Monitor
    Monitor --> Escalation
    Escalation -->|Yes| Resolve
    Resolve --> Monitor
    Escalation -->|No| Complete
    Complete -->|No| Monitor
    Complete -->|Yes| Report
```

**MEOW Steps:**

1. **Receive** -- Accept instructions from human or mail
2. **Analyze** -- Break down into discrete, parallelizable tasks
3. **Create** -- Generate beads with clear descriptions and acceptance criteria
4. **Bundle** -- Group related beads into a convoy
5. **Assign** -- Sling beads to target rigs
6. **Monitor** -- Track convoy progress, handle escalations
7. **Report** -- Summarize results to overseer

## Commands

### Primary Commands

| Command | Description |
|---------|-------------|
| `gt mayor attach` | Open an interactive session with the Mayor |
| `gt mayor start` | Start the Mayor session in the background |
| `gt mayor stop` | Stop the Mayor session |
| `gt mayor status` | Check if the Mayor is running and view session info |

### Commands the Mayor Uses

| Command | Purpose |
|---------|---------|
| `gt sling <bead> <rig>` | Assign work to a rig |
| `gt convoy create` | Bundle beads into a convoy |
| `gt convoy list` | View convoy status |
| `gt mail inbox` | Check incoming messages |
| `gt mail send` | Send messages to agents |
| `gt escalate` | Escalate issues to overseer |
| `gt rig list` | View all rigs and their status |
| `gt feed` | View the activity feed |
| `gt broadcast` | Send message to all agents |

## Context Files

The Mayor maintains state through several context files:

| File | Purpose |
|------|---------|
| `~/gt/mayor/town.json` | Town metadata -- rig list, global config |
| `~/gt/mayor/rigs.json` | Rig status and configuration summary |
| `~/gt/mayor/overseer.json` | Overseer preferences and escalation rules |
| `~/gt/mayor/CLAUDE.md` | Mayor agent context and instructions |
| `~/gt/<rig>/mayor/rig/CLAUDE.md` | Per-rig Mayor context |

## Interaction Diagram

```mermaid
sequenceDiagram
    participant H as Human
    participant M as Mayor
    participant D as Deacon
    participant P as Polecat
    participant R as Refinery

    H->>M: "Fix auth tests and add validation"
    M->>M: Decompose into beads
    M->>M: Create convoy
    M->>P: gt sling gt-a1 myproject
    M->>P: gt sling gt-b2 myproject
    P->>P: Work on task
    P->>R: gt done (submit MR)
    R->>R: Rebase + validate + merge
    P-->>M: Escalation (if blocked)
    M-->>H: Escalation (if unresolvable)
    M->>H: Convoy complete report
```

## Tips and Best Practices

:::tip[Be Specific with Instructions]

The more specific your instructions, the better the Mayor decomposes them. Include acceptance criteria, edge cases, and constraints when possible.

:::

:::tip[Check Convoy Progress]

Use `gt convoy list` and `gt convoy show` regularly to track batch progress. The Mayor monitors automatically, but you can intervene at any time.

:::

:::tip[Use Escalations]

If you see something the Mayor should know about, use `gt mail send mayor "..."` to communicate directly. The Mayor checks its inbox as part of its workflow.

:::

:::warning[One Mayor Per Town]

Gas Town supports exactly one Mayor per town. Running multiple Mayor sessions will cause coordination conflicts.


:::