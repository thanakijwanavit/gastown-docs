---
title: "Troubleshooting"
sidebar_position: 4
description: "This guide covers common Gas Town problems, their diagnosis, and resolution. Start with gt doctor for automated diagnostics, then consult the specific sectio..."
---

# Troubleshooting

This guide covers common Gas Town problems, their diagnosis, and resolution. Start with `gt doctor` for automated diagnostics, then consult the specific sections below for detailed troubleshooting steps.

---

## First Steps

Before diving into specific issues, always run these commands:

```bash
# Automated health check
gt doctor

# Check what's running
gt rig list

# Check recent activity for clues
gt trail --since 1h

# Check for open escalations
gt escalate list
```

---

## Agent Loses Connection

**Symptom:** An agent session is running but not responding to mail or nudges. The agent appears to be stuck in an inactive state.

**Diagnosis:**

```bash
# Check if the session is alive
gt peek <agent>

# Check the agent's hook state
gt hook --agent <agent>

# Check convoy status for the agent's work
gt convoy list
```

**Solutions:**

1. **Verify hooks are intact.** If the agent's hook was corrupted, the agent may not know what to do.

    ```bash
    # Check hooks for the agent
    gt hook --agent witness --rig myproject

    # If hooks look wrong, re-prime the agent
    gt prime --agent witness --rig myproject
    ```

2. **Check convoy status.** If the convoy tracking a piece of work is in a bad state, the agent may be waiting on something that will never arrive.

    ```bash
    gt convoy list
    gt convoy show <convoy-id>
    ```

3. **Restart the agent.** If hooks and state look correct, a session restart often resolves transient issues.

    ```bash
    gt witness restart --rig myproject
    # Or for a fresh start:
    gt witness restart --rig myproject --fresh
    ```

:::tip

After restarting an agent, it automatically runs `gt prime` to reload context. All hook-attached work persists -- the agent will resume where it left off.

:::

---

## Convoy Stuck

**Symptom:** A convoy shows `ACTIVE` but no progress is being made. Issues within the convoy are not advancing.

**Diagnosis:**

```bash
# Check convoy details
gt convoy show <convoy-id>

# Check bead states for the convoy's issues
bd list --convoy <convoy-id>

# Check for stranded convoys
gt convoy stranded
```

**Solutions:**

1. **Review bead states.** Look for beads stuck in `hooked` or `in_progress` that are not being worked on.

    ```bash
    # List beads with their states
    bd list --status in_progress
    bd list --status hooked
    ```

2. **Manually advance stuck beads.** If a bead is hooked but no polecat is running it:

    ```bash
    # Release the bead back to pending
    gt release gt-a1b2c

    # Re-sling to a rig
    gt sling gt-a1b2c myproject
    ```

3. **Check for blocked dependencies.** If beads have dependency links, one stuck bead can block the entire chain.

    ```bash
    bd show gt-a1b2c
    # Look for "blocked_by" or "depends_on" fields
    ```

4. **Check the merge queue.** Completed work may be stuck in the refinery.

    ```bash
    gt mq list --rig myproject
    gt mq status --rig myproject
    ```

---

## Mayor Not Responding

**Symptom:** The Mayor session is alive but not processing mail or giving instructions.

**Diagnosis:**

```bash
# Check if the session is active
gt peek mayor

# Check the Mayor's mailbox
gt mail inbox --agent mayor

# Check for recent Mayor activity
gt audit mayor --since 1h
```

**Solutions:**

1. **Context recovery with `gt prime`.** The Mayor may have lost context after compaction or a long idle period.

    ```bash
    gt mayor attach
    # Then inside the session:
    # Run gt prime
    ```

    Or from outside:

    ```bash
    gt nudge mayor "Run gt prime to recover context"
    ```

2. **Restart the Mayor.** If priming does not help:

    ```bash
    gt mayor restart
    ```

3. **Check for a blocking escalation.** The Mayor may be waiting for human input on a critical escalation.

    ```bash
    gt escalate list --severity critical
    gt escalate list --severity high
    ```

:::warning

If the Mayor is unresponsive and you have urgent work, you can bypass it by directly slinging work to rigs: `gt sling gt-a1b2c myproject`. The Mayor is not required for individual task assignment.

:::

---

## Stale Polecats

**Symptom:** Polecats that have been running for an unusually long time without producing output or completing their work.

**Diagnosis:**

```bash
# List stale polecats
gt polecat stale

# Check individual polecat status
gt polecat list --rig myproject
gt peek polecat:toast --rig myproject
```

**Solutions:**

1. **Let the Witness handle it.** The Witness detects stale polecats during its patrol cycle and will nudge them first, then escalate if they remain stuck.

    ```bash
    # Check if the Witness has already acted
    gt trail --agent witness --rig myproject
    ```

