---
title: "Operations"
sidebar_position: 0
description: "Day-to-day operational guides for starting, monitoring, troubleshooting, and extending your Gas Town agent fleet."
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

```text
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

---

## Incident Response Playbook

When something goes wrong, follow this decision tree:

```text
Is the system completely down?
├── Yes → gt daemon start && gt start --all (see Lifecycle: Emergency Recovery)
└── No
    ├── Is one rig broken?
    │   └── gt rig reboot <name> (see Lifecycle: Emergency Recovery)
    ├── Are polecats stuck?
    │   └── gt shutdown --polecats-only (see Troubleshooting: Stale Polecats)
    ├── Is the merge queue backed up?
    │   └── gt mq status (see Troubleshooting: Merge Conflicts)
    ├── Are costs spiking?
    │   └── gt costs --by-agent (see Escalations: Cost Spike scenario)
    └── Are escalations piling up?
        └── gt escalate list (see Escalations: Managing Escalations)
```

## Weekly Review Checklist

Run these checks once a week to catch slow-building problems:

```bash
# 1. Overall system health
gt doctor

# 2. Cost trends for the week
gt costs --since 7d --by-rig

# 3. Find orphaned resources consuming disk
gt orphans

# 4. Review and close stale escalations
gt escalate stale

# 5. Check for stranded convoys
gt convoy stranded

# 6. Clean up finished polecat worktrees
gt cleanup
```

## Operational Anti-Patterns

Avoid these common mistakes when running Gas Town:

| Anti-Pattern | Why It Hurts | What to Do Instead |
|-------------|-------------|-------------------|
| Manually fixing things on `main` | Bypasses the merge queue; can conflict with in-flight polecat work | Use a crew workspace or sling a fix bead |
| Ignoring P3 escalations | They accumulate and mask real problems | Review and close (or promote) P3s weekly |
| Restarting everything when one thing breaks | Disrupts working agents unnecessarily | Use surgical restarts: `gt rig reboot` or per-agent commands |
| Never running `gt cleanup` | Disk fills with orphaned worktrees | Schedule regular cleanup or add it to your weekly checklist |
| Over-slinging work to one rig | Creates merge queue bottlenecks | Distribute work across rigs when possible |

## Related

- **[Architecture](../architecture/index.md)** — How the supervisor tree enables self-healing operations
- **[Agents](../agents/index.md)** — Roles and responsibilities of each agent type
- **[CLI Reference](../cli-reference/index.md)** — Full command reference for operational tasks
- **[Guides](../guides/index.md)** — Usage patterns, troubleshooting, and cost management