---
title: "Agent Hierarchy"
sidebar_position: 2
description: "Gas Town uses a supervisor tree pattern inspired by Erlang/OTP. Each agent level monitors the level below it, providing fault tolerance and automatic recovery."
---

# Agent Hierarchy

Gas Town uses a supervisor tree pattern inspired by Erlang/OTP. Each agent level monitors the level below it, providing fault tolerance and automatic recovery.

## Supervision Tree

```mermaid
graph TD
    Daemon["Daemon<br/>(Go process)"]
    Deacon["Deacon<br/>(Town supervisor)"]
    Mayor["Mayor<br/>(Coordinator)"]
    Boot["Boot<br/>(Triage dog)"]

    Daemon -->|heartbeat 3m| Deacon
    Mayor -->|strategic direction| Deacon
    Deacon -->|spawns for triage| Boot

    subgraph "Per-Rig Supervision"
        Witness["Witness<br/>(Rig supervisor)"]
        Refinery["Refinery"]
        P1["Polecat 1"]
        P2["Polecat 2"]
        P3["Polecat 3"]
        Crew["Crew<br/>(Human devs)"]
    end

    Deacon -->|monitors| Witness
    Witness -->|watches| P1
    Witness -->|watches| P2
    Witness -->|watches| P3
    P1 -->|gt done → MR| Refinery
    P2 -->|gt done → MR| Refinery
    Refinery -->|merge| Main[main branch]
```

## Monitoring Chain

| Monitor | Watches | Detects | Action |
|---------|---------|---------|--------|
| Daemon | Deacon | Unresponsive | Restart Deacon session |
| Deacon | All Witnesses | Stuck/dead Witness | Restart Witness |
| Deacon | Boot dog | Triage needed | Spawn Boot for assessment |
| Witness | Polecats in rig | Stalled/crashed | Nudge, then nuke zombie |
| Witness | Refinery | Merge failures | Escalate to Mayor |

## Patrol Cycles

Persistent agents run patrol cycles — periodic health checks:

| Agent | Interval | Actions |
|-------|----------|---------|
| **Deacon** | 5 min | Check Witnesses, process lifecycle requests, run Boot triage |
| **Witness** | 5 min | Check polecats, detect stalls, clean zombies |
| **Refinery** | 5 min | Process merge queue, rebase and validate |
| **Daemon** | 3 min | Send heartbeat to Deacon |

## Boot Dog: The Triage Agent

The Boot dog is a special agent spawned by the Deacon to assess situations that need triage — new work arriving, health check failures, or ambiguous states. Boot performs a quick assessment and reports back to the Deacon, which then takes action (spawn polecats, escalate, etc.). Boot is short-lived and focused: assess, report, exit.

## Escalation Path

When an agent encounters a problem it cannot resolve:

```
Polecat (stuck)
  → Witness detects stall (patrol cycle)
    → Witness nudges polecat
      → If still stuck: Witness escalates to Deacon
        → Deacon escalates to Mayor
          → Mayor escalates to Human/Overseer
```

Agents can also self-escalate using `gt escalate`:

```bash
gt escalate "Brief description" -s HIGH -m "Details"
```

Severity levels control routing:

| Level | Code | Route |
|-------|------|-------|
| Critical | P0 | Bead → Mail:Mayor → Email:Human → SMS:Human |
| High | P1 | Bead → Mail:Mayor → Email:Human |
| Medium | P2 | Bead → Mail:Mayor |
| Low | P3 | Bead only |

## See Also

- **[Patrol Cycles](../concepts/patrol-cycles.md)** -- The periodic health monitoring that agents perform
- **[Escalations](../operations/escalations.md)** -- How problems travel up the hierarchy
- **[Design Principles](design-principles.md)** -- Erlang-inspired supervision and other architectural principles
