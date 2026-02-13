---
title: "gt warrant"
sidebar_position: 17
description: "Manage death warrants for agents that need forced termination. File, list, and execute warrants through Boot's triage cycle."
---

# gt warrant

Manage death warrants for agents that need termination.

```bash
gt warrant [command]
```

## Description

Death warrants are filed when an agent is stuck, unresponsive, or needs forced termination. Boot handles warrant execution during triage cycles.

The warrant lifecycle:

1. **Deacon/Witness files a warrant** with a reason
2. **Boot picks up the warrant** during triage
3. **Boot executes the warrant** (terminates session, updates state)
4. **Warrant is marked as executed**

Warrants are stored in `~/gt/warrants/` as JSON files.

## Subcommands

| Command | Description |
|---------|-------------|
| [`file`](#gt-warrant-file) | File a death warrant for an agent |
| [`list`](#gt-warrant-list) | List pending warrants |
| [`execute`](#gt-warrant-execute) | Execute a warrant (terminate agent) |

---

## gt warrant file

File a death warrant for an agent that needs termination.

```bash
gt warrant file <target> [flags]
```

The target should be an agent path like `gastown/polecats/alpha` or `deacon/dogs/bravo`.

**Flags:**

| Flag | Short | Description |
|------|-------|-------------|
| `--reason <text>` | `-r` | Reason for the warrant (required unless `--stdin`) |
| `--stdin` | | Read reason from stdin (avoids shell quoting issues) |

**Examples:**

```bash
gt warrant file gastown/polecats/alpha --reason "Zombie: no session, idle >10m"
gt warrant file deacon/dogs/bravo --reason "Stuck: working on task for >2h"
```

---

## gt warrant list

List all pending (unexecuted) warrants.

```bash
gt warrant list [flags]
```

**Flags:**

| Flag | Short | Description |
|------|-------|-------------|
| `--all` | `-a` | Include executed warrants |

**Examples:**

```bash
gt warrant list
gt warrant list --all
```

---

## gt warrant execute

Execute a pending warrant for the specified target.

```bash
gt warrant execute <target> [flags]
```

This will:

1. Find the warrant for the target
2. Terminate the agent's tmux session (if exists)
3. Mark the warrant as executed

**Flags:**

| Flag | Short | Description |
|------|-------|-------------|
| `--force` | `-f` | Execute even without a warrant |

**Examples:**

```bash
gt warrant execute gastown/polecats/alpha
gt warrant execute deacon/dogs/bravo --force
```

:::warning

Using `--force` bypasses the warrant system entirely. Only use this for emergency termination when you can't wait for the normal warrant flow.

:::

## Related

- [Boot](../agents/boot.md) -- Infrastructure helper that executes warrants during triage
- [Deacon](../agents/deacon.md) -- Health-check orchestrator that files warrants
- [Witness](../agents/witness.md) -- Polecat monitor that escalates stuck agents
- [Lifecycle Management](../operations/lifecycle.md) -- Agent lifecycle and termination flows
