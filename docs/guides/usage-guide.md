---
title: "Usage Guide"
sidebar_position: 1
description: "This guide covers practical day-to-day Gas Town usage patterns -- from working with the Mayor, to managing multiple rigs, to the mandatory session completion..."
---

# Usage Guide

This guide covers practical day-to-day Gas Town usage patterns -- from working with the Mayor, to managing multiple rigs, to the mandatory session completion workflow. It assumes you have a working installation (see [Getting Started](../getting-started/index.md)) and are familiar with the basic concepts.

---

## Working with the Mayor

The Mayor is your primary interface for multi-agent coordination. You talk to the Mayor in natural language, and it handles issue creation, work assignment, convoy management, and progress tracking.

### Starting a Session

```bash
gt mayor attach
```

This attaches your terminal to the Mayor's tmux session. You can now interact with it directly.

### Giving Instructions

Be specific and action-oriented:

```
Good:  "Fix the 5 failing tests in the auth module and add input
        validation to the user registration endpoint."

Bad:   "Make the code better."
```

The Mayor will:

1. Break your request into discrete beads (issues)
2. Create a convoy to track the batch
3. Assign work to polecats across appropriate rigs
4. Monitor progress and handle escalations
5. Report back when the convoy completes

### Checking on Progress

You can ask the Mayor directly:

```
"What's the status of the auth fixes?"
"How many polecats are running right now?"
"Are there any blocked items?"
```

Or use CLI commands from any terminal:

```bash
gt convoy list
gt feed
gt trail --since 30m
```

### Detaching from the Mayor

Press `Ctrl+B` then `D` to detach from the tmux session (the Mayor continues running in the background).

---

## Managing Multiple Rigs

A common Gas Town setup involves 2-5 rigs (projects) running simultaneously.

### Listing Rigs

```bash
gt rig list
```

Sample output:

```
Rigs (3):
  myapp        active   3 polecats   witness: up   refinery: up
  api-server   active   1 polecat    witness: up   refinery: up
  docs         parked   -            witness: -    refinery: -
```

### Working Across Rigs

```bash
# Sling work to a specific rig
gt sling gt-a1b2c myapp
gt sling gt-d3e4f api-server

# Check a specific rig's status
gt rig status myapp

# View a rig's merge queue
gt mq list --rig api-server
```

### Rig-Specific Operations

```bash
# Start agents for one rig
gt rig start api-server

# Park a rig you're not currently using
gt rig park docs

# Bring it back later
gt rig unpark docs
gt rig start docs
```

:::tip[Focus Mode]

Park rigs you are not actively working on. This reduces resource consumption and keeps the feed cleaner.

:::

---

## Session Management and Handoffs

Gas Town agents are designed for long-running sessions with context preservation.

### Context Recovery

When an agent loses context (after compaction, crash, or long idle):

```bash
gt prime
```

This reloads the agent's full context from its CLAUDE.md file, hooks, and beads state. All persistent agents run `gt prime` automatically on startup.

### Handoffs Between Sessions

When transitioning from one work session to another (e.g., end of day):

```bash
# From within an agent session
gt handoff
```

This:

1. Summarizes current state
2. Writes handoff notes to the agent's context
3. Ensures hooks are up to date
4. The next session picks up the handoff notes automatically

### Agent Session Restart

```bash
# Restart with context preservation
gt mayor restart

# Restart completely fresh (re-reads all context)
gt mayor restart --fresh
```

---

## Day-to-Day Usage Patterns

### Morning Startup

```bash
# 1. Start the fleet
gt start --all

# 2. Check overnight activity
gt trail --since 12h

# 3. Review escalations
gt escalate list

# 4. Check convoy progress
gt convoy list

# 5. Attach to Mayor and give today's instructions
gt mayor attach
```

### During Active Development

```bash
# Watch the live feed (keep this in a dedicated terminal)
gt feed

# Periodically check costs
gt costs --today

# If something looks wrong
gt doctor

# Quick status check
gt rig list
```

### End of Day

```bash
# 1. Check what's still running
gt polecat list

# 2. Review convoy status
gt convoy list

# 3. Option A: Leave it running overnight
#    (check gt costs first to estimate overnight spend)

# 4. Option B: Pause until morning
gt down
```

---

## Landing the Plane (Session Completion)

Landing the plane is the **mandatory** workflow for completing a Gas Town session. Skipping any step risks losing work, leaving stale state, or creating confusion for the next session.

:::danger[Mandatory Workflow]

