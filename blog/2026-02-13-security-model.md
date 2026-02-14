---
title: "Gas Town's Security Model: Trust Boundaries for AI Agents"
description: "How Gas Town implements security through workspace isolation, permission scoping, and trust boundaries between agents."
slug: security-model
authors: [gastown]
tags: [security, architecture, operations, best-practices]
---

When you give AI agents write access to your codebase, security stops being theoretical. Gas Town's security model is built around a simple principle: **minimize the blast radius of any single agent's actions** through workspace isolation, scoped permissions, and trust boundaries.

<!-- truncate -->

## The Trust Hierarchy

Gas Town organizes agents into a trust hierarchy where each level has progressively narrower access:

```text
Overseer (Human)     ← Full access, all rigs, all secrets
  └── Mayor          ← Read access to all rigs, dispatch authority
      └── Deacon     ← Infrastructure management, no code write access
      └── Per-Rig Agents:
          ├── Witness     ← Read-only monitoring of rig state
          ├── Refinery    ← Write access to main branch only
          ├── Crew        ← Full write access to their clone
          └── Polecats    ← Write access to sandboxed worktree only
```

Each agent can only affect what its trust level permits. A polecat cannot push to main directly -- it submits to the Refinery, which validates and merges. The Witness can observe but not modify code. The Mayor can dispatch but not implement.

```mermaid
flowchart TD
    O[Overseer: Full Access] --> MY[Mayor: Read + Dispatch]
    MY --> DC[Deacon: Infrastructure Only]
    MY --> W[Witness: Read-Only]
    MY --> RF[Refinery: Write Main Only]
    MY --> CR[Crew: Write Own Clone]
    MY --> PC[Polecats: Sandboxed Worktree]
```

## Workspace Isolation

The first line of defense is **physical isolation through git worktrees**. Every polecat works in its own isolated worktree:

```text
~/gt/myproject/
├── refinery/rig/     # Refinery's canonical clone (protected)
├── crew/dave/        # Dave's persistent workspace
├── polecats/
│   ├── toast/        # Polecat toast's isolated worktree
│   └── alpha/        # Polecat alpha's isolated worktree
```

Polecats cannot see or modify each other's worktrees. A polecat that goes haywire -- writing garbage to files, deleting directories, corrupting state -- affects only its own sandbox. The Witness detects the problem, and the sandbox is nuked without impacting any other agent or the main branch.

### Why Worktrees, Not Containers?

Gas Town uses git worktrees rather than Docker containers for isolation because:

- **Speed** -- Worktree creation is milliseconds vs. seconds for containers
- **Git-native** -- No extra tooling to manage; git handles the isolation
- **Lightweight** -- No container runtime overhead; polecats are just directories
- **Sufficient isolation** -- For code changes, filesystem isolation is what matters

This is a deliberate trade-off: Gas Town provides **code isolation**, not **process isolation**. If you need stronger sandboxing (untrusted code execution, network isolation), layer containers on top.

```mermaid
flowchart TD
    subgraph Isolation["Workspace Isolation"]
        R[Rig Clone .git]
        R --> WT1["polecats/toast/ (sandboxed)"]
        R --> WT2["polecats/alpha/ (sandboxed)"]
        R --> CW["crew/dave/ (full access)"]
        R --> RF["refinery/rig/ (merge only)"]
    end
    WT1 -.->|cannot access| WT2
    WT1 -.->|cannot access| CW
```

## The Refinery Gate

The Refinery is the single point where code enters `main`. No agent pushes directly to the main branch (except crew workers, who are human-managed). This creates a natural security checkpoint:

```text
Polecat work → Branch push → Merge Request → Refinery validates → Merge to main
                                                 ↓
                                          Tests must pass
                                          Rebase must succeed
                                          No conflict markers
```

The Refinery runs the full test suite before merging. If tests fail, the merge is rejected and a conflict-resolution bead is created. This prevents broken code from reaching main, even if a polecat's implementation has bugs.

```mermaid
stateDiagram-v2
    [*] --> Write: Polecat writes code
    Write --> Push: Push to feature branch
    Push --> Validate: Refinery rebases + tests
    Validate --> Merge: Tests pass
    Validate --> Reject: Tests fail
    Merge --> Main: Fast-forward to main
    Reject --> Retry: New polecat retries
    Note right of Validate: Security checkpoint
```

## Secrets Management

Gas Town follows a strict rule: **secrets never enter agent context**.

- **Environment variables** -- Agents inherit minimal env vars. Secrets are not set in agent sessions.
- **`.env` files** -- The `.gitignore` in every rig excludes `.env`, credentials, and key files.
- **Beads** -- The beads database stores work metadata, not secrets. If a bead description inadvertently contains a secret, it is flagged during review.
- **Handoff mail** -- Mail content is stored in the beads database. Never include secrets in handoff notes.

:::warning[API Keys]

If your CI needs API keys, configure them in your CI provider's secrets management (GitHub Secrets, etc.), not in the Gas Town workspace. Agents should never have direct access to production credentials.

:::

:::info Crew Workers Have Broader Access Than Polecats by Design
Crew workers operate in persistent clones with full write access to their workspace, while polecats are confined to sandboxed worktrees. This is intentional: crew workers are human-managed sessions where an operator is actively reviewing changes, so they need the flexibility to modify any file. If you want to limit a crew worker's scope, use branch protection rules and code owners rather than Gas Town's workspace isolation.
:::

## Agent Identity and Audit Trail

Every action in Gas Town is attributable. The `BD_ACTOR` environment variable identifies each agent:

The following diagram illustrates how actions flow through the audit trail system.

