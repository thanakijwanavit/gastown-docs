---
title: "Troubleshooting"
sidebar_position: 7
description: "Solutions for the most common Gas Town issues: gt done failures, polecat churn, branch mismatches, bead routing, hook slots, and stuck merges."
---

# Troubleshooting

This guide covers the most frequently encountered Gas Town issues with diagnostic commands and fixes. For comprehensive operational troubleshooting (agent crashes, daemon issues, orphaned processes), see the [Operations Troubleshooting](../operations/troubleshooting.md) guide.

---

## `gt done` Fails: "Not Inside a Rig Directory"

**Symptom:** A polecat completes its work, runs `gt done`, and gets an error like `not inside a rig directory` -- even though the polecat is clearly inside its worktree.

**Root cause:** Gas Town expects polecat worktrees at `polecats/<name>/rig/`, but some rigs (notably `gastowndocs`) create worktrees with a project subdirectory instead: `polecats/<name>/gastowndocs/`. The rig detection logic walks up the directory tree looking for markers and fails to find them at the expected depth.

A related issue is the `.beads/redirect` file. This file uses a relative path (e.g., `../../../.beads`) to point from the worktree's `.beads/` to the rig-level beads database. When the worktree has extra nesting, the redirect resolves to the wrong directory.

**Diagnosis:**

```bash
# Verify your current location
pwd
# Expected: ~/gt/<rig>/polecats/<name>/<project>/

# Check if .beads/redirect points to the right place
cat .beads/redirect 2>/dev/null

# Check what gt thinks your rig is
git remote -v
git worktree list
```

**Workaround:**

```bash
# 1. Commit and push your work manually
git status
git add <files>
git commit -m "your commit message"
git push origin HEAD

# 2. Escalate so the Witness can clean up your worktree
gt mail send <rig>/witness -s "HELP: gt done failing" -m "Polecat: <name>
Issue: <bead-id>
Error: not inside a rig directory
Branch pushed: yes
Git state: clean"

# 3. If you must exit, escalate with status
gt done --status=ESCALATED
```

