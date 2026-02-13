---
title: "gt town"
sidebar_position: 18
description: "Town-level operations including session cycling, status, and navigation between mayor and deacon."
---

# gt town

Commands for town-level operations including session cycling, status checks, and navigation.

```bash
gt town [command]
```

## Description

The `gt town` commands manage **town-level infrastructure** -- the Mayor and Deacon sessions that run above individual rigs. The town is the top of the Gas Town hierarchy:

```text
Town (~/gt/)
├── Mayor   ← Strategic coordinator (gt town manages this level)
├── Deacon  ← Infrastructure patrol
├── Rig A   ← Project container (managed by gt rig)
├── Rig B
└── Rig C
```

Town commands let you navigate between the Mayor and Deacon tmux sessions, check overall town health, and manage the town lifecycle.

:::info[Town vs Rig]

`gt town` operates at the **town level** (Mayor + Deacon). For rig-level agents (Witness, Refinery, Polecats), use [`gt rig`](rigs.md) instead.

:::

## Subcommands

| Command | Description |
|---------|-------------|
| [`next`](#gt-town-next) | Switch to next town session (mayor/deacon) |
| [`prev`](#gt-town-prev) | Switch to previous town session (mayor/deacon) |
| [`status`](#gt-town-status) | Show town-wide health summary |
| [`shutdown`](#gt-town-shutdown) | Graceful shutdown of all town agents |

---

## gt town next

Switch to the next town session (mayor/deacon).

```bash
gt town next
```

Cycles forward through town-level tmux sessions, allowing quick navigation between the mayor and deacon sessions. Useful when monitoring or debugging town-level coordination.

```bash
# You're viewing the Mayor session. Switch to Deacon:
gt town next

# Now viewing Deacon. Switch back to Mayor:
gt town next
```

---

## gt town prev

Switch to the previous town session (mayor/deacon).

```bash
gt town prev
```

Cycles backward through town-level tmux sessions. Functionally equivalent to `gt town next` when there are only two sessions (Mayor and Deacon), but maintains directional consistency with `gt rig prev`.

---

## gt town status

Show the overall health and status of the town.

```bash
gt town status
```

Displays a summary of:

- **Mayor** -- Current state, active convoys, pending dispatches
- **Deacon** -- Patrol status, last gate evaluation, health check results
- **Rigs** -- Per-rig status summary (active, parked, docked)
- **Agents** -- Total count of running agents across all rigs

### Example Output

```text
🏭 Gas Town Status
==================
Mayor:   ACTIVE (session: gt-mayor, uptime: 4h23m)
Deacon:  ACTIVE (session: gt-deacon, last patrol: 2m ago)

Rigs:
  myproject    Active   2 polecats   1 MR pending
  docs         Active   0 polecats   0 MR pending
  api-server   Docked   -            -

Agents: 8 total (2 town + 4 rig + 2 polecats)
Gates:  1 open (timer: 12m remaining)
```

---

## gt town shutdown

Gracefully shut down all town agents.

```bash
gt town shutdown
```

Initiates the `mol-town-shutdown` workflow:

1. Signals all rigs to park (stop accepting new work)
2. Waits for in-flight polecats to complete or hand off
3. Stops Witness and Refinery in each rig
4. Stops the Deacon
5. Stops the Mayor

:::warning[Data Safety]

`gt town shutdown` waits for in-flight work to land before stopping agents. If you need an immediate stop (accepting potential work loss), use `gt town shutdown --force`.

:::

```bash
# Graceful shutdown (waits for work to land)
gt town shutdown

# Forced shutdown (immediate, may lose in-flight work)
gt town shutdown --force
```

## When to Use

Town-level navigation and management is useful when:

- **Debugging coordination issues** -- The Mayor and Deacon handle different aspects of town operations. Cycling between them lets you compare what each is seeing.
- **Monitoring town health** -- Check the Deacon's patrol state, then switch to the Mayor to see strategic context.
- **During incident response** -- Quickly switch between sessions to understand both the health monitoring (Deacon) and coordination (Mayor) perspectives.
- **End of day shutdown** -- Use `gt town shutdown` to gracefully stop all agents before leaving.
- **Checking overall status** -- `gt town status` gives a single-pane view of the entire Gas Town deployment.

:::tip
If you need to interact with rig-level agents (Witness, Refinery, Polecats), use `gt rig next/prev` instead. `gt town` only cycles between Mayor and Deacon sessions.
:::

## Command Reference

| Command | Description |
|---------|-------------|
| `gt town next` | Switch to next town session |
| `gt town prev` | Switch to previous town session |
| `gt town status` | Show town-wide health and status |
| `gt town shutdown` | Graceful shutdown of all agents |
| `gt town shutdown --force` | Immediate shutdown (may lose work) |

## Examples

```bash
# Check overall town health
gt town status

# Cycle to the next town-level session
gt town next

# Cycle back to the previous town-level session
gt town prev

# Common workflow: check Deacon health, then Mayor strategy
gt town next          # Switch to Deacon
# ... inspect patrol state ...
gt town next          # Switch to Mayor
# ... check coordination status ...

# End-of-day: graceful shutdown
gt town shutdown
```

## Related

- [Starting & Stopping](../operations/lifecycle.md) -- Full lifecycle management for town and rig agents
- [Architecture Overview](../architecture/overview.md) -- How Mayor and Deacon fit into the Gas Town architecture
- [Mayor](../agents/mayor.md) -- The Mayor agent that coordinates across rigs
- [Deacon](../agents/deacon.md) -- The Deacon agent that manages infrastructure
- [gt rig](rigs.md) -- Rig-level agent management (Witness, Refinery, Polecats)
- [Monitoring & Observability](../operations/monitoring.md) -- Detailed monitoring beyond `gt town status`
