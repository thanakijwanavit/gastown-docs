---
title: "gt town"
sidebar_position: 18
description: "Town-level operations including session cycling between mayor and deacon."
---

# gt town

Commands for town-level operations including session cycling.

```bash
gt town [command]
```

## Description

The `gt town` commands manage navigation between **town-level sessions** -- the Mayor and Deacon. These are the two persistent agents that run at the Gas Town infrastructure level (above individual rigs).

Town sessions live in tmux and `gt town` provides quick cycling between them, similar to how `gt rig` commands manage rig-level agents.

## Subcommands

| Command | Description |
|---------|-------------|
| [`next`](#gt-town-next) | Switch to next town session (mayor/deacon) |
| [`prev`](#gt-town-prev) | Switch to previous town session (mayor/deacon) |

---

## gt town next

Switch to the next town session (mayor/deacon).

```bash
gt town next
```

Cycles forward through town-level tmux sessions, allowing quick navigation between the mayor and deacon sessions. Useful when monitoring or debugging town-level coordination.

---

## gt town prev

Switch to the previous town session (mayor/deacon).

```bash
gt town prev
```

Cycles backward through town-level tmux sessions.

## When to Use

Town-level navigation is useful when:

- **Debugging coordination issues** -- The Mayor and Deacon handle different aspects of town operations. Cycling between them lets you compare what each is seeing.
- **Monitoring town health** -- Check the Deacon's patrol state, then switch to the Mayor to see strategic context.
- **During incident response** -- Quickly switch between sessions to understand both the health monitoring (Deacon) and coordination (Mayor) perspectives.

:::tip
If you need to interact with rig-level agents (Witness, Refinery, Polecats), use `gt rig next/prev` instead. `gt town` only cycles between Mayor and Deacon sessions.
:::

## Examples

```bash
# Cycle to the next town-level session
gt town next

# Cycle back to the previous town-level session
gt town prev

# Common workflow: check Deacon health, then Mayor strategy
gt town next          # Switch to Deacon
# ... inspect patrol state ...
gt town next          # Switch to Mayor
# ... check coordination status ...
```

## Related

- [Starting & Stopping](../operations/lifecycle.md) -- Full lifecycle management for town and rig agents
- [Architecture Overview](../architecture/overview.md) -- How Mayor and Deacon fit into the Gas Town architecture
- [Mayor](../agents/mayor.md) -- The Mayor agent that coordinates across rigs
- [Deacon](../agents/deacon.md) -- The Deacon agent that manages infrastructure
