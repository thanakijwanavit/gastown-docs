---
title: "gt warrant"
sidebar_position: 18
description: "File and execute death warrants for stuck or unresponsive agents that need controlled termination."
---

# gt warrant

Manage death warrants for agents that need termination.

Death warrants provide a controlled way to terminate agents that are stuck, unresponsive, or otherwise need forced termination. The warrant system ensures proper cleanup and work recovery before killing an agent.

## Warrant Lifecycle

1. **Deacon/Witness files a warrant** with a reason (e.g., "agent stuck in loop for 30 minutes")
2. **Boot picks up the warrant** during its triage cycle
3. **Boot executes the warrant** — terminates the session, recovers in-progress work, updates state
4. **Warrant is marked as executed** and archived

Warrants are stored as JSON files in `~/gt/warrants/`.

## Commands

### `gt warrant file`

File a death warrant for an agent.

```bash
gt warrant file --agent gastowndocs/polecats/alpha --reason "Stuck in infinite loop"
```

### `gt warrant list`

List pending warrants that haven't been executed yet.

```bash
gt warrant list
```

### `gt warrant execute`

Execute a warrant — terminate the agent and clean up.

```bash
gt warrant execute <warrant-id>
```

## When Warrants Are Filed

Warrants are typically filed automatically by patrol agents when they detect:

- **Zombie processes** — agents whose tmux sessions are gone but state still shows "running"
- **Infinite loops** — agents that have been in the same state for an abnormally long time
- **Resource exhaustion** — agents consuming excessive tokens without progress
- **Stale sessions** — sessions that exceed maximum age without cycling

## See Also

- [Lifecycle](../operations/lifecycle.md) — Agent lifecycle management including death warrants
- [Boot](../agents/boot.md) — The triage agent that processes warrants
- [Deacon](../agents/deacon.md) — Files warrants when agents need termination
