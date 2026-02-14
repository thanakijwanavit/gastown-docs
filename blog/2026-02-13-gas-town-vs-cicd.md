---
title: "Gas Town vs Traditional CI/CD: What's Different?"
description: "How Gas Town's agent-driven development model complements and extends traditional CI/CD pipelines rather than replacing them."
slug: gas-town-vs-cicd
authors: [gastown]
tags: [architecture, comparison, ci-cd, devops]
---

If you come from a DevOps background, Gas Town might look like a CI/CD system. It has pipelines (molecules), queues (merge queue), workers (polecats), and automated testing, as described in the [work distribution documentation](/docs/architecture/work-distribution). But the mental model is fundamentally different.

<!-- truncate -->

## The Key Difference

Traditional CI/CD operates on code that humans already wrote. Gas Town operates *before* code exists — it writes the code, then uses CI/CD to validate it.

```text
Traditional:  Human writes code → CI builds → CD deploys
Gas Town:     Human describes intent → Agent writes code → CI validates → Refinery merges
```

Gas Town doesn't replace your CI/CD pipeline. It sits upstream of it, generating the code that your existing pipeline validates.

## Where They Overlap

Both Gas Town and CI/CD share some concepts:

| Concept | CI/CD | Gas Town |
|---------|-------|----------|
| Work queue | Build queue | Merge queue (Refinery) |
| Workers | Build agents | Polecats |
| Pipeline | Build/test/deploy steps | Molecule steps |
| Triggers | Push/PR events | Sling/hook events |
| Artifacts | Build outputs | Git commits |

The Refinery's merge queue is the closest analog to a CI pipeline — it takes submitted work, rebases it, runs validation, and merges clean code. But the validation step typically *calls your existing CI* rather than reimplementing it.

:::note Gas Town Complements CI/CD — It Does Not Compete With It
The most common misconception is that Gas Town replaces your existing CI/CD infrastructure. In reality, Gas Town generates code and your CI validates it. Keep your GitHub Actions, Jenkins pipelines, and deployment scripts exactly as they are. Gas Town simply becomes the code producer feeding into the validation pipeline you already trust.
:::

## Where They Diverge

### 1. Authorship

CI/CD assumes a human authored the code. Gas Town's polecats are the authors. This changes everything about the review model:

- **CI/CD:** Automated checks validate human intent
- **Gas Town:** Automated checks validate agent output (the agent might have misunderstood the task)

:::warning Merge Conflicts Scale with Parallelism
Because Gas Town parallelizes across authorship — multiple agents writing code simultaneously — merge conflicts become more frequent than in human-paced development. The Refinery handles rebasing automatically, but if many polecats touch overlapping files, consider sequencing dependent beads with `bd dep add` rather than letting them run in parallel.
:::

### 2. Parallelism Model

CI/CD parallelizes across builds (multiple PRs building simultaneously). Gas Town parallelizes across *authorship* (multiple agents writing code simultaneously).

```text
CI/CD:     PR1 → build | PR2 → build | PR3 → build
Gas Town:  Bead1 → write+build | Bead2 → write+build | Bead3 → write+build
```

This means Gas Town has a conflict problem that CI/CD doesn't: multiple agents changing the same codebase simultaneously can create merge conflicts that don't exist in human-paced development.

### 3. Failure Recovery

When a CI build fails, a human investigates and fixes the code. When a Gas Town validation fails, the system can either:
- Retry with the same agent (maybe the test was flaky)
- Spawn a new agent with the error context
- Escalate to a human via the Mayor

This self-healing loop doesn't exist in traditional CI/CD.

### 4. Work Decomposition

CI/CD doesn't decompose work — it processes whatever gets pushed. Gas Town actively decomposes high-level requests into atomic units (beads) before any code is written. The Mayor does this decomposition, creating a plan before execution begins.

```mermaid
flowchart LR
    subgraph GT["Gas Town (Upstream)"]
        I[Intent] --> M[Mayor]
        M --> P[Polecats Write Code]
        P --> RF[Refinery]
    end
    subgraph CICD["Your CI/CD (Downstream)"]
        RF --> CI[CI Validates]
        CI --> CD[CD Deploys]
    end
```

## How They Work Together

The recommended setup uses Gas Town upstream of your existing CI/CD:

```text
1. Mayor decomposes request → beads
2. Polecats write code on branches
3. Polecats submit via gt done → merge queue
4. Refinery rebases onto main
5. YOUR CI runs (GitHub Actions, Jenkins, etc.)
6. If CI passes → Refinery merges to main
7. YOUR CD deploys (ArgoCD, Flux, etc.)
```

Gas Town plugs into step 5-6 of your existing pipeline. The Refinery can be configured to wait for your CI checks:

```bash
# Refinery waits for GitHub Actions CI to pass before merging
gt rig config myproject refinery.require_ci true
```

## What Gas Town Adds That CI/CD Can't

**Autonomous code generation.** CI/CD can't write code. Gas Town can take a high-level request and produce working, tested code without human involvement.

**Batch orchestration.** CI/CD processes individual PRs. Gas Town manages batches of related work (convoys) with dependency tracking and auto-close.

**Agent lifecycle management.** CI/CD doesn't manage the workers that produce code. Gas Town's Witness monitors polecat health, restarts stuck agents, and escalates failures. For details on agent monitoring, see [monitoring fleet](/blog/monitoring-fleet). The [work distribution patterns](/docs/architecture/work-distribution) explain how Gas Town orchestrates agents upstream of CI.

**Intent-level tracking.** CI/CD tracks commits and builds. Gas Town tracks beads (intent) through the entire lifecycle from idea to merged code.

