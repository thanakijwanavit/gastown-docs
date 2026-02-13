---
title: "Getting Started"
sidebar_position: 0
description: "This section covers everything you need to go from zero to running Gas Town with your first project."
---

# Getting Started

This section covers everything you need to go from zero to running Gas Town with your first project.

## What is Gas Town?

Gas Town is a **multi-agent workspace manager** that coordinates AI coding agents working on your projects. Instead of one agent in one terminal, Gas Town runs many agents in parallel — each with its own git worktree, issue tracker, and session — while a hierarchy of supervisors keeps everything on track.

**Core components:**

| Component | Role |
|-----------|------|
| **Mayor** | Global coordinator that decomposes high-level goals into actionable work |
| **Polecats** | Ephemeral workers spawned for individual tasks, nuked when done |
| **Refinery** | Per-rig merge queue that serializes all merges to main |
| **Witness** | Monitors polecat health and recovers stuck workers |
| **Deacon** | Infrastructure orchestrator running periodic health checks |
| **Crew** | Persistent human-managed workspaces for direct interaction |

**How it works:** You describe what you want built. The Mayor breaks it into issues, bundles them into convoys, and slings work to polecats. Each polecat works independently in its own sandbox, then submits completed work to the Refinery for merge. The Witness watches for failures. You watch the progress.

## Prerequisites

Before installing Gas Town, ensure you have:

- **Go 1.23+** — Gas Town is written in Go
- **Git 2.25+** — Worktree support required
- **Beads (bd) 0.44.0+** — Issue tracking CLI
- **SQLite3** — Backend for Beads
- **Tmux 3.0+** — Recommended for multi-agent session management
- **Claude Code CLI** — Or a compatible AI coding agent runtime

## What You'll Learn

1. [Installation](installation.md) — Install Gas Town and its dependencies
2. [Quick Start](quickstart.md) — Set up your workspace and add your first project
3. [Your First Convoy](first-convoy.md) — Assign work and watch agents deliver
4. [Using Search](using-search.md) — Find what you need in the documentation
5. [Cheat Sheet](cheat-sheet.md) — One-page command quick reference
6. [FAQ](faq.md) — Answers to the most common questions

## The 30-Second Version

```bash
brew install gastown          # Install
gt install ~/gt --git         # Create workspace
cd ~/gt
gt rig add myapp git@github.com:you/app.git   # Add project
gt mayor attach               # Start the Mayor
# Tell the Mayor what to build
```

## From the Blog

- [Your First Convoy in 5 Minutes](/blog/first-convoy) -- Step-by-step walkthrough of creating and running your first convoy
- [5 Common Pitfalls When Starting](/blog/common-pitfalls) -- Avoid these mistakes when setting up Gas Town
- [Understanding GUPP](/blog/understanding-gupp) -- Why agents never lose work, even when they crash

## Next Steps

Once you're up and running, explore these areas:

- [Cheat Sheet](cheat-sheet.md) — Quick reference for the commands you'll use most
- [FAQ](faq.md) — Answers to common questions about setup, agents, and costs
- [Architecture Overview](../architecture/overview.md) — Understand how all the pieces fit together
- [Usage Guide](../guides/usage-guide.md) — Day-to-day patterns for working with Gas Town
- [CLI Reference](../cli-reference/index.md) — Complete command reference
