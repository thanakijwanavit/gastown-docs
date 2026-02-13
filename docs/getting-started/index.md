---
title: "Getting Started"
sidebar_position: 0
description: "This section covers everything you need to go from zero to running Gas Town with your first project."
---

# Getting Started

This section covers everything you need to go from zero to running Gas Town with your first project.

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

## The 30-Second Version

```bash
brew install gastown          # Install
gt install ~/gt --git         # Create workspace
cd ~/gt
gt rig add myapp git@github.com:you/app.git   # Add project
gt mayor attach               # Start the Mayor
# Tell the Mayor what to build
```
