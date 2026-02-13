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

## NDI: The Practical Companion

GUPP has a companion principle: **Nondeterministic Idempotence (NDI)**. It acknowledges that AI agents are nondeterministic — ask Claude to implement the same feature twice and you'll get different code.

NDI says: **that's fine.** What matters is the end state (tests pass, feature works), not the exact implementation. A fresh agent may solve the same step differently than the crashed agent would have, and that's acceptable.

```text
Crashed agent would have used:  Joi validation library
Fresh agent actually uses:      Zod validation library
Both produce:                   Valid input validation with passing tests ✓
```

## What This Means For You

As a Gas Town user, GUPP means:

- **Don't worry about crashes.** They're handled automatically.
- **Don't manually restart failed work.** The Witness detects zombies and the system re-slings the work.
- **Don't babysit polecats.** The supervision tree (Witness → Deacon → Mayor) handles recovery at every level.
- **Trust the hook.** If work is on a hook, it will get done — eventually.

## Further Reading

- **[GUPP & NDI](/docs/concepts/gupp)** — Full technical reference
- **[Design Principles](/docs/architecture/design-principles)** — All twelve principles including GUPP
- **[Agent Hierarchy](/docs/architecture/agent-hierarchy)** — The supervision tree that enforces recovery
- **[Hooks](/docs/concepts/hooks)** — The persistence primitive that makes GUPP possible
- **[Hooks: The Persistence Primitive](/blog/hook-persistence)** — How hooks implement GUPP's crash-safety guarantee
- **[Session Cycling Explained](/blog/session-cycling)** — How GUPP applies to context refresh and handoffs
