---
title: "The Crew Workflow: Human Developers in Gas Town"
description: "How human developers work alongside AI agents in Gas Town using persistent crew workspaces, direct main access, and flexible session management."
slug: crew-workflow
authors: [gastown]
tags: [crew, workflow, getting-started, best-practices]
---

Gas Town is not just for AI agents. Human developers have their own workspace type -- the **crew worker** -- designed to integrate seamlessly with the agent fleet. You get a persistent clone, direct push access to main, and the full Gas Town communication stack.

<!-- truncate -->

## What Makes Crew Different

Polecats are ephemeral. They spawn, do one task, submit to the merge queue, and self-destruct. Crew workers are the opposite:

| Property | Polecats | Crew |
|----------|----------|------|
| **Lifecycle** | Minutes to hours | Weeks to months |
| **Merge path** | Submit MR to Refinery | Push directly to main |
| **Monitoring** | Witness-supervised | Self-managed |
| **Workspace** | Isolated worktree (nuked after use) | Persistent git clone |
| **Identity** | Auto-generated name (toast, alpha) | Chosen name (dave, emma) |

Crew workers push directly to main because they have human judgment. There is no need for the Refinery to validate their work -- the human reviewer is already in the loop.

```mermaid
flowchart TD
    H[Human Overseer] --> C[Crew Worker]
    C -->|push direct| M[Main Branch]
    C -->|gt mail send| Mayor
    C -->|gt sling| P[Polecats]
    P -->|gt done| R[Refinery]
    R -->|merge| M
```

## Setting Up a Crew Workspace

Adding a crew member to a rig creates a full git clone:

```bash
# Add a crew workspace
gt crew add myproject dave

# Attach to the workspace
gt crew at dave --rig myproject
```

This creates:

```text
~/gt/myproject/crew/dave/    # Full git clone
├── .git/                    # Independent git history
├── src/                     # Your working copy
└── ...
```

The clone is completely independent. You can have uncommitted changes, experimental branches, and work-in-progress without affecting any other agent.

## The Daily Workflow

### Morning Startup

```bash
# 1. Load context
gt prime

# 2. Check your hook (any assigned work?)
gt hook

# 3. Check mail
gt mail inbox

# 4. Pull latest from main
git pull

# 5. Check what's ready to work on
bd ready
```

### Working on Issues

```bash
# Claim an issue
bd update ga-abc --status in_progress

# Do the work...
# (edit files, run tests, etc.)

# Commit and push directly to main
git add -A
git commit -m "Fix auth bug in token refresh"
git push

# Close the issue
bd close ga-abc --reason "Fixed in commit abc1234"
```

### Communicating with Agents

```bash
# Send mail to the Mayor
gt mail send mayor/ -s "Feature request" -m "Add rate limiting to the API"

# Nudge a stuck polecat
gt nudge myproject/toast "Check your mail - the API endpoint changed"

# Create work and dispatch it
bd create "Add input validation" --type task --priority 1
gt sling ga-xyz myproject
```

## Session Cycling for Crew

Unlike polecats (which cycle automatically when context fills), crew workers cycle at their own pace:

- **Context getting full?** Run `gt handoff -m "notes for next session"`
- **Finished a chunk of work?** Good time to cycle for a fresh perspective
- **Need to step away?** Commit, push, and your hook preserves your assignment

The key difference: crew cycling is optional and human-controlled. You are never forced to cycle.

```bash
# Handoff with context notes
gt handoff -s "Working on auth refactor" -m "
Finished token refresh logic.
Next: update the middleware in auth/middleware.go.
The failing test is TestRefreshExpired - needs mock update.
"
```

## Working Across Rigs

Sometimes you need to fix something in a different project. Gas Town's worktree system lets you work on other rigs without leaving your crew workspace:

```bash
# Create a worktree in another rig
gt worktree beads

# Now you can work in ~/gt/beads/crew/myproject-dave/
# Your identity stays as myproject/crew/dave

# When done, remove the worktree
gt worktree remove beads
```

This is better than using `gt sling` (which dispatches work to a polecat) because you maintain human judgment over the fix.

## Crew vs. Vibe Coding

Gas Town embraces "vibe coding" -- letting AI do the heavy lifting while you focus on direction and review. Crew workers sit at the intersection:

- **Specify work clearly** -- Write good bead descriptions so polecats know exactly what to build
- **Review polecat output** -- Check merged code, file follow-up beads for issues
- **Handle the hard stuff** -- Take on complex refactoring, architecture decisions, and sensitive operations that benefit from human judgment
- **Stay in the loop** -- Use `gt feed` and `gt convoy list` to monitor progress

The most effective Gas Town operators spend 80% of their time on specification and review, and 20% on direct coding in their crew workspace.

```mermaid
flowchart LR
    subgraph Crew["Crew Operator Time Split"]
        S[Specify: 40%] --> R[Review: 40%]
        R --> C[Code: 20%]
    end
```

## Best Practices

1. **Push frequently.** In a multi-agent environment, unpushed work diverges fast. Push after every logical chunk.
2. **Use handoff mail.** Even for your own next session, good notes save significant ramp-up time.
3. **Keep git status clean.** Before stepping away, commit or stash everything. A dirty workspace causes confusion on restart.
4. **File beads for follow-ups.** If you notice something while working, file a bead rather than trying to fix everything at once.
5. **Communicate through Gas Town channels.** Use `gt mail` and `gt nudge` rather than side channels so all coordination is observable.

## Next Steps

- [Crew Workers](/docs/agents/crew) -- Full crew worker reference
- [Git Workflow](/docs/guides/git-workflow) -- Multi-agent git workflow patterns
- [Session Cycling](/docs/concepts/session-cycling) -- How context refresh works for crew
- [Cost Management](/docs/guides/cost-management) -- Optimizing token spend across your team
- [Session Cycling Explained](/blog/session-cycling) -- How crew members handle context limits with handoffs
- [Agent Communication Patterns](/blog/agent-communication-patterns) -- Mail, nudges, and hooks for crew coordination
