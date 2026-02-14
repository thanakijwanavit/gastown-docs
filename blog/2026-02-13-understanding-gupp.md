---
title: "Understanding GUPP: Why Crashes Don't Lose Work"
description: "How the Gas Town Universal Propulsion Principle makes multi-agent AI development crash-safe by design."
slug: understanding-gupp
authors: [gastown]
tags: [concepts, architecture]
---

Multi-agent systems are inherently chaotic. Agents crash. Sessions expire. Context windows fill up. Gas Town handles all of this gracefully thanks to one core principle: **GUPP**.

<!-- truncate -->

## The Problem: AI Agents Are Fragile

AI coding agents operate in sessions with finite context windows. Any of these can happen at any moment:

- **Context fills up** — the agent loses track of what it was doing
- **Session crashes** — network issue, timeout, or runtime error
- **Agent gets confused** — loops on a failing test, goes down the wrong path
- **Machine restarts** — power loss, OS update, or manual restart

In a traditional single-agent setup, any of these means starting over. In a multi-agent system with 20+ concurrent workers, failures are not exceptions — they're the normal operating condition.

## The Solution: Forward-Only Progress

GUPP (Gas Town Universal Propulsion Principle) states:

> **Every operation must move the system forward or leave it unchanged. No operation should move backward.**

This means:

- **Completed work stays completed.** When a molecule step is marked `done`, it's permanently done. A fresh agent picking up the work skips it.
- **Partial progress is preserved.** If an agent crashes after completing 4 of 9 steps, the next agent starts at step 5.
- **State never goes backward.** Bead statuses progress `open → in_progress → done`. There is no `done → open` transition.

## How It Works: Three Primitives

```mermaid
flowchart LR
    subgraph GUPP["Forward-Only Progress"]
        direction LR
        A["open"] -->|claim| B["in_progress"]
        B -->|complete| C["done"]
    end
    style A fill:#f9f,stroke:#333
    style B fill:#ff9,stroke:#333
    style C fill:#9f9,stroke:#333
```

GUPP is enforced by three concrete mechanisms:

### 1. Hooks (Persistent Assignment)

A [hook](/docs/concepts/hooks) is a pointer from an agent to its current work. Hooks are stored on the filesystem, not in memory. When an agent crashes:

```text
Before crash:  hook → ga-a1b2c (bead assigned to polecat Toast)
After crash:   hook → ga-a1b2c (still there — filesystem survived)
New session:   hook → ga-a1b2c (fresh agent reads it and continues)
```

The hook is why "did the agent finish?" doesn't matter. What matters is: "is the work still on a hook?" If yes, someone will pick it up.

### 2. Molecules (Step-Level Checkpoints)

A [molecule](/docs/concepts/molecules) tracks multi-step workflows as a sequence of individual steps. Each step's completion is persisted to the beads database:

```text
Before crash:
  load-context      [done]
  branch-setup      [done]
  implement         [in_progress]  ← agent was here
  run-tests         [pending]

After restart:
  load-context      [done]        ← skipped
  branch-setup      [done]        ← skipped
  implement         [in_progress] ← resume here
  run-tests         [pending]
```

The fresh agent doesn't redo steps 1-2. It reads the molecule state and picks up from step 3.

### 3. Beads (Forward-Only Status)

[Beads](/docs/concepts/beads) enforce forward-only state progression. There is no API to move a bead from `done` back to `open`. If completed work needs revision, you create a new bead — you don't reopen the old one.

This prevents a class of bugs where agents fight over state: Agent A closes a bead, Agent B reopens it, Agent A closes it again, and so on.

```mermaid
sequenceDiagram
    participant P1 as Polecat (crashes)
    participant H as Hook + Molecule
    participant P2 as Fresh Polecat
    P1->>H: Steps 1-2 done, step 3 in_progress
    Note over P1: CRASH
    P2->>H: Reads hook state
    Note over P2: Skips steps 1-2, resumes step 3
    P2->>H: Steps 3-4 done
```

## NDI: The Practical Companion

GUPP has a companion principle: **Nondeterministic Idempotence (NDI)**. It acknowledges that AI agents are nondeterministic — ask Claude to implement the same feature twice and you'll get different code.

NDI says: **that's fine.** What matters is the end state (tests pass, feature works), not the exact implementation. A fresh agent may solve the same step differently than the crashed agent would have, and that's acceptable.

```text
Crashed agent would have used:  Joi validation library
Fresh agent actually uses:      Zod validation library
Both produce:                   Valid input validation with passing tests ✓
```

## GUPP in Practice: A Recovery Walkthrough

Let's trace a real failure-recovery sequence to see GUPP in action:

```text
10:00  Polecat "toast" starts working on ga-xyz (molecule step: implement)
10:15  Network issue kills the tmux session
10:15  Hook state on disk: ga-xyz still attached
10:15  Molecule state in DB: steps 1-3 done, step 4 in_progress
10:20  Witness patrol detects toast is dead (session gone)
10:20  Witness files warrant for toast, re-slings ga-xyz to the rig
10:21  New polecat "alpha" spawns, finds ga-xyz on hook
10:21  Alpha reads molecule: skips steps 1-3, resumes step 4
10:35  Alpha completes all steps, runs gt done
10:36  Refinery merges to main
```

No human involvement. No lost work. The 15-minute gap was the only cost — and that's just the Witness patrol interval. The key moments are at 10:15 (hook and molecule state survive the crash) and 10:21 (fresh agent skips completed steps).

## What This Means For You

As a Gas Town user, GUPP means:

- **Don't worry about crashes.** They're handled automatically.
- **Don't manually restart failed work.** The Witness detects zombies and the system re-slings the work.
- **Don't babysit polecats.** The supervision tree (Witness → Deacon → Mayor) handles recovery at every level.
- **Trust the hook.** If work is on a hook, it will get done — eventually.

:::note GUPP applies to you too
GUPP isn't just for polecats. When you're a crew worker and your session crashes, your hook still has your molecule attached. Run `gt prime` in your next session and you'll pick up right where you left off. The principle is universal across all Gas Town agent types.
:::

## Further Reading

- **[GUPP & NDI](/docs/concepts/gupp)** — Full technical reference
- **[Design Principles](/docs/architecture/design-principles)** — All twelve principles including GUPP
- **[Agent Hierarchy](/docs/architecture/agent-hierarchy)** — The supervision tree that enforces recovery
- **[Hooks](/docs/concepts/hooks)** — The persistence primitive that makes GUPP possible
- **[Hooks: The Persistence Primitive](/blog/hook-persistence)** — How hooks implement GUPP's crash-safety guarantee
- **[Session Cycling Explained](/blog/session-cycling)** — How GUPP applies to context refresh and handoffs
- **[Common Pitfalls](/blog/common-pitfalls)** — Mistakes that happen when teams skip GUPP principles
- [Sessions CLI Reference](/docs/cli-reference/sessions) — Commands for session lifecycle and molecule management
