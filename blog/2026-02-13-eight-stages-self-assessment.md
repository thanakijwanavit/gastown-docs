---
title: "What Stage Are You? A Self-Assessment for AI Coding Maturity"
description: "Find out where you fall on the 8 Stages of AI Coding maturity model and get practical advice for leveling up to multi-agent orchestration."
slug: eight-stages-self-assessment
authors: [gastown]
tags: [getting-started, philosophy, ai-coding, maturity]
---

Gas Town targets developers at Stage 7 and above on the AI coding maturity model, as outlined in the [first convoy guide](/docs/getting-started/first-convoy). But most developers are still at Stage 4 or 5. Here's how to figure out where you are and what it takes to level up.

<!-- truncate -->

## The Quick Assessment

Answer honestly. Which statement best describes your daily workflow?

**Stage 1-2: Manual or Completions**
- "I write all my code by hand" → Stage 1
- "I use Copilot/Codeium for tab-complete" → Stage 2

**Stage 3-4: Chat or Agents**
- "I ask ChatGPT/Claude questions while coding" → Stage 3
- "I use Cursor/Claude Code to write whole functions" → Stage 4

**Stage 5-6: Deep Agent Use**
- "I let agents make multi-file changes with review" → Stage 5
- "I trust agents to implement features end-to-end" → Stage 6

**Stage 7-8: Orchestration**
- "I run multiple agents on different tasks simultaneously" → Stage 7
- "I manage agents with other agents (like Gas Town)" → Stage 8

Most developers reading this blog are probably at Stage 4-6. That's fine — Gas Town will make more sense once you understand the progression. For those just starting their multi-agent journey, the [crew workflow](/blog/crew-workflow) offers a practical introduction to coordinating parallel development.

```mermaid
flowchart LR
    S1["1: Manual"] --> S2["2: Completions"]
    S2 --> S3["3: Chat"]
    S3 --> S4["4: Agent Edits"]
    S4 --> S5["5: Multi-File"]
    S5 --> S6["6: Intent-Level"]
    S6 --> S7["7: Parallel Agents"]
    S7 --> S8["8: Agents Managing Agents"]
    style S7 fill:#ff9,stroke:#333
    style S8 fill:#9f9,stroke:#333
```

## What Each Stage Transition Feels Like

### Stage 2 → 3: "I Can Ask Questions"

The shift from completions to chat feels like getting a knowledgeable coworker. Instead of guessing at APIs, you ask. Instead of reading docs for 20 minutes, you get an answer in 10 seconds.

**What changes:** Your browser has fewer Stack Overflow tabs open.

### Stage 3 → 4: "The Agent Can Edit My Code"

This is where most people get stuck. Giving an AI agent permission to modify your files feels uncomfortable. You worry about it breaking things. You review every change line by line.

**What changes:** You stop copy-pasting from chat and start approving diffs.

**How to get past it:** Start with low-risk files. Let the agent write tests, update documentation, or refactor small functions. Build trust incrementally.

:::tip Build Trust Incrementally
The biggest blocker to advancing through the stages is fear, not capability. Start by letting agents handle low-risk tasks (tests, docs, formatting) where mistakes are cheap to fix. As you see consistent quality, gradually give agents higher-stakes work. Each successful delegation builds the confidence needed for the next stage. For more on building this foundation, see [work distribution patterns](/blog/work-distribution-patterns).
:::

### Stage 4 → 5: "I Trust Multi-File Changes"

At Stage 4, you use agents for single-function or single-file tasks. Stage 5 means trusting the agent to make coordinated changes across multiple files — adding a new API endpoint means the agent updates the handler, the router, the tests, and the docs.

**What changes:** You review by intent ("did it add the endpoint correctly?") instead of by diff ("what did it change in each file?").

### Stage 5 → 6: "I Describe What, Not How"

Stage 5 still involves directing the agent step by step. Stage 6 means describing the outcome and letting the agent figure out the implementation path.

**Stage 5:** "Add a `validateEmail` function in `utils.go`, then call it from `CreateUser` in `handlers.go`, then add a test case in `handlers_test.go`."

**Stage 6:** "Add email validation to the user creation flow."

