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

    Daemon -->|heartbeat| Deacon
    Mayor --> Deacon
    Deacon --> W1
    Deacon --> W2
    W1 --> P1a
    W1 --> P1b
    P1a -->|MR| R1
    P1b -->|MR| R1
    P2a -->|MR| R2
    R1 -->|merge| Main1[main]
    R2 -->|merge| Main2[main]
```

Gas Town is a hierarchical supervisor system where each level monitors the level below it, ensuring work progresses reliably even when individual agents crash or stall.
