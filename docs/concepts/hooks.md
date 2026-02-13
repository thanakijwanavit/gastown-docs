---
title: "Hooks (Persistence)"
sidebar_position: 2
description: "Hooks are Gas Town's durability primitive -- persistent attachment points that store work state surviving crashes, restarts, handoffs, and compaction."
---

# Hooks (Persistence)

Hooks are Gas Town's **durability primitive**. A hook is a persistent attachment point where work state is stored in a way that survives crashes, restarts, handoffs, context compaction, and even machine failures. Hooks are what make Gas Town agents self-propelling -- an agent always knows what to do by checking its hook.

---

## The Problem Hooks Solve

AI coding agents are inherently ephemeral. Sessions can end for many reasons:

- Context window fills up
- Session crashes or times out
- Operator requests a handoff
- Machine restarts

Without hooks, all in-flight work state would be lost on every session boundary. The agent would restart with no memory of what it was doing.

:::danger[Without Hooks]

Agent starts -> Does half the work -> Context fills up -> Session ends -> **All progress context lost** -> New session has no idea what to do

:::

:::success[With Hooks]

Agent starts -> Does half the work -> Context fills up -> Session ends -> New session checks hook -> **Finds work + molecule progress** -> Resumes seamlessly

:::

## How Hooks Work

Hooks are implemented as **git worktrees** with attached metadata. When work is "hooked" to an agent, the bead ID and molecule state are recorded in a persistent location tied to that agent's working directory.

```mermaid
graph TD
    A[Agent Session 1] -->|crashes| X[Session Lost]
    H[Hook<br/>git worktree] -->|persists| H
    A -->|writes progress to| H
    B[Agent Session 2] -->|reads from| H
    B -->|resumes work| W[Continues Work]
```text

The hook stores:

- **Hook bead** -- The bead ID of the assigned work
- **Molecule state** -- Which step of the workflow the agent was on
- **Branch state** -- The git branch and any uncommitted progress

Because this is all stored in the git worktree (filesystem), it survives any session boundary.

## The Propulsion Principle

> **"If it's on your hook, YOU RUN IT."**

This is Gas Town's core scheduling rule. It replaces centralized job schedulers with a simple, crash-safe protocol:

1. Agent starts a new session
2. Agent runs `gt prime` to load context
3. Agent checks `gt hook` for attached work
4. **If work found** -- Execute it immediately
5. **If no work** -- Check inbox, then wait for instructions

This creates **automatic momentum**. Agents are self-propelled by their hooks. No coordinator needs to tell them what to do -- they discover it themselves every time they start.

```mermaid
flowchart TD
    Start[Session Start] --> Prime[gt prime]
    Prime --> Hook{gt hook}
    Hook -->|Work found| Execute[Execute molecule]
    Hook -->|No work| Inbox[Check gt mail inbox]
    Inbox -->|Mail found| Process[Process messages]
    Inbox -->|Empty| Wait[Wait for instructions]
    Execute -->|Done| Submit[gt done]
    Execute -->|Context full| Handoff[gt handoff]
    Handoff --> Start
```text

## Commands

### Checking Your Hook

```bash
# Show what is currently on your hook
gt hook
```text

Output shows the hooked bead ID and any attached molecule:

```text
Hook: gt-a1b2c  "Fix login bug"
  Molecule: mol-polecat-work (step: implement)
  Branch: polecat/toast
  Status: in_progress
```text

### Manually Hooking Work

```bash
# Attach a bead to your hook
gt hook gt-a1b2c
```text

This is rarely done manually. Most hooking happens through `gt sling`.

### Slinging Work

The `gt sling` command is the primary way to assign work to agents. It hooks a bead to the target and spawns a worker:

```bash
# Assign to a rig (auto-spawns a polecat)
gt sling gt-a1b2c myproject

# Assign to a specific agent
gt sling gt-a1b2c myproject --agent cursor

# Assign multiple items
gt sling gt-a1b2c gt-d3e4f myproject
```text

What `gt sling` does internally:

1. Changes bead status to `hooked`
2. Attaches work to the target agent's hook
3. Spawns a polecat (ephemeral worker) in the rig
4. The polecat's startup sequence finds the hook
5. The polecat begins executing the assigned molecule

### Removing Work from a Hook

```bash
# Remove a bead from the hook without completing it
gt unsling gt-a1b2c
```text

This releases the work back to the available pool without marking it done. Another agent can pick it up later.

## Hook Persistence Guarantees

Hooks are the core mechanism behind [GUPP](gupp.md) (the Gas Town Universal Propulsion Principle). They ensure that no session boundary can lose work state. Hooks survive every type of disruption:

| Disruption | Hook Status |
|-----------|-------------|
| Session restart | Preserved -- new session reads hook on startup |
| Context compaction | Preserved -- hook is in filesystem, not context |
| Agent crash | Preserved -- git worktree is durable |
| Handoff (`gt handoff`) | Preserved -- successor session inherits hook |
| Machine reboot | Preserved -- git worktree is on disk |
| Manual session kill | Preserved -- hook outlives the process |

## How Hooks Drive Agent Behavior

Different agent roles respond to hooks differently:

### Polecats (Ephemeral Workers)

When a polecat spawns:

1. `gt prime` runs automatically (SessionStart hook)
2. Prime reads the hook and injects the assigned bead
3. Polecat executes the `mol-polecat-work` molecule
4. On completion, `gt done` submits work and nukes the sandbox
5. **Done means gone** -- the polecat ceases to exist

### Persistent Agents (Witness, Refinery, Deacon)

Persistent agents use hooks to track their patrol molecules:

1. On startup, check hook for active patrol molecule
2. If found, resume the patrol from the last completed step
3. If not found, create a new patrol molecule and hook it
4. Run patrol cycles until context fills up
5. Handoff to fresh session, which picks up from the hook

### The Mayor

The Mayor's hook typically holds a coordination molecule or convoy management task. The Mayor checks its hook on each session start to resume strategic planning.

## Hook and Molecule Integration

Hooks and [Molecules](molecules.md) work together to provide crash-safe workflows:

```text
Hook
├── hook_bead: gt-a1b2c        # The assigned issue
└── molecule: mol-polecat-work  # The workflow template
    ├── step: load-context      [done]
    ├── step: branch-setup      [done]
    ├── step: implement         [in_progress]  <-- resume here
    ├── step: self-review       [pending]
    └── step: submit-and-exit   [pending]
```text

When a session restarts, the agent:

1. Reads the hook to find `gt-a1b2c`
2. Reads the molecule to find it is on the `implement` step
3. Resumes implementation without repeating earlier steps

This is why Gas Town agents can work on complex tasks across many sessions without losing progress.

:::tip[Best Practice]

Always check `gt hook` at the start of a session before doing anything else. If work is on your hook, that is your top priority. The Propulsion Principle ensures agents stay focused and productive.

:::

## See Also

- **[Beads](beads.md)** -- The hook stores the bead ID of the assigned work; the bead's status transitions to `hooked` when slung
- **[Molecules & Formulas](molecules.md)** -- The molecule attached to a hook tracks step-level progress, enabling crash-safe resume
- **[GUPP & NDI](gupp.md)** -- Hooks are the primary mechanism that makes GUPP possible: work state persists across every kind of disruption
- **[Rigs](rigs.md)** -- Hooks are implemented as git worktrees within a rig's directory structure
- **[Gates](gates.md)** -- When a molecule step is gated, the hook preserves the parked state until the gate closes
- **[Session Cycling](session-cycling.md)** -- Hooks persist across session boundaries, enabling context refresh without losing work