**Prevention:** This is a known bug ([ga-w8vv](https://github.com/steveyegge/gastown)). Until the fix lands, polecats in affected rigs should always push their branch before attempting `gt done`, so work is preserved even if the command fails.

---

## Polecat Churn Cycle

**Symptom:** A polecat spawns, works for a while, fills its context window, hands off, a new session spawns, fills context again, and the cycle repeats -- with little or no forward progress on the actual task.

**Root cause:** The task is too large for a single context window, but the handoff notes do not carry enough state for the successor to make progress efficiently. Each new session spends most of its context re-reading files and re-discovering what the predecessor already knew.

**Diagnosis:**

```bash
# Check how many times this bead has been handed off
gt trail --bead <bead-id>

# Check polecat history for the rig
gt polecat list --rig <rig>

# Look for repeated handoff patterns
gt audit polecat:<name> --rig <rig>
```

**Solutions:**

1. **Break the task into smaller beads.** If a task consistently causes churn, decompose it into subtasks that each fit within a single context window.

    ```bash
    bd create --title="Part 1: implement X" --type=task
    bd create --title="Part 2: implement Y" --type=task
    bd create --title="Part 3: write tests" --type=task
    bd dep add <part2> <part1>
    bd dep add <part3> <part2>
    ```

2. **Improve handoff notes.** When a polecat hands off, the notes should include:
    - Exactly which files were modified and why
    - What remains to be done (specific, not vague)
    - Any decisions already made so the successor does not re-evaluate them

    ```bash
    gt handoff -s "Implementing feature X - 60% done" -m "Issue: <bead-id>
    Branch: feature/add-x (pushed)
    Done: Created models in src/models/x.ts, added routes in src/routes/x.ts
    Remaining: Write tests in tests/x.test.ts, update docs
    Decisions: Using JWT auth (not API keys) per discussion in bead notes"
    ```

3. **Commit incrementally.** Each logical unit of progress should be committed and pushed before context fills. This ensures successors start with working code, not half-finished changes.

**Prevention:** The Mayor should decompose large tasks before slinging them. A good heuristic: if a task requires reading more than 10 files to understand the codebase, it is probably too large for one polecat session.

---

## `origin/main` vs `origin/master`

**Symptom:** Git operations fail with errors like `fatal: invalid reference: origin/main` or branches diverge unexpectedly. The Refinery rejects MRs because it cannot rebase onto the expected branch.

**Root cause:** The repository's default branch is `master`, but Gas Town commands (and the Refinery) assume `main`. Or vice versa -- the repo uses `main` but some local configuration or stale references still point to `master`.

**Diagnosis:**

```bash
# Check what the remote default branch is
git remote show origin | grep "HEAD branch"

# Check local branch tracking
git branch -vv

# Check what branches exist on the remote
git branch -r

# Check Gas Town's assumption
git config --get init.defaultBranch
```

**Solutions:**

1. **Align the local repo with the remote.** If the remote uses `main`:

    ```bash
    # Ensure you are tracking the correct branch
    git fetch origin
    git branch --set-upstream-to=origin/main main
    ```

2. **If the remote uses `master` but Gas Town expects `main`:**

    ```bash
    # Rename local branch
    git branch -m master main

    # Update tracking
    git fetch origin
    git branch --set-upstream-to=origin/master main
    ```

3. **If the remote has both `main` and `master`:** One is stale. Check which one has recent commits:

    ```bash
    git log --oneline -5 origin/main
    git log --oneline -5 origin/master
    ```

    The branch with recent commits is the active one. Delete the stale remote branch (if you have permission) or update your local tracking to point at the active one.

**Prevention:** When setting up a new rig, verify the default branch immediately:

```bash
git remote show origin | grep "HEAD branch"
```

The Refinery always rebases onto `main`. If your repo uses `master`, rename it before creating the rig, or coordinate with the rig owner to update the configuration.

---

## Bead Routing: Town vs Rig

**Symptom:** A `bd` command returns "issue not found" or operates on the wrong beads database. Beads created in one context are invisible from another. Cross-rig bead references fail.

**Root cause:** Gas Town has a two-level beads architecture. Town-level beads (prefix `hq-`) live in `~/gt/.beads/`. Rig-level beads (project-specific prefixes like `ga-`, `gt-`) live in each rig's `.beads/` directory. The `bd` CLI uses prefix-based routing defined in `~/gt/.beads/routes.jsonl` to determine which database to query.

**Diagnosis:**

```bash
# Check routing configuration
cat ~/gt/.beads/routes.jsonl

# Debug routing for a specific bead
BD_DEBUG_ROUTING=1 bd show <bead-id>

# Check which beads database you are hitting
bd doctor
```

**Common scenarios and fixes:**

1. **"Issue not found" for a bead that exists.** The prefix is routing to the wrong database.

    ```bash
    # Check where the bead actually lives
    BD_DEBUG_ROUTING=1 bd show <bead-id>

    # If routing is wrong, specify the rig explicitly
    bd show <bead-id> --rig <correct-rig>
    ```

2. **Polecat cannot see rig-level beads.** The polecat's `.beads/redirect` file may be incorrect (see the `gt done` section above for the redirect path issue).

    ```bash
    # Check redirect from inside the polecat worktree
    cat .beads/redirect

    # The path should resolve to the rig's .beads/ directory
    # e.g., ../../../../.beads for a worktree at polecats/<name>/<project>/
    ```

3. **Filing a bead in the wrong rig.** Remember the rule: file in the rig that **owns the code**, not the rig you are currently in.

    ```bash
    # File in the current rig (default)
    bd create --title="Fix broken test" --type=bug

    # File in a different rig
    bd create --rig gastown --title="gt sling flag missing" --type=bug

    # File at town level (HQ)
    bd create --prefix hq- --title="Cross-rig coordination needed" --type=task
    ```

4. **Dependency links across levels.** Dependencies between town-level and rig-level beads work, but require the full bead ID including prefix:

    ```bash
    # Rig bead depends on HQ bead
    bd dep add ga-abc123 hq-xyz789
    ```

---

## Hook Slot Failures

**Symptom:** An agent starts up but has no work on its hook. Or `gt hook` shows unexpected output -- wrong bead, empty when it should have work, or a stale reference to a closed bead.

**Root cause:** The hook is a persistent filesystem pointer from an agent to its current work. Hook failures happen when:

- The bead was closed or released but the hook was not cleared
- A previous polecat session crashed before the Witness cleaned up the hook
- The hook file was corrupted by concurrent writes
- The bead ID in the hook references a database the agent cannot reach (routing issue)

**Diagnosis:**

```bash
# Check your hook
gt hook

# Check hook for a specific agent
gt hook --agent <agent> --rig <rig>

# Verify the hooked bead actually exists
bd show <bead-id-from-hook>

# Check if the bead is in the expected state
bd list --status=hooked
```

**Solutions:**

1. **Hook is empty but should have work.** The Witness or Mayor may not have attached work yet. Check mail first:

    ```bash
    gt mail inbox

    # If mail has attached work
    gt mol attach-from-mail <mail-id>
    ```

2. **Hook points to a closed or invalid bead.** The bead was completed by a previous session but the hook was not cleaned up:

    ```bash
    # Release the stale hook
    gt release <stale-bead-id>

    # Check for new work
    bd ready
    ```

3. **Hook has the right bead but the agent cannot read it.** This is a routing issue:

    ```bash
    # Debug routing
    BD_DEBUG_ROUTING=1 bd show <bead-id>

    # If the bead is in a different rig's database, the redirect may be wrong
    cat .beads/redirect
    ```

4. **Multiple agents hooked to the same bead.** This should not happen but can occur after crashes:

    ```bash
    # Check who is hooked to what
    gt polecat list --rig <rig>

    # The Witness should detect this during patrol
    # If not, manually release one
    gt release <bead-id>
    gt sling <bead-id> <rig>
    ```

**Prevention:** Hooks survive all disruptions (session restarts, compaction, crashes, reboots). The most common failure mode is stale hooks from polecats that crashed before running `gt done`. The Witness patrol cycle detects and cleans these up automatically. If the Witness itself is down, hook cleanup stalls -- restart the Witness first.

---

## Refinery Stuck Merges

**Symptom:** Completed work is sitting in the merge queue but not being merged to `main`. The queue shows MRs in `queued` or `processing` state indefinitely.

**Root cause:** The Refinery processes MRs sequentially: rebase, validate, merge. If any step fails, the MR stalls and can block the entire queue. Common causes:

- The Refinery session is dead or unresponsive
- Repeated rebase conflicts on the same MR
- Validation (tests) failing after rebase
- `main` itself is broken, causing all validations to fail

**Diagnosis:**

```bash
# Check queue status
gt mq list --rig <rig>
gt mq status --rig <rig>

# Check if the Refinery is alive
gt peek refinery --rig <rig>
gt rig status <rig>

# Check for conflict details on a specific MR
gt mq show <mr-id>

# Check if main is healthy
git fetch origin
git log --oneline -5 origin/main
```

**Solutions:**

1. **Refinery session is dead.** Restart it:

    ```bash
    gt refinery restart --rig <rig>
    ```

2. **One MR is blocking the queue with conflicts.** Skip it so other MRs can proceed:

    ```bash
    # Skip the problematic MR
    gt mq skip <mr-id>

    # The bead goes back to pending for reassignment
    gt sling <bead-id> <rig>
    ```

    The respawned polecat will rebase onto the latest `main` (which now includes the MRs that were behind the stuck one) and resolve the conflict.

3. **Tests failing after rebase.** The branch was green when the polecat pushed it, but rebasing onto newer `main` introduced test failures:

    ```bash
    # Check if main itself has broken tests
    git checkout origin/main
    # Run your project's test command

    # If main is broken, that needs to be fixed first
    bd create --title="Fix broken tests on main" --type=bug --priority=0
    gt sling <new-bead-id> <rig>
    ```

4. **Queue is processing but very slow.** If your validation step (tests, linting, build) is slow, the queue throughput is limited:

    ```bash
    # Check how long MRs spend in processing
    gt mq status --rig <rig>

    # Consider whether your validation command can be optimized
    ```

5. **The MERGED mail contract.** After a successful merge, the Refinery must send a `MERGED` mail to the Witness. If this mail is lost or delayed, the Witness does not know to clean up the polecat's worktree, and worktrees accumulate:

    ```bash
    # Check if the Witness received merge notifications
    gt mail inbox --agent witness --rig <rig>

    # Manually trigger cleanup if needed
    gt cleanup --rig <rig>
    ```

**Prevention:** Keep your test suite fast. Avoid having many polecats modify the same files in parallel -- this maximizes rebase conflicts. Use convoy dependencies to serialize work on shared files.

---

## Quick Reference: Diagnostic Commands

| Situation | Command |
|-----------|---------|
| General health check | `gt doctor` |
| Auto-repair known issues | `gt doctor --fix` |
| What is on my hook? | `gt hook` |
| What work is ready? | `bd ready` |
| Show a specific bead | `bd show <id>` |
| Debug bead routing | `BD_DEBUG_ROUTING=1 bd show <id>` |
| Check merge queue | `gt mq list --rig <rig>` |
| List stale polecats | `gt polecat stale` |
| View agent output | `gt peek <agent>` |
| Recent activity log | `gt trail --since 1h` |
| Open escalations | `gt escalate list` |
| Beads database health | `bd doctor` |
| Find orphaned resources | `gt orphans` |
| Clean up stale resources | `gt cleanup` |

---

## See Also

- [Operations Troubleshooting](../operations/troubleshooting.md) -- comprehensive guide covering agent crashes, daemon issues, context window problems, and more
- [Usage Guide](usage-guide.md) -- day-to-day patterns and the session completion checklist
- [Glossary](glossary.md) -- terminology reference