**What changes:** Your prompts get shorter and higher-level.

### Stage 6 → 7: "Multiple Agents in Parallel"

This is the Gas Town entry point. Instead of one agent doing one task while you wait, you spawn multiple agents working on different tasks simultaneously.

```mermaid
sequenceDiagram
    participant D as Developer
    participant A1 as Agent 1
    participant A2 as Agent 2
    participant A3 as Agent 3
    participant M as Main Branch
    D->>A1: Task: Add validation
    D->>A2: Task: Write tests
    D->>A3: Task: Update docs
    A1->>M: Merge validation
    A2->>M: Merge tests
    A3->>M: Merge docs
    Note over D,M: 3x throughput vs serial
```

**What changes:** You go from "one agent, one task, wait, review" to "five agents, five tasks, monitor, merge." Your throughput jumps dramatically.

:::caution The Stage 6 to 7 Transition Requires a Complete Workflow Overhaul
Moving from intent-level development to parallel orchestration is not just a tooling change — it requires restructuring your entire code review process, test infrastructure, and git workflow. Most teams underestimate this transition and try to run parallel agents with Stage 5 practices, resulting in merge conflicts and quality issues. Budget 2-4 weeks to establish the foundation before scaling up.
:::

**Prerequisites:**
- Good test coverage (agents need automated validation)
- Clean git workflow (parallel agents need clean merge paths)
- Comfort with agent autonomy (you can't review every line from 5 agents)

### Stage 7 → 8: "Agents Managing Agents"

Stage 8 is where Gas Town operates. The Mayor decomposes high-level requests into beads. Polecats execute autonomously. The Witness monitors health. The Refinery merges code. The Deacon manages infrastructure. You operate at the level of intent. See the [architecture overview](/docs/architecture/overview) for how these agents fit together.

**What changes:** You stop thinking about code and start thinking about outcomes.

:::note Your Stage May Vary by Project
Most developers operate at different stages across different codebases. You might be at Stage 6 on a well-tested personal project but only Stage 4 on a legacy codebase with no tests. Assess your stage per-project rather than globally, and focus on leveling up the projects that would benefit most from parallel agent work.
:::

## Common Fears at Each Stage

| Stage Transition | Fear | Reality |
|-----------------|------|---------|
| 3 → 4 | "It'll break my code" | Version control exists; undo is one command |
| 4 → 5 | "I can't review all those changes" | You review intent, not diffs |
| 5 → 6 | "It won't understand what I want" | Better prompts come from practice |
| 6 → 7 | "I'll lose track of parallel work" | That's what convoys are for |
| 7 → 8 | "I'm giving up too much control" | You're trading control for leverage |

```mermaid
gantt
    title AI Coding Maturity Progression Timeline
    dateFormat YYYY-MM
    section Learning Phase
    Stage 1-2: Manual/Completions    :2024-01, 6M
    Stage 3: Chat Assistance          :2024-04, 4M
    section Building Trust
    Stage 4: Agent Edits              :2024-08, 6M
    Stage 5: Multi-File Changes       :2025-02, 4M
    section Intent Level
    Stage 6: Intent-Based Dev         :2025-06, 6M
    section Orchestration
    Stage 7: Parallel Agents          :2025-12, 3M
    Stage 8: Agents Managing Agents   :2026-03, 3M
```

:::danger Stage 7 Without Test Coverage Is a Recipe for Chaos
Running multiple agents in parallel without comprehensive test coverage means you won't catch bad code until it is already on main and breaking downstream work. The automation that makes Stage 7 powerful — agents merging code with minimal review — becomes your biggest liability when tests are missing. If your codebase does not have 70%+ test coverage, stay at Stage 6 until you can build that foundation.
:::

## The Stage 7 Starter Kit

If you're at Stage 5-6 and want to try Gas Town, here's a minimal setup:

```bash
# Install Gas Town
gt install
gt init

# Set up your first rig
gt rig add myproject --repo <your-repo-url>

# Create your first bead
bd create --title "Add input validation to /api/users" --type task --priority 1

# Sling it — your first autonomous agent
gt sling <bead-id> myproject
```

Watch what happens. The polecat will:
1. Read the bead description
2. Understand the task
3. Create a branch
4. Implement the change
5. Run tests
6. Submit for merge

If it works on the first try, congratulations — you just moved to Stage 7.

```mermaid
flowchart TD
    subgraph S7Kit["Stage 7 Starter Kit"]
        INS[gt install + gt init] --> RIG[gt rig add]
        RIG --> BD[bd create bead]
        BD --> SL[gt sling]
        SL --> PC[Polecat Executes]
        PC --> MG[Code on Main]
    end
```

:::warning Don't Skip Stages
Each stage builds skills and trust that the next stage depends on. Jumping from Stage 4 directly to Stage 8 typically results in expensive failures -- agents produce low-quality code because you haven't developed the instinct for writing precise task descriptions, and you lack the monitoring habits to catch problems early. Progress through each stage deliberately, even if it feels slow. For more on measuring your readiness, see the [FAQ](/docs/getting-started/faq).
:::

The following diagram shows typical adoption timelines for each stage transition.

```mermaid
graph LR
    subgraph Trust["Trust Building Stages"]
        S1[Stage 1-3<br/>Manual to Chat<br/>~6 months] --> S2[Stage 4-5<br/>Agent Edits<br/>~6 months]
    end
    subgraph Intent["Intent-Level Stages"]
        S2 --> S3[Stage 6<br/>Intent-Based<br/>~4 months]
    end
    subgraph Orchestration["Orchestration Stages"]
        S3 --> S4[Stage 7<br/>Parallel<br/>~3 months]
        S4 --> S5[Stage 8<br/>Agents Managing Agents<br/>~3 months]
    end
    style S4 fill:#ffcc99
    style S5 fill:#99ff99
```

:::info Stage 7 Is the Real Turning Point
The jump from Stage 6 to Stage 7 is the most impactful transition in the entire maturity model. Running even two agents in parallel fundamentally changes how you think about development -- you shift from "what should I build next" to "what should I assign next." This mental model shift is harder than any tooling change, and it is what separates casual AI users from orchestrators.
:::

```mermaid
pie title Developer Distribution by Stage (Estimated)
    "Stage 1-2: Manual/Completions" : 25
    "Stage 3: Chat" : 30
    "Stage 4: Agent Edits" : 25
    "Stage 5: Multi-File" : 12
    "Stage 6: Intent-Level" : 5
    "Stage 7-8: Orchestration" : 3
```

## The Honest Truth About Stage 8

Stage 8 is not for everyone. It requires:

- **High test coverage** — Agents need automated gates to validate their work
- **Clean architecture** — Poorly structured code confuses agents, causing expensive retries
- **Tolerance for imperfection** — Agent code is good-enough code, not artisanal code
- **Trust in the system** — You have to let go of reviewing every commit

But for teams with well-tested codebases and a backlog of clearly-defined tasks, Stage 8 can deliver 10-50x throughput over Stage 6. That's not hyperbole — it's math: 10 agents working in parallel, each 2-5x as productive as manual coding.

## Next Steps

- **[The 8 Stages of AI Coding](/docs/guides/eight-stages)** — Full reference with detailed descriptions
- **[Quick Start](/docs/getting-started/quickstart)** — Get Gas Town running in 10 minutes
- **[Your First Convoy](/blog/first-convoy)** — Run your first parallel workflow
- **[Philosophy](/docs/guides/philosophy)** — The design thinking behind Gas Town
- **[Beads](/docs/concepts/beads)** — The AI-native task unit that powers agent work from Stage 7 onward
- **[Cheat Sheet](/docs/getting-started/cheat-sheet)** — Quick reference for common commands at every stage
- **[Common Pitfalls](/blog/common-pitfalls)** — Avoid the most frequent mistakes at every stage
- **[Understanding GUPP](/blog/understanding-gupp)** — The core principle that defines Stage 4+ maturity
- **[Why Beads?](/blog/why-beads)** — Understanding the task unit that powers every stage from 7 onward
- **[Scaling Beyond 30 Agents](/blog/scaling-beyond-30)** — Infrastructure and orchestration patterns for teams ready to operate at Stage 8
