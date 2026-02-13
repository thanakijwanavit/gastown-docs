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

Cycles forward through town-level tmux sessions, allowing quick navigation between the mayor and deacon sessions.

---

## gt town prev

Switch to the previous town session (mayor/deacon).

```bash
gt town prev
```

Cycles backward through town-level tmux sessions.