Every Gas Town session must end with a proper landing. Incomplete landings lead to orphaned work, missed pushes, and broken state.

:::

### The 7-Step Landing Checklist

#### Step 1: File Issues for Remaining Work

Any incomplete work or follow-up items must be tracked:

```bash
# Create beads for remaining work
bd create --title "TODO: finish API pagination" --type task --priority medium
bd create --title "TODO: add tests for edge case X" --type task
```

Do not leave work undocumented. If it is not in a bead, it will be forgotten.

#### Step 2: Run Quality Gates

Ensure all code passes quality checks before pushing:

```bash
# Run tests
cd ~/gt/myproject/refinery/rig
npm test          # or: go test ./...  or: pytest

# Run linting
npm run lint      # or your project's lint command

# Check for build errors
npm run build
```

#### Step 3: Update Issue Status

Close completed beads and update in-progress ones:

```bash
# Close completed beads
bd close gt-a1b2c --note "Implemented and merged"
bd close gt-d3e4f

# Update in-progress beads
bd update gt-g5h6i --status deferred --note "Waiting for API spec"
```

#### Step 4: Push to Remote (MANDATORY)

This is the most critical step. **All changes must be pushed to the remote repository.**

```bash
# Pull latest and rebase
git pull --rebase

# Sync beads
bd sync

# Push everything
git push
```

:::danger[Always Push]

Work that is committed locally but not pushed is effectively invisible to other developers and agents. A machine crash or cleanup will lose it. **Always push.**

:::

#### Step 5: Clean Up

```bash
# Clean up stale resources
gt cleanup

# Stop polecats that have finished
gt shutdown --polecats-only
```

#### Step 6: Verify All Changes Committed and Pushed

Double-check that nothing was missed:

```bash
# Check for uncommitted changes
git status

# Verify remote is up to date
git log --oneline origin/main..HEAD
# Should show nothing (all commits pushed)
```

#### Step 7: Hand Off with Context

Write handoff notes for the next session:

```bash
gt handoff
```

Or if you are the human operator, leave a note in the Mayor's mail:

```bash
gt mail send mayor "End of day: all auth work landed. Remaining: API pagination (gt-g5h6i) deferred until spec is ready. Tests all green."
```

### Landing Checklist Summary

| Step | Command | Purpose |
|------|---------|---------|
| 1 | `bd create` | File remaining work |
| 2 | `npm test` / `go test` | Run quality gates |
| 3 | `bd close` / `bd update` | Update issue status |
| 4 | `git pull --rebase && bd sync && git push` | **Push to remote** |
| 5 | `gt cleanup` | Clean up resources |
| 6 | `git status` + `git log` | Verify everything pushed |
| 7 | `gt handoff` | Hand off with context |

---

## Quick Reference Commands

### Lifecycle

| Command | Description |
|---------|-------------|
| `gt start` | Start Mayor + Deacon |
| `gt start --all` | Start full fleet |
| `gt down` | Pause (keep state) |
| `gt shutdown` | Stop + cleanup |
| `gt shutdown --all` | Full stop including crew |

### Work Management

| Command | Description |
|---------|-------------|
| `gt sling <bead> <rig>` | Assign work to a rig |
| `gt hook` | Check current hook |
| `gt done` | Mark work complete, submit MR |
| `gt release <bead>` | Release a stuck bead |
| `gt convoy list` | List active convoys |
| `gt convoy stranded` | Find convoys with unassigned work |

### Monitoring

| Command | Description |
|---------|-------------|
| `gt feed` | Live activity stream |
| `gt trail` | Recent activity summary |
| `gt peek <agent>` | View agent output |
| `gt doctor` | Health check |
| `gt costs` | Token usage |
| `gt rig list` | Rig status overview |

### Communication

| Command | Description |
|---------|-------------|
| `gt mail inbox` | Check your inbox |
| `gt mail send <to> <msg>` | Send a message |
| `gt nudge <agent> <msg>` | Send sync message |
| `gt escalate <msg>` | Create escalation |
| `gt broadcast <msg>` | Message all agents |

### Beads (Issue Tracking)

| Command | Description |
|---------|-------------|
| `bd create` | Create a new issue |
| `bd list` | List issues |
| `bd show <id>` | Show issue details |
| `bd close <id>` | Close an issue |
| `bd sync` | Sync beads with git |

### Session

| Command | Description |
|---------|-------------|
| `gt prime` | Reload agent context |
| `gt handoff` | Write handoff notes |
| `gt mayor attach` | Attach to Mayor |
| `gt polecat attach <name>` | Attach to a polecat |
