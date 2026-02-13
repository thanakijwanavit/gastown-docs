---
title: "Architecture"
sidebar_position: 0
description: "Gas Town's architecture draws from Erlang's supervisor trees and mailbox patterns — battle-tested approaches to building reliable distributed systems."
---

# Architecture

Gas Town's architecture draws from Erlang's supervisor trees and mailbox patterns — battle-tested approaches to building reliable distributed systems.

## Sections

- [System Overview](overview.md) — High-level architecture and components
- [Agent Hierarchy](agent-hierarchy.md) — How agents supervise each other
- [Work Distribution](work-distribution.md) — How tasks flow through the system
- [Design Principles](design-principles.md) — Core patterns and philosophy

## At a Glance

```mermaid
graph TB
    subgraph Town ["Town (~/gt/)"]
        Mayor["Mayor<br/>Global Coordinator"]
        Deacon["Deacon<br/>Health Monitor"]
        Daemon["Daemon<br/>Background Scheduler"]
    end

    subgraph Rig1 ["Rig: myproject"]
        W1["Witness"]
        R1["Refinery"]
        P1a["Polecat: Toast"]
        P1b["Polecat: Alpha"]
        C1["Crew: dave"]
    end

    subgraph Rig2 ["Rig: docs"]
        W2["Witness"]
        R2["Refinery"]
        P2a["Polecat: Bravo"]
    end

    Daemon -->|heartbeat 3m| Deacon
    Mayor -->|strategy| Deacon
    Deacon -->|monitors| W1
    Deacon -->|monitors| W2
    W1 -->|watches| P1a
    W1 -->|watches| P1b
    P1a -->|gt done → MR| R1
    P1b -->|gt done → MR| R1
    P2a -->|gt done → MR| R2
    R1 -->|merge| Main1[main]
    R2 -->|merge| Main2[main]
```

## How It Fits Together

Gas Town is a hierarchical supervisor system with three layers:

- **Town level** — The Mayor sets strategy, the Deacon runs health checks, and the Daemon provides heartbeats. These are singleton agents shared across all projects.
- **Rig level** — Each project (rig) has its own Witness watching polecat health and a Refinery serializing merges to main. These agents are rig-scoped.
- **Worker level** — Polecats are ephemeral workers spawned for one task and nuked when done. Crew members are persistent human-managed workspaces. Both do the actual coding work.

Each level monitors the level below it, ensuring work progresses reliably even when individual agents crash or stall. When a polecat gets stuck, the Witness detects it and escalates to the Deacon, who can file a warrant for termination or trigger recovery.
