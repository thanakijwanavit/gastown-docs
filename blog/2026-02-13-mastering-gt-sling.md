---
title: "Mastering gt sling: Work Assignment Patterns in Gas Town"
description: "A practical guide to gt sling — the core command for assigning work to agents, from basic usage to cross-rig patterns."
slug: mastering-gt-sling
authors: [gastown]
tags: [cli, operations, workflow, agents]
---

`gt sling` is the single most important operational command in Gas Town. Every piece of work — from a bug fix to a multi-rig infrastructure migration — gets to an agent through slinging. Understanding its patterns, flags, and failure modes is the difference between a smooth fleet and a confused pile of idle polecats.

<!-- truncate -->

## What Slinging Actually Does

When you run `gt sling <bead-id> <target>`, three things happen in sequence:

1. **Target resolution** — Gas Town figures out which agent or rig you mean
2. **Hook attachment** — The bead is attached to the target agent's hook
3. **Propulsion** — If the agent is running, it picks up the work immediately via [GUPP](/docs/concepts/gupp)

The hook is the key. It's a persistent pointer stored in the agent's worktree, surviving crashes and session restarts. When a slung bead lands on an agent's hook, it stays there until the work is done.

```mermaid
sequenceDiagram
    participant H as Human/Mayor
    participant S as gt sling
    participant T as Target Agent
    participant W as Work (Bead)

    H->>S: gt sling gt-abc myproject
    S->>S: Resolve target → myproject/polecats/toast
    S->>T: Attach gt-abc to hook
    S->>T: Nudge agent (if running)
    T->>W: Agent reads hook → begins work
    W->>T: Work completes → gt done
```

## Basic Patterns

### Sling to a Rig (Auto-Spawn)

The simplest pattern. Gas Town spawns a fresh polecat automatically:

```bash
gt sling gt-abc12 myproject
```

The Witness for `myproject` will spawn a polecat, attach the bead to its hook, and the polecat starts working immediately. You don't need to know the polecat's name in advance.

### Sling to a Specific Agent

When you want a particular agent to handle the work:

```bash
gt sling gt-abc12 myproject/polecats/toast
```

This is useful when:
- You know `toast` has relevant context from previous work
- You're re-assigning work after a failed attempt
- You want to stack sequential tasks on one agent

### Sling with Instructions

Add context beyond what's in the bead itself:

```bash
gt sling gt-abc12 myproject --args "Focus on the SQL injection vector. Ignore the XSS findings for now."
```

The `--args` text is injected into the agent's context alongside the bead description. Use this for nuance that doesn't belong in the bead itself.

### Sling a Formula

Formulas are TOML templates for structured workflows. Slinging a formula cooks it into a live [molecule](/docs/concepts/molecules):

```bash
gt sling mol-release mayor/ --on shiny
```

This creates a molecule from the `shiny` formula and attaches it to the Mayor. The Mayor then works through each step of the formula.

## Cross-Rig Slinging

Work often needs to land in a different rig than where you're operating. Gas Town handles this seamlessly:

```bash
# Sling from anywhere to the backend rig
gt sling gt-abc12 backend

# Sling to a crew member in another rig
gt sling gt-abc12 frontend/crew/alice
```

The sling command resolves the target rig, finds (or spawns) an appropriate agent, and attaches the work. Cross-rig slinging is the backbone of [convoy workflows](/docs/workflows/manual-convoy) where related work spans multiple projects.

## Batch Slinging

For convoys with multiple beads, sling them all at once:

```bash
# Create the convoy first
gt convoy create "API Security Hardening" gt-a1 gt-b2 gt-c3

# Sling each bead to appropriate rigs
gt sling gt-a1 backend
gt sling gt-b2 frontend
gt sling gt-c3 api-gateway
```

Each bead lands on a separate polecat. The Witnesses monitor all three in parallel, and the convoy tracks overall completion.

## Dry Run

Not sure what will happen? Preview first:

```bash
gt sling gt-abc12 myproject --dry-run
```

This resolves the target, checks for conflicts, and reports what *would* happen without actually doing anything. Use this liberally when learning.

## Common Failure Modes

### "Target not found"

The target rig or agent doesn't exist or isn't active:

```bash
gt rig list              # Verify the rig exists
gt rig status myproject  # Check if it's parked or docked
```

Parked rigs don't accept slung work. Unpark first: `gt rig unpark myproject`.

### "Hook occupied"

The target agent already has work on its hook:

```bash
gt hook --agent myproject/polecats/toast  # See what's hooked
```

Options:
- Wait for the current work to finish
- Use `--force` to override (be careful — this displaces the current work)
- Sling to the rig instead and let a fresh polecat pick it up

### "Bead not found"

The bead ID doesn't resolve. Check the bead exists and isn't already closed:

```bash
bd show gt-abc12        # Verify the bead
bd list --status=open   # Check open beads
```

## Anti-Patterns

**Don't sling to busy agents.** If an agent is mid-task, slinging more work forces a context switch. Sling to the rig and let a fresh polecat handle it.

**Don't sling without a bead.** Every piece of work should be tracked. Create the bead first, then sling it. This ensures the audit trail is complete.

**Don't over-specify the target.** Unless you have a reason to target a specific polecat, sling to the rig. Let the [Witness](/docs/agents/witness) handle agent selection and spawning.

## Next Steps

- [Work Distribution Architecture](/docs/architecture/work-distribution) — How work flows through Gas Town end-to-end
- [Manual Convoy Workflow](/docs/workflows/manual-convoy) — Step-by-step convoy creation and slinging
- [Formula Workflow](/docs/workflows/formula-workflow) — Structured workflows using TOML templates
- [Understanding GUPP](/blog/understanding-gupp) — Why the propulsion principle makes slinging work
- [Hooks: The Persistence Primitive](/blog/hook-persistence) — How hooks make slung work crash-safe
