---
title: "Error Recovery"
sidebar_position: 5
description: "How to recover from common agent failure modes including stuck loops, gt done failures, uncommitted work, and session crashes."
---

# Error Recovery

This guide covers common agent failure patterns, how to detect them, and step-by-step recovery procedures. For general troubleshooting, see the [Troubleshooting](./troubleshooting.md) guide.

---

## Quick Recovery Reference

| Symptom | Detection | Recovery |
|---------|-----------|----------|
| Agent stuck in error loop | Repetitive error output, no progress | [Cheeto Pattern](#stuck-in-error-loop-cheeto-pattern) |
| `gt done` fails | Cannot complete work submission | [`gt done` Failures](#gt-done-failures) |
| Uncommitted work lost | Session crash, no commit history | [Uncommitted Work Recovery](#uncommitted-work-recovery) |
| Session unresponsive | No output, ignores commands | [Session Crashes](#session-crashes) |

---

## Stuck in Error Loop (Cheeto Pattern)

**Symptom:** An agent repeatedly encounters the same error, attempts recovery, fails, and repeats. The cycle continues indefinitely without human intervention.

**Detection:**

```bash
# Check for repetitive error patterns
gt peek <agent> --rig <rig> --lines 100 | grep -i "error\|fail\|retry" | tail -20

# Check loop count (if available)
gt trail --agent <agent> --rig <rig> --since 10m | grep -c "attempt\|retry"
```

**Recovery:**

1. **Immediate break:** Stop the looping agent.

   ```bash
   # Stop the agent session
   gt polecat stop <name> --rig <rig>
   # Or for persistent agents
   gt <agent> stop --rig <rig>
   ```

2. **Analyze the root cause** before respawning:

   ```bash
   # Review the error trail
   gt trail --agent <agent> --rig <rig> --since 30m

   # Check if it's a dependency issue
   bd show <bead-id>

   # Verify external resources
   ping <external-service>
   ```

3. **Apply the appropriate fix:**

   | Cause | Fix |
   |-------|-----|
   | Missing dependency | Install dependency, update environment |
   | Transient network error | Retry after delay |
   | Invalid configuration | Fix config, validate with `gt doctor` |
   | Permission denied | Check ownership, fix permissions |
   | External service down | Wait or escalate to operator |

4. **Respawn with monitoring:**

   ```bash
   # Re-sling the work
   gt sling <bead-id> <rig>

   # Watch for immediate re-looping
   gt peek polecat:<name> --rig <rig> --follow
   ```

**Prevention:**

- Agents should implement exponential backoff with a maximum retry limit
- Circuit breaker pattern: After N failures, escalate instead of retrying
- Add `gt handoff` checkpoints in long-running tasks to break potential loops

---

## `gt done` Failures

**Symptom:** A polecat completes its work but cannot successfully run `gt done`. The command fails with various errors, leaving the polecat in limbo—work finished but not submitted.

### Common Failure Modes

#### 1. Uncommitted Changes

**Detection:**

```bash
# Check git status from within the polecat session
git status
```

**Recovery:**

```bash
# Commit remaining changes
git add -A
git commit -m "fix: complete remaining changes (<bead-id>)"
git push

# Retry gt done
gt done
```

#### 2. Push Rejected (Remote Diverged)

**Detection:**

```bash
# Check remote status
git fetch origin
git log --oneline origin/main..HEAD
git log --oneline HEAD..origin/main
```

**Recovery:**

```bash
# Rebase onto latest main
git rebase origin/main

# If conflicts occur:
# 1. Resolve each conflict file
# 2. git add <resolved-files>
# 3. git rebase --continue
# 4. Retry push

git push
gt done
```

#### 3. Merge Queue Submission Failed

**Detection:**

```bash
# Check merge queue status
gt mq status --rig <rig>
gt mq list --rig <rig>
```

**Recovery:**

```bash
# If MQ is full, wait and retry
gt mq status --rig <rig>

# If submission failed for other reasons, retry
gt done --retry
```

#### 4. Persistent Failures

If `gt done` continues to fail after standard fixes:

```bash
# 1. Preserve work by ensuring everything is pushed
git push --force-with-lease  # Only if necessary

# 2. Escalate with full context
gt mail send <rig>/witness -s "ESCALATE: gt done failing" -m "Polecat: <name>
Bead: <bead-id>
Git status: $(git status --porcelain)
Commits ahead of main: $(git log --oneline origin/main..HEAD | wc -l)
Last error: <copy error message>
Branch pushed: yes/no"

# 3. Exit cleanly
gt done --status=ESCALATED
```

---

## Uncommitted Work Recovery

**Symptom:** A polecat session crashes before committing work. Changes exist in the working tree but are not committed or pushed.

**Detection (by Witness/Patrol):**

```bash
# Check for uncommitted work in polecat directories
gt polecat list --rig <rig>
gt peek polecat:<name> --rig <rig>

# Check git status in each worktree
for dir in ~/gt/<rig>/polecats/*/<rig>; do
  echo "=== $dir ==="
  (cd "$dir" && git status --porcelain)
done
```

**Recovery:**

1. **From outside the polecat session:**

   ```bash
   cd ~/gt/<rig>/polecats/<name>/<rig>

   # Check what's there
   git status
   git diff
   ```

2. **If changes are salvageable:**

   ```bash
   # Stage and commit the work
   git add -A
   git commit -m "fix: recover work from crashed session (<bead-id>)

   Recovered after session crash. Original polecat: <name>"
   git push

   # Release the work back to pending
   gt release <bead-id>

   # Re-sling for completion
   gt sling <bead-id> <rig>
   ```

3. **If changes are incomplete/unclear:**

   ```bash
   # Create a recovery branch
   git checkout -b recovery/<bead-id>-$(date +%s)
   git add -A
   git commit -m "WIP: recovered from crash (<bead-id>)"
   git push origin recovery/<bead-id>-$(date +%s)

   # Create a new bead for cleanup work
   bd create --title "Complete recovery for <bead-id>" \
             --type task \
             --description "Recovered WIP from crashed session. See branch recovery/<bead-id>-<timestamp>"

   # Release original bead
   gt release <bead-id>
   ```

**Prevention:**

- Polecats should commit incrementally during long tasks
- Use `gt handoff` to cycle sessions before context fills
- Witness patrol detects stale polecats and can trigger recovery

---

## Session Crashes

**Symptom:** An agent session terminates unexpectedly. The tmux session ends, the process dies, or the agent becomes completely unresponsive.

### Detection

```bash
# Check if tmux session exists
tmux list-sessions | grep <agent>

# Check if process is running
ps aux | grep claude | grep <session-id>

# Check Deacon health reports
gt deacon status --rig <rig>
```

### Recovery by Agent Type

#### Polecat Crashes

```bash
# 1. Check for uncommitted work
gt peek polecat:<name> --rig <rig> 2>/dev/null || echo "Session dead"

# 2. If work exists, attempt recovery (see Uncommitted Work section)
cd ~/gt/<rig>/polecats/<name>/<rig>
git status

# 3. Release and respawn
gt release <bead-id>
gt sling <bead-id> <rig>

# 4. New polecat loads context and continues
gt peek polecat:<new-name> --rig <rig>
```

#### Witness Crashes

```bash
# 1. Restart the Witness
gt witness start --rig <rig>

# 2. Verify it picks up patrol duties
gt peek witness --rig <rig>
gt trail --agent witness --rig <rig> --since 1m
```

#### Mayor Crashes

```bash
# 1. Restart the Mayor
gt mayor start

# 2. Check mail queue for pending items
gt mail inbox --agent mayor

# 3. Verify cross-rig coordination restored
gt rig list
```

#### Deacon Crashes

```bash
# 1. Restart the Deacon
gt deacon start

# 2. Verify daemon reconnection
gt daemon status

# 3. Check agent health reports resume
gt deacon status
```

### When to Restart vs. Nuke

| Situation | Action | Command |
|-----------|--------|---------|
| Session died, work committed | Restart agent | `gt <agent> start --rig <rig>` |
| Session died, uncommitted work | Recovery mode, then restart | See Uncommitted Work section |
| Session corrupted/confused | Fresh start | `gt <agent> restart --rig <rig> --fresh` |
| Persistent crashes | Clean shutdown, fresh start | `gt shutdown --all && gt start --all` |

---

## Recovery Automation

The Witness patrol includes automatic recovery for certain failure modes:

```bash
# Check patrol status
gt witness status --rig <rig>

# Review recent recovery actions
gt trail --agent witness --rig <rig> --since 1h | grep -i "recover\|restart\|clean"
```

**Auto-recovery triggers:**

- Stale polecats (no output for threshold period) → Nudge → Escalate
- Detected uncommitted work in crashed sessions → Alert operator
- Orphaned processes → Cleanup
- Failed `gt done` with clear fix → Attempt retry

---

## Escalation Checklist

When recovery fails, escalate with this information:

```bash
gt mail send <rig>/witness -s "ESCALATE: <brief description>" -m "Issue: <bead-id>
Agent: <agent-name>
Failure: <error loop/gt done/crash/other>

What was tried:
- <step 1>
- <step 2>

Current state:
- Git status: <clean/dirty>
- Branch pushed: <yes/no>
- Session alive: <yes/no>

Blocker: <what is preventing progress>"
```

---

## Recovery Commands Summary

| Command | Purpose |
|---------|---------|
| `gt polecat stop <name>` | Stop a stuck polecat |
| `gt release <bead-id>` | Release work from agent |
| `gt sling <bead-id> <rig>` | Re-assign work to new agent |
| `gt <agent> restart --fresh` | Fresh agent start |
| `gt trail --since <time>` | Review recent activity |
| `gt doctor` | System health check |
| `bd doctor` | Beads health check |
| `gt cleanup` | Remove stale resources |
| `gt orphans` | Find disconnected resources |