```mermaid
flowchart TD
    subgraph "Traditional CI/CD Scope"
        HC[Human Codes] --> PR[Pull Request]
        PR --> BLD[Build]
        BLD --> TST[Test]
        TST --> DPL[Deploy]
    end
    subgraph "Gas Town Extended Scope"
        INT[Human Intent] --> MAY[Mayor Decomposes]
        MAY --> BD[Beads Created]
        BD --> PC[Polecats Code]
        PC --> RF[Refinery]
        RF --> CICD[Your CI/CD]
        CICD --> PROD[Production]
    end
    style "Gas Town Extended Scope" fill:#e1f5e1
    style "Traditional CI/CD Scope" fill:#fff3cd
```

:::tip Keep Your Existing CI Pipeline as the Quality Gate
Rather than duplicating test logic in Gas Town, configure the Refinery to call your existing CI system with `refinery.require_ci`. This way, your established quality gates remain the single source of truth for what merges to main, and Gas Town simply feeds work into the pipeline you already trust.
:::

```mermaid
stateDiagram-v2
    [*] --> Intent: Human describes goal
    Intent --> Beads: Mayor decomposes
    Beads --> Code: Polecats implement
    Code --> Validated: Your CI runs tests
    Validated --> Merged: Refinery merges
    Merged --> Deployed: Your CD deploys
    Merged --> [*]
    Code --> FixLoop: CI fails
    FixLoop --> Code: Agent retries or respawns
```

:::info Gas Town Does Not Replace Your Deployment Pipeline
A common misconception is that Gas Town handles deployment. It does not. Gas Town's scope ends at merging validated code to main. Your existing CD system (ArgoCD, Flux, GitHub Actions deploy steps) continues to own the production deployment pipeline. Gas Town is a code generation and merge layer, not a deployment orchestrator.
:::

:::caution Gas Town Generates More CI Load Than Human Developers
Because agents work faster and in parallel, your CI system will see 5-10x the number of builds it is used to handling. If your CI has capacity limits or per-build costs, budget accordingly. The Refinery can be configured to batch merges or throttle submission rate, but the default behavior is to push every completed polecat branch through CI immediately, which can overwhelm under-provisioned build infrastructure.
:::

The following diagram shows how build volume scales with parallel agents.

```mermaid
pie title CI Build Volume Comparison
    "Human Dev (1-2 PRs/day)" : 2
    "Stage 6 (Single Agent, 5-8 PRs/day)" : 8
    "Stage 7 (3 Parallel Agents, 15-24 PRs/day)" : 24
    "Stage 8 (10 Parallel Agents, 50-80 PRs/day)" : 80
```

## When to Use What

| Scenario | Tool |
|----------|------|
| Validate code quality | Your CI (unchanged) |
| Deploy to production | Your CD (unchanged) |
| Write new features | Gas Town polecats |
| Manage parallel development | Gas Town convoys |
| Monitor agent health | Gas Town Witness |
| Merge safely at scale | Gas Town Refinery + your CI |

```mermaid
sequenceDiagram
    participant MY as Mayor
    participant PC as Polecats
    participant RF as Refinery
    participant CI as Your CI/CD
    participant PR as Production
    MY->>PC: Decompose + Sling
    PC->>RF: gt done (submit MR)
    RF->>CI: Push rebased branch
    CI->>RF: Pass/Fail
    RF->>RF: Merge to main
    CI->>PR: Deploy (your CD)
```

```mermaid
graph LR
    subgraph CICD_Only["Traditional CI/CD"]
        HC[Human Codes] --> PR[Pull Request]
        PR --> BLD[Build]
        BLD --> TST[Test]
        TST --> DPL[Deploy]
    end
    subgraph GT_Plus_CICD["Gas Town + CI/CD"]
        INT[Human Intent] --> MAY[Mayor]
        MAY --> PCS[Polecats Code]
        PCS --> REF[Refinery]
        REF --> CI2[Your CI]
        CI2 --> CD2[Your CD]
    end
```

## The Bottom Line

Gas Town is not CI/CD 2.0. It's the layer that generates the code your CI/CD validates. Think of it as "AI-driven development management" that happens to interface with your existing automation. The security implications of this upstream integration are discussed in the [security model](/blog/security-model), which explains how Gas Town maintains trust boundaries even when generating code at CI/CD scale.

If your CI/CD pipeline works well, keep it. Gas Town will feed it better, faster, and in higher volume.

:::note Integration is the default
Gas Town was designed from day one to complement existing CI/CD, not replace it. The `refinery.require_ci` config flag is the bridge — it tells the Refinery to wait for your CI checks before merging. This means your existing quality gates remain fully in control of what lands on main.
:::

## Next Steps

- **[Architecture Overview](/docs/architecture/overview)** — How Gas Town's components fit together
- **[Refinery](/docs/agents/refinery)** — The merge queue that interfaces with your CI
- **[Convoys](/docs/concepts/convoys)** — Batch tracking for parallel work
- **[Quick Start](/docs/getting-started/quickstart)** — Get started in 10 minutes
- **[The Refinery Deep Dive](/blog/refinery-deep-dive)** — How the Refinery merge queue replaces CI/CD
- **[Work Distribution Patterns](/blog/work-distribution-patterns)** — Work distribution that goes beyond traditional CI/CD
- **[Understanding GUPP](/blog/understanding-gupp)** — The crash-recovery model that makes Gas Town different from CI/CD
- **[Molecules and Formulas](/blog/molecules-and-formulas)** — How Gas Town's workflow engine replaces traditional CI/CD pipeline definitions
- [Architecture Guide](/docs/guides/architecture) — Comprehensive visual guide to Gas Town's architecture
- [Design Principles](/docs/architecture/design-principles) — Core principles that differentiate Gas Town from traditional CI/CD
- **[Cost Optimization Strategies](/blog/cost-optimization)** — Managing token costs when running parallel agents at CI/CD scale
