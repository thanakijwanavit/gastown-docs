---
title: "Operations"
sidebar_position: 0
description: "Running Gas Town in production means managing a fleet of AI agents across multiple projects. This section covers the day-to-day operational tasks: starting a..."
---

# Operations

Running Gas Town in production means managing a fleet of AI agents across multiple projects. This section covers the day-to-day operational tasks: starting and stopping the system, monitoring health, handling escalations, troubleshooting problems, and extending functionality with plugins.

---

## Sections

| Guide | Description |
|-------|-------------|
| [Starting & Stopping](lifecycle.md) | Launch, pause, and shut down agents and rigs |
| [Monitoring & Health](monitoring.md) | Real-time feeds, dashboards, patrols, and audits |
| [Escalation System](escalations.md) | Priority-routed alerts with severity levels |
| [Troubleshooting](troubleshooting.md) | Common issues, diagnostics, and recovery procedures |
| [Plugins](plugins.md) | Extend Gas Town with custom gates and automation |

## Operational Mindset

Gas Town is a **supervisor tree** modeled on Erlang/OTP. Understanding three key operational principles will save you hours:

### 1. The Daemon is Dumb, Agents are Smart

The daemon process is a simple Go scheduler that sends heartbeats and processes lifecycle requests. All decision-making lives in the agents. If something is wrong, look at agent state (mail, hooks, beads) rather than the daemon.

### 2. Escalations Flow Upward

```
Polecat (stuck)
  --> Witness detects stall
    --> Witness nudges polecat
      --> If still stuck: Witness escalates to Deacon
        --> Deacon escalates to Mayor
          --> Mayor escalates to Human/Overseer
```

You only need to intervene when escalations reach you. The system handles lower-level recovery automatically.

### 3. Everything is in Git

All persistent state (beads, hooks, config, context) lives in git or the filesystem. This means you can always recover from failures by inspecting git history, and you can always understand what happened by reading the activity log.

## Quick Reference

```bash
# Start everything
gt start --all

# Check system health
gt doctor

# Watch real-time activity
gt feed

# View recent agent output
gt trail

# Stop everything, keep state
gt down

# Stop and clean up
gt shutdown --all
```

:::tip[Daily Operations Checklist]

1. Check `gt feed` for activity anomalies
2. Review `gt escalate list` for unacknowledged escalations
3. Run `gt doctor` to verify system health
4. Check `gt costs` to monitor token spend
5. Review `gt convoy list` for stalled or stranded convoys


:::