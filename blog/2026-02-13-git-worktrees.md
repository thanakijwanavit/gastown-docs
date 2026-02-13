---
title: "Why Git Worktrees? Gas Town's Isolation Strategy"
description: "How Gas Town uses git worktrees instead of containers to isolate parallel agent workspaces, and why this trade-off makes sense."
slug: git-worktrees
authors: [gastown]
tags: [architecture, git, isolation, concepts]
---

When you run 10 agents writing code in parallel, you need isolation. Each agent needs its own copy of the codebase where it can make changes without stepping on other agents' work. Gas Town solves this with git worktrees -- and the choice was deliberate.

<!-- truncate -->

## The Isolation Problem

Consider what happens without isolation:

```text
Agent A: Edits src/auth.go (adds validation)
Agent B: Edits src/auth.go (fixes token refresh)
Agent C: Edits src/auth.go (updates error messages)
```

Three agents editing the same file simultaneously in the same directory leads to chaos. Each agent's writes overwrite the others. The final state is unpredictable garbage.

You need each agent to have its own copy of the codebase. The question is: how?

## Option 1: Full Git Clones

The obvious approach is giving each agent a full `git clone`:

```bash
git clone repo.git agent-a/
git clone repo.git agent-b/
git clone repo.git agent-c/
```

This works but is expensive. Each clone copies the entire git history. For a repo with 100MB of history, ten clones means 1GB of disk. Cloning also takes time -- seconds to minutes depending on repo size.

## Option 2: Docker Containers

Another approach is running each agent in a Docker container:

```bash
docker run -v repo:/workspace agent-a
docker run -v repo:/workspace agent-b
```

Containers provide strong isolation (process-level, network-level) but add overhead: container startup time, image management, Docker daemon dependency, and complexity in managing git state across container boundaries.

## Option 3: Git Worktrees (Gas Town's Choice)

Git worktrees are the sweet spot for Gas Town's use case:

```bash
git worktree add ../polecats/toast feature-branch-a
git worktree add ../polecats/alpha feature-branch-b
```

Each worktree shares the same `.git` directory (zero duplication of history) but has its own working directory with its own branch checked out:

```text
myproject/
├── refinery/rig/           # Main clone (.git lives here)
│   └── .git/
├── polecats/
│   ├── toast/              # Worktree (own branch, shared .git)
│   └── alpha/              # Worktree (own branch, shared .git)
```

### Why Worktrees Win

| Factor | Full Clone | Container | Worktree |
|--------|-----------|-----------|----------|
| **Creation time** | Seconds-minutes | Seconds | Milliseconds |
| **Disk overhead** | Full repo per agent | Image + volume | Near zero |
| **Git integration** | Independent | Complex | Native |
| **Cleanup** | Delete directory | Remove container | `git worktree remove` |
| **Branch management** | Manual | Manual | Automatic |
| **History access** | Full (duplicated) | Mounted | Full (shared) |

Worktree creation is essentially instant -- it's just creating a directory and checking out files. No network calls, no image pulls, no history duplication.

```mermaid
flowchart TD
    GIT[".git/ (shared history)"] --> WT1["polecats/toast/ (branch A)"]
    GIT --> WT2["polecats/alpha/ (branch B)"]
    GIT --> WT3["crew/dave/ (main)"]
    GIT --> RF["refinery/rig/ (main)"]
    WT1 -.->|isolated| WT2
    WT2 -.->|isolated| WT3
```

## How Gas Town Uses Worktrees

### Polecat Sandboxes

When the Mayor slings a bead to a rig, a polecat worktree is created:

```text
gt sling gt-a1b2c myproject
→ git worktree add polecats/toast -b polecat/toast
→ Polecat session starts in polecats/toast/
→ Agent works on its own branch
→ Agent submits MR to Refinery
→ Refinery merges to main
→ Witness nukes worktree: git worktree remove polecats/toast
```

The entire polecat lifecycle -- create, work, submit, cleanup -- happens within worktree mechanics. No external tooling needed.

### Cross-Rig Worktrees

Crew workers can create worktrees in other rigs for cross-project work:

```bash
# Create a worktree to work on the beads project
gt worktree beads
# → Creates ~/gt/beads/crew/myproject-dave/

# Work on beads code directly
cd ~/gt/beads/crew/myproject-dave/
# ... fix a bug ...

# Clean up when done
gt worktree remove beads
```

This is how crew workers contribute to projects outside their home rig without needing a full clone.

### Refinery Merge Operations

The Refinery uses the canonical clone in `refinery/rig/` for merge operations:

```text
1. Fetch polecat branch: git fetch origin polecat/toast
2. Checkout main: git checkout main
3. Rebase polecat work: git rebase main polecat/toast
4. Run tests on rebased code
5. Fast-forward main: git merge --ff-only polecat/toast
6. Push: git push origin main
```

This happens in the Refinery's own working directory, completely isolated from all polecat worktrees.

## The Trade-Off

Gas Town's worktree approach provides **code isolation**, not **process isolation**. A misbehaving polecat could theoretically access files outside its worktree. For most code generation use cases, this is acceptable -- the risk model is "agent writes bad code" (caught by tests), not "agent escapes sandbox" (which requires container-level isolation).

If you need stronger isolation for security-sensitive workloads (running untrusted code, network-restricted environments), you can layer containers on top of Gas Town's worktree system. But for the common case of AI agents writing and testing code, worktrees provide the right balance of isolation, speed, and simplicity.

## Next Steps

- [Rigs](/docs/concepts/rigs) -- How rigs organize worktrees and agent infrastructure
- [Hooks](/docs/concepts/hooks) -- How work state persists in worktree-based hooks
- [Security Model](/blog/security-model) -- Gas Town's trust boundaries and isolation strategy
- [Git Workflow](/docs/guides/git-workflow) -- Multi-agent git patterns with worktrees
- [Git Workflows for Multi-Agent Development](/blog/git-workflows-multi-agent) -- Git patterns for multi-agent development with worktrees