2. **Manually nudge the polecat.**

    ```bash
    gt nudge polecat:toast --rig myproject "Check your progress - you appear to be stalled"
    ```

3. **Terminate and respawn.** If the polecat is truly stuck:

    ```bash
    # Stop the polecat
    gt polecat stop toast --rig myproject

    # Release its work
    gt release gt-a1b2c

    # Re-sling to spawn a fresh polecat
    gt sling gt-a1b2c myproject
    ```

---

## Orphaned Processes

**Symptom:** Resources consuming disk or compute that are not connected to any active agent or convoy.

### Orphaned Worktrees

```bash
# Find orphaned worktrees
gt orphans

# Clean them up
gt cleanup
```

`gt orphans` finds:

- Polecat directories with no running session
- Worktrees not attached to any active bead
- Stale temporary directories from crashed agents

### Zombie Claude Processes

```bash
# Scan for zombie Claude processes
gt deacon zombie-scan

# Or manually check
ps aux | grep claude | grep -v grep
```

If zombie processes are found:

```bash
# Let the Deacon clean them up
gt deacon zombie-scan --cleanup

# Or manually kill specific processes
kill <PID>
```

### Orphaned Commits

```bash
# Find unreachable commits (lost work from crashed polecats)
gt orphans --commits

# Recover work from an orphaned commit
gt orphans --recover <commit-hash>
```

:::tip[Lost Work Recovery]

`gt orphans --commits` uses `git fsck` under the hood to find unreachable commits. If a polecat crashed before pushing, its work may still be recoverable from the local git object store.

:::

---

## Merge Conflicts

**Symptom:** The Refinery reports merge conflicts that prevent code from landing on main.

**Diagnosis:**

```bash
# Check merge queue status
gt mq list --rig myproject
gt mq status --rig myproject

# Check for conflict details
gt mq show <mr-id>
```

**Solutions:**

1. **Let the Refinery handle it.** The Refinery's default behavior on conflict is to spawn a fresh polecat to resolve the conflict. This works for straightforward conflicts.

2. **Manual resolution.** For complex conflicts that polecats cannot resolve:

    ```bash
    # Attach to the Refinery
    gt refinery attach --rig myproject

    # Or work from a crew workspace
    cd ~/gt/myproject/crew/yourname
    git fetch origin
    git merge origin/main
    # Resolve conflicts manually
    git push
    ```

3. **Skip and retry.** If one MR is blocking the queue:

    ```bash
    # Skip the problematic MR
    gt mq skip <mr-id>

    # The bead goes back to pending for reassignment
    gt sling gt-a1b2c myproject
    ```

:::note

The Refinery always rebases onto the latest `main` before merging. Conflicts are most common when multiple polecats modify the same files. Consider assigning related work to a single polecat or serializing via convoy dependencies.

:::

---

## Daemon Issues

### Daemon Not Starting

```bash
# Check daemon status
gt daemon status

# Check for port conflicts
gt daemon start --verbose

# Check daemon logs
gt daemon logs --level error
```

### Heartbeat Failures

If the Deacon is not receiving heartbeats:

```bash
# Verify the daemon is running
gt daemon status

# Check for network issues between daemon and Deacon
gt daemon logs --follow

# Restart the daemon
gt daemon stop && gt daemon start
```

---

## Context Window Filling

**Symptom:** An agent becomes sluggish, loses track of its work, starts repeating itself, or produces incoherent output. Often preceded by the agent running for an extended period on a large task.

**Diagnosis:**

```bash
# Check how long the agent has been running
gt audit polecat:toast --rig myproject

# Look for signs of context pressure in agent output
gt peek polecat:toast --rig myproject --lines 50
```

**Solutions:**

1. **For polecats: use `gt handoff`.** The polecat should cycle itself to a fresh session with context notes before the window fills completely.

    ```bash
    # From inside the polecat session:
    gt handoff -s "Context filling, continuing work" -m "Issue: gt-a1b2c
    Progress: implemented X, Y remains
    Next step: finish Y and run tests"
    ```

2. **For persistent agents (Witness, Mayor, Deacon): trigger a context reset.**

    ```bash
    # Nudge the agent to prime
    gt nudge witness --rig myproject "Run gt prime to reset context"

    # Or restart with fresh context
    gt witness restart --rig myproject --fresh
    ```

3. **Prevent the issue.** Large tasks should be broken into smaller beads. If a polecat consistently fills context on a task type, the task decomposition needs improvement.

:::note

Persistent agents (Mayor, Deacon, Witness) experience automatic compaction but may lose nuance. If an agent seems confused after compaction, `gt prime` reloads the full role context.

:::

---

## Agent Boot Failures

