---
title: "Deacon -- Town-Level Watchdog"
sidebar_position: 2
description: "> The Deacon is the immune system of Gas Town. It monitors the health of every agent, manages lifecycles, and ensures the system self-heals when things go wr..."
---

# Deacon -- Town-Level Watchdog

> The Deacon is the immune system of Gas Town. It monitors the health of every agent, manages lifecycles, and ensures the system self-heals when things go wrong.

---

## Overview

The Deacon is a persistent, town-level agent responsible for health monitoring and lifecycle management across the entire Gas Town installation. It receives periodic heartbeats from the Daemon, monitors all Witnesses, manages Dogs for cross-rig infrastructure work, and performs boot triage when the system starts up. If the Mayor is the brain, the Deacon is the nervous system -- always watching, always ready to respond.

## Key Characteristics

| Property | Value |
|----------|-------|
| **Scope** | Town-level (all rigs) |
| **Lifecycle** | Persistent |
| **Instance count** | 1 per town |
| **Session type** | Long-running Claude Code session |
| **Patrol cycle** | 5 minutes |
| **Location** | `~/gt/deacon/` |
| **Git identity** | No |
| **Mailbox** | Yes |

## Responsibilities

### 1. Receive Daemon Heartbeats

The Daemon (a Go process) sends heartbeats to the Deacon on a 3-minute interval. These heartbeats trigger the Deacon's patrol cycle and carry system state information.

```mermaid
sequenceDiagram
    participant Dm as Daemon
    participant Dc as Deacon
    participant W as Witnesses

    loop Every 3 minutes
        Dm->>Dc: Heartbeat + system state
        Dc->>Dc: Process patrol cycle
        Dc->>W: Check all Witnesses
    end
```

### 2. Monitor All Witnesses

The Deacon supervises every Witness in every rig. If a Witness becomes unresponsive or dies, the Deacon restarts it:

| Witness State | Deacon Action |
|---------------|---------------|
| Healthy | No action |
| Slow to respond | Nudge |
| Unresponsive | Restart session |
| Dead | Spawn new Witness |

### 3. Manage Dogs

Dogs are reusable infrastructure workers managed by the Deacon for cross-rig tasks. The Deacon spawns, assigns, and monitors Dogs:

```bash
gt dog list          # List active dogs
gt dog spawn         # Create a new dog
```

### 4. Patrol Cycle

Every 5 minutes, the Deacon runs a patrol cycle:

```mermaid
flowchart TD
    Start["Patrol Tick"]
    Check["Check All Witnesses"]
    Stale{"Any Stale?"}
    Nudge["Nudge Stale Witness"]
    Response{"Responded?"}
    Restart["Restart Witness"]
    Hooks["Check Stale Hooks"]
    Orphans["Cleanup Orphans"]
    Zombies["Scan for Zombies"]
    Done["Patrol Complete"]

    Start --> Check
    Check --> Stale
    Stale -->|Yes| Nudge
    Nudge --> Response
    Response -->|No| Restart
    Response -->|Yes| Hooks
    Stale -->|No| Hooks
    Restart --> Hooks
    Hooks --> Orphans
    Orphans --> Zombies
    Zombies --> Done
```

### 5. Boot Triage Process

When the system starts up (or after a crash), the Deacon runs boot triage to assess and recover state:

```mermaid
flowchart LR
    Observe["Observe<br/>System State"]
    Decide["Decide<br/>Actions Needed"]
    Act["Act<br/>Execute Recovery"]

    Observe --> Decide --> Act
```

**Boot triage steps:**

1. **Observe** -- Inventory all rigs, check agent sessions, scan for orphaned work
2. **Decide** -- Determine which agents need starting, which work needs reassignment
3. **Act** -- Start Witnesses, restart stalled agents, re-sling orphaned work

### 6. Handle Escalations from Witnesses

When a Witness encounters a problem it cannot resolve (e.g., a rig-level failure), it escalates to the Deacon. The Deacon either handles it directly or escalates further to the Mayor.

## Commands

### Deacon Management

| Command | Description |
|---------|-------------|
| `gt deacon start` | Start the Deacon session |
| `gt deacon stop` | Stop the Deacon session |
| `gt deacon status` | Check Deacon health and patrol state |

### Maintenance Commands

| Command | Description |
|---------|-------------|
| `gt deacon stale-hooks` | Find and report hooks with no active agent |
| `gt deacon cleanup-orphans` | Remove orphaned worktrees and temp files |
| `gt deacon zombie-scan` | Detect and report zombie agent sessions |

## Configuration

The Deacon's behavior is configured through town-level settings:

| Setting | Default | Description |
|---------|---------|-------------|
| Patrol interval | 5 min | Time between patrol cycles |
| Heartbeat timeout | 10 min | Time before Daemon heartbeat considered missed |
| Witness restart threshold | 3 missed patrols | Missed patrols before restarting a Witness |
| Zombie age threshold | 30 min | Idle time before a session is considered zombie |

## Deacon State

The Deacon tracks the following state:

| State File | Purpose |
|------------|---------|
| `~/gt/deacon/state.json` | Current patrol state and agent inventory |
| `~/gt/deacon/dogs/` | Dog workspace directory |
| `~/gt/deacon/CLAUDE.md` | Deacon agent context and instructions |

## Interaction Diagram

```mermaid
graph TD
    Daemon["Daemon<br/>(Go process)"]
    Deacon["Deacon"]
    Mayor["Mayor"]
    Boot["Boot Dog"]
    Dogs["Dogs"]
    W1["Witness<br/>Rig 1"]
    W2["Witness<br/>Rig 2"]
    W3["Witness<br/>Rig 3"]

    Daemon -->|heartbeat 3m| Deacon
    Mayor -->|strategic direction| Deacon
    Deacon -->|manages| Boot
    Deacon -->|manages| Dogs
    Deacon -->|monitors| W1
    Deacon -->|monitors| W2
    Deacon -->|monitors| W3
    W1 -->|escalates| Deacon
    W2 -->|escalates| Deacon
    W3 -->|escalates| Deacon
    Deacon -->|escalates| Mayor
```

## Tips and Best Practices

:::tip[Check Deacon Status After Restarts]

After restarting the Daemon or recovering from a crash, run `gt deacon status` to verify the Deacon has completed boot triage and all Witnesses are healthy.

:::

:::tip[Use Zombie Scan Proactively]

Run `gt deacon zombie-scan` periodically if you suspect stuck sessions. The Deacon does this automatically, but manual scans give you immediate visibility.

:::

:::warning[Do Not Run Multiple Deacons]

Like the Mayor, the Deacon is a singleton. Running multiple instances will cause conflicting health decisions and potential data corruption.

:::

:::info[Deacon vs Mayor]

The Deacon handles **operational health** (is everything running?). The Mayor handles **strategic coordination** (what should we build?). They communicate but have non-overlapping responsibilities.


:::