```mermaid
flowchart LR
    PC[Polecat Action] -->|BD_ACTOR: gastowndocs/polecats/toast| GC[Git Commit]
    PC -->|BD_ACTOR: gastowndocs/polecats/toast| BD[Bead Update]
    PC -->|BD_ACTOR: gastowndocs/polecats/toast| ML[Mail Message]
    GC --> AT[Audit Trail]
    BD --> AT
    ML --> AT
    AT --> LOG[Complete Attribution Log]
```


```text
gastowndocs/crew/nic       # Crew worker nic in the gastowndocs rig
gastowndocs/polecats/toast # Polecat toast in the gastowndocs rig
```

This identity is recorded on every bead operation, git commit, and mail message. The beads database provides a complete audit trail: who created an issue, who worked on it, who closed it, and when.

:::note Git Commit Attribution Mirrors BD_ACTOR for Compliance Traceability
Every git commit created by a Gas Town agent includes the agent's BD_ACTOR identity in the commit author field, not a generic "bot" identity. This ensures that audit logs, code ownership tools, and compliance systems can trace every change back to the specific agent session that created it — critical for regulated environments where attribution cannot be ambiguous.
:::

```mermaid
timeline
    title Security Evolution in Gas Town
    section Bootstrap
        Single Rig : Workspace isolation via worktrees
        First Agents : Refinery gate for all merges
    section Production
        Multi-Rig : Cross-rig routing with prefixes
        Secrets : Environment separation and .gitignore
    section Scale
        Branch Protection : CI/CD integration gates
        Audit Trail : BD_ACTOR identity tracking
        Gates : Human approval for production ops
```

| Failure Mode | Blast Radius | Recovery |
|-------------|-------------|----------|
| Polecat writes bad code | Its worktree only | Witness nukes sandbox |
| Polecat crashes mid-work | Its branch only | New polecat resumes from hook |
| Refinery merges a bug | Main branch | Revert commit, file P0 bead |
| Witness false positive | Polecat killed early | Bead returns to ready queue |
| Mayor dispatches wrong work | Wasted polecat cycles | Close incorrect beads, re-dispatch |

The worst case -- a bug merged to main -- is handled by standard git practices (revert) and the beads system (P0 escalation). Gas Town does not add risk beyond what any CI/CD pipeline has.

:::tip Use Gates for Any Production-Facing Operation
For operations that touch production infrastructure — deployments, database migrations, secret rotations — always require a human-approval gate. Even well-tested agent code can have unintended production consequences. Gates add a few minutes of human review time but prevent the kind of irreversible mistakes that no amount of automated testing can catch.
:::

:::caution Review Branch Protection Rules Before Enabling Agent Workflows
Before onboarding a new rig, verify that your repository's branch protection rules allow the Refinery to push to main while still blocking direct pushes from other agents. A misconfigured branch protection setup can either lock out the Refinery entirely — stalling all merges — or leave main unprotected against direct polecat pushes, bypassing the validation pipeline you depend on.
:::

```mermaid
sequenceDiagram
    participant PC as Polecat
    participant BR as Feature Branch
    participant RF as Refinery
    participant CI as CI/CD
    participant M as Main Branch
    PC->>BR: Push code changes
    BR->>RF: Submit merge request
    RF->>RF: Rebase onto main
    RF->>CI: Run validation suite
    CI-->>RF: Tests pass
    RF->>M: Fast-forward merge
    Note over RF,M: Only validated code reaches main
```

## Best Practices

1. **Never commit secrets.** Use `.gitignore` patterns for `.env`, `*.key`, `credentials.*`, and similar files.
2. **Review Refinery merges.** Enable branch protection and required reviews for production repositories.
3. **Monitor the audit trail.** Use `bd list` and `gt feed` to watch for unexpected activity. For comprehensive monitoring strategies, see [monitoring your fleet](/blog/monitoring-fleet).
4. **Scope agent permissions.** Crew workers need write access; the Witness does not. Keep permissions minimal. When extending Gas Town with custom functionality, follow the security guidelines in the [plugins documentation](/docs/operations/plugins). For insights on how plugins interact with the broader architecture, see the [plugin system guide](/blog/plugin-system).
5. **Use gates for sensitive operations.** Production deploys and infrastructure changes should require human approval via [gates](/docs/concepts/gates).

:::note Security Boundaries Are Enforced at the Git Layer, Not the Process Layer
Gas Town's isolation model relies on git worktrees to keep agents in separate working directories, not on process sandboxing or containerization. This means agents share the same filesystem, network access, and environment variables. If your threat model requires process-level isolation — for example, running untrusted code or enforcing network boundaries — you need to layer Docker or VM-based sandboxing on top of Gas Town's git-based workspace isolation.
:::

## Next Steps

- [Architecture Overview](/docs/architecture/overview) -- How agents are organized within the town
- [Gates](/docs/concepts/gates) -- Human approval gates for sensitive operations
- [Monitoring & Observability](/docs/operations/monitoring) -- Watching agent behavior in real time
- [Troubleshooting](/docs/operations/troubleshooting) -- When things go wrong and how to recover
- [Git Worktrees](/blog/git-worktrees) -- Worktree isolation as a security boundary
- [Death Warrants](/blog/death-warrants) -- How the warrant system enforces safe termination
- [Understanding Rigs](/blog/understanding-rigs) -- How rigs enforce the security boundaries described here
- [Incident Response](/blog/incident-response) -- What to do when a security boundary is breached or an agent misbehaves
- [Agent Hierarchy](/docs/architecture/agent-hierarchy) -- Trust levels and authority boundaries across the agent tree