**Symptom:** An agent fails to start, or starts but immediately exits or becomes unresponsive. The `gt start` command completes but `gt doctor` shows the agent is not running.

**Diagnosis:**

```bash
# Check if the session exists in tmux
gt peek <agent> --rig myproject

# Check daemon logs for startup errors
gt daemon logs --level error --since 10m

# Check if the tmux session was created
tmux list-sessions
```

**Solutions:**

1. **Missing dependencies.** The agent's Claude session may fail if required tools are not installed.

    ```bash
    gt doctor --check dependencies
    ```

2. **Stale tmux sessions.** A previous session may still hold the slot.

    ```bash
    # Kill stale tmux sessions
    tmux kill-session -t <session-name>

    # Restart the agent
    gt witness start --rig myproject
    ```

3. **Configuration errors.** Check rig configuration for invalid settings.

    ```bash
    # Validate rig config
    gt rig show myproject
    ```

4. **Disk space.** Claude sessions need space for logs and context.

    ```bash
    df -h ~/gt/
    # Clean up if needed
    gt cleanup
    ```

---

## Git Worktree Issues

**Symptom:** A polecat reports git errors, has a dirty working tree it did not expect, or cannot commit/push its changes.

**Diagnosis:**

```bash
# Check worktree state from outside
cd ~/gt/myproject/polecats/<name>/myproject
git status
git log --oneline -5
```

**Solutions:**

1. **Dirty working tree from a previous crash.** If a polecat crashed mid-work, its worktree may have uncommitted changes.

    ```bash
    # If the changes are salvageable, commit them
    cd ~/gt/myproject/polecats/<name>/myproject
    git add -A
    git commit -m "chore: recover work from crashed polecat session"
    git push

    # Then stop and respawn
    gt polecat stop <name> --rig myproject
    gt sling <bead-id> myproject
    ```

2. **Detached HEAD.** The worktree may have ended up in a detached HEAD state.

    ```bash
    # Check the current state
    git branch --show-current  # Empty output means detached HEAD

    # Recover by creating a branch from the current position
    git checkout -b recovery/<bead-id>
    git push origin recovery/<bead-id>
    ```

3. **Worktree pointing to deleted branch.** If the branch was cleaned up but the worktree remains:

    ```bash
    # Remove the broken worktree
    git worktree remove ~/gt/myproject/polecats/<name>/myproject --force

    # Let gt recreate it on next spawn
    gt sling <bead-id> myproject
    ```

---

## Beads Database Issues

**Symptom:** `bd` commands fail with lock errors, return unexpected results, or report corruption. Agents may be unable to create, update, or close beads.

**Diagnosis:**

```bash
# Run the beads doctor
bd doctor

# Check for lock files
ls -la ~/gt/myproject/.beads/*.lock 2>/dev/null
```

**Solutions:**

1. **Database locked.** Concurrent writes from multiple agents can cause locking. Usually resolves itself.

    ```bash
    # Wait a few seconds and retry
    bd list --status=open

    # If persistent, check for zombie bd processes
    ps aux | grep "bd " | grep -v grep

    # Kill zombies if found
    kill <PID>
    ```

2. **Database corruption.** Rare but possible after unclean shutdowns.

    ```bash
    # Run repair
    bd doctor --fix

    # If repair fails, the JSONL export is the backup
    # Check for the last good export
    ls -la ~/gt/myproject/.beads/*.jsonl
    ```

3. **Sync issues between agents.** If agents have divergent views of bead state:

    ```bash
    # Force a flush to JSONL
    bd sync --flush-only

    # Each agent should re-read on next bd command
    ```

---

## Polecat Self-Clean Failures

**Symptom:** A polecat runs `gt done` but the command fails. The polecat may be left in a limbo state -- finished with work but not properly cleaned up.

**Diagnosis:**

```bash
# Check if the polecat's work was pushed
cd ~/gt/myproject/polecats/<name>/myproject
git status
git log --oneline origin/main..HEAD
```

**Solutions:**

1. **Uncommitted changes.** `gt done` requires a clean git state.

    ```bash
    # Commit remaining changes
    git add <files>
    git commit -m "fix: remaining changes before gt done"
    git push

    # Retry
    gt done
    ```

2. **Push failures.** Network issues or remote conflicts can prevent push.

    ```bash
    # Check remote connectivity
    git remote -v
    git fetch origin

    # If behind remote, rebase
    git rebase origin/main
    git push

    gt done
    ```

3. **If `gt done` keeps failing:** Escalate to the Witness with context about what failed.

    ```bash
    gt mail send myproject/witness -s "HELP: gt done failing" -m "Polecat: <name>
    Issue: <bead-id>
    Error: <error message>
    Git state: <clean/dirty>
    Branch pushed: <yes/no>"
    ```

---

## Mail Delivery Problems

