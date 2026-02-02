---
title: "Quick Start"
sidebar_position: 2
description: "The Town is your top-level workspace directory. All projects (rigs) live inside it."
---

# Quick Start

## Create Your Workspace

The **Town** is your top-level workspace directory. All projects (rigs) live inside it.

```bash
gt install ~/gt --git
cd ~/gt
```

This creates:

```
~/gt/
├── .beads/          # Town-level issue tracking
├── .claude/         # Claude Code integration
├── mayor/           # Mayor agent context
│   └── town.json    # Town metadata
├── deacon/          # Deacon agent context
├── settings/        # Configuration files
├── scripts/         # Utility scripts
├── plugins/         # Town-level plugins
└── CLAUDE.md        # Project context
```

## Add a Project (Rig)

Each project you manage with Gas Town is called a **Rig**.

```bash
gt rig add myproject https://github.com/you/repo.git
```

This creates the rig structure:

```
~/gt/myproject/
├── .beads/          # Rig-level issue tracking
├── config.json      # Rig configuration
├── refinery/rig/    # Canonical clone (merge queue)
├── mayor/rig/       # Mayor's working copy
├── crew/            # Human developer workspaces
├── witness/         # Health monitor
├── polecats/        # Worker directories
└── plugins/         # Rig-level plugins
```

## Create a Crew Workspace

Crew workspaces are persistent clones for human developers.

```bash
gt crew add myproject yourname
```

Enter your workspace:

```bash
cd ~/gt/myproject/crew/yourname
```

## Start Gas Town

Start the core agents:

```bash
# Start Mayor + Deacon
gt start

# Or start everything including Witnesses and Refineries
gt start --all
```

## Attach to the Mayor

The Mayor is your primary interface for coordinating work.

```bash
gt mayor attach
```

Now you can give natural language instructions. For example:

> "Fix the 5 failing tests in the auth module and add input validation to the user registration endpoint."

The Mayor will:

1. Create beads (issues) for each task
2. Bundle them into a convoy
3. Spawn polecats to work on each task
4. Monitor progress
5. Route completed work through the refinery for merging

## Check Status

```bash
# List all rigs
gt rig list

# Check convoy progress
gt convoy list

# View activity feed
gt feed

# Check what's ready for work
gt ready
```

## Next Steps

- [Your First Convoy](first-convoy.md) — Detailed walkthrough of the convoy workflow
- [CLI Reference](../cli-reference/index.md) — Full command documentation
- [Architecture](../architecture/index.md) — Understand the system design