**Symptom:** Messages sent via `gt mail send` are not appearing in the recipient's inbox, or agents are not responding to mail they should have received.

**Diagnosis:**

```bash
# Check outbox
gt mail sent

# Check the recipient's inbox directly
gt mail inbox --agent <recipient>

# Verify the mail address format
gt mail send <rig>/<agent> -s "test" -m "ping"
```

**Solutions:**

1. **Wrong address format.** Mail addresses follow the pattern `<rig>/<agent>` or `mayor/` for town-level agents.

2. **Agent not checking mail.** Persistent agents check mail during patrol cycles. If an agent is stuck, it may not be polling.

    ```bash
    # Nudge the agent to check mail
    gt nudge <agent> --rig myproject "Check your inbox"
    ```

3. **Mail queue corruption.** Rare, but can happen after crashes.

    ```bash
    # Check mail queue health
    gt doctor --check agents
    ```

---

## Common Error Messages

| Error | Cause | Fix |
|-------|-------|-----|
| `no rig found` | Command run outside a rig context | Use `--rig <name>` or `cd` into a rig directory |
| `agent session not found` | Agent is not running | Start the agent: `gt <agent> start` |
| `hook already attached` | Bead is already hooked to another agent | Release first: `gt release <bead-id>` |
| `merge queue full` | Refinery is backed up | Check `gt mq list`, clear stuck MRs |
| `daemon not running` | Daemon process has stopped | Run `gt daemon start` |
| `beads database locked` | Concurrent write conflict | Wait and retry; check for zombie `bd` processes |
| `worktree already exists` | Stale worktree from previous run | Clean up: `gt cleanup` |
| `convoy not found` | Invalid convoy ID or convoy was auto-cleaned | Check `gt convoy list --all` for closed convoys |
| `context window exceeded` | Agent session ran too long | Use `gt handoff` to cycle to a fresh session |
| `git push rejected` | Remote has diverged from local | Run `git fetch && git rebase origin/main`, then push |
| `molecule step not found` | Bead ID typo or step was already closed | Check `bd show <molecule-id>` for step list |
| `permission denied` | File or directory owned by another agent | Check `ls -la` ownership; may need `gt cleanup` |

---

## Diagnostic Commands Summary

| Command | Purpose |
|---------|---------|
| `gt doctor` | Comprehensive health check |
| `gt doctor --fix` | Auto-repair known issues |
| `gt orphans` | Find disconnected resources |
| `gt cleanup` | Remove stale resources |
| `gt polecat stale` | List stuck polecats |
| `gt deacon zombie-scan` | Find zombie Claude processes |
| `gt escalate stale` | Find unacknowledged escalations |
| `gt convoy stranded` | Find convoys with unassigned work |
| `gt mq status` | Check merge queue health |
| `gt daemon status` | Verify daemon is running |
| `gt trail --since 1h` | Recent activity for diagnosis |
| `gt peek <agent>` | View agent session output |
| `bd doctor` | Check beads database health |
| `bd doctor --fix` | Attempt beads database repair |

---

## Decision Tree: Which Section to Read

Use this to quickly find the right troubleshooting section:

```
Is anything running at all?
├── No → Daemon Issues / Agent Boot Failures
└── Yes
    ├── Is a specific agent unresponsive?
    │   ├── Mayor → Mayor Not Responding
    │   ├── Polecat → Stale Polecats
    │   └── Witness/Refinery → Agent Loses Connection
    ├── Is work not progressing?
    │   ├── Convoy shows ACTIVE → Convoy Stuck
    │   ├── Merge queue backed up → Merge Conflicts
    │   └── Polecat can't finish → Polecat Self-Clean Failures
    ├── Are bd commands failing?
    │   └── Beads Database Issues
    ├── Is an agent confused or repeating itself?
    │   └── Context Window Filling
    └── Are there leftover resources?
        └── Orphaned Processes
```

---

## When to Reboot

If multiple systems are failing simultaneously and individual fixes are not resolving the problem, a full restart is often the fastest path to recovery:

```bash
# Nuclear option: stop everything and start fresh
gt shutdown --all
gt start --all
```

This preserves all persistent state (beads, config, hooks) but gives every agent a clean session. Agents will automatically pick up their hooked work on restart.

:::warning

Before running `gt shutdown --all`, check if any polecats have uncommitted work: `gt polecat list --rig myproject`. Work that has been committed to the polecat's worktree branch is safe. Uncommitted changes in an active session will be lost.


:::

## See Also

- **[Monitoring](monitoring.md)** -- Proactive monitoring to prevent issues
- **[Diagnostics CLI](../cli-reference/diagnostics.md)** -- Diagnostic commands for debugging
- **[Lifecycle](lifecycle.md)** -- Agent lifecycle management