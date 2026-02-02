---
title: "Background & Philosophy"
sidebar_position: 5
description: "Gas Town is not just a tool -- it is a thesis about the future of software development. This guide covers why Gas Town exists, how it evolved, the intellectu..."
---

# Background & Philosophy

Gas Town is not just a tool -- it is a thesis about the future of software development. This guide covers why Gas Town exists, how it evolved, the intellectual foundations behind its design, and the community response to its ideas.

---

## Why Gas Town Exists: The Inevitability Argument

Gas Town's creator, Steve Yegge, makes a straightforward argument: multi-agent AI orchestration is **inevitable**. The progression from code completions to chat to agents to orchestrators follows an exponential curve that has been consistent since 2023.

The argument:

1. AI coding capabilities improve exponentially
2. Each improvement enables a new "stage" of AI-assisted development
3. Competitive pressure forces adoption of each stage within 6-12 months
4. Multi-agent orchestration (Stage 8) is the next inevitable step after hand-managing many agents (Stage 7)

Therefore, someone needs to build the orchestration infrastructure. Gas Town is one such attempt.

:::note[Not a Prediction -- An Observation]

Yegge argues this is not a prediction about the future but an observation of an already-visible trend. The exponential curve has been running for three years. Extrapolating it forward is not speculation; it is pattern recognition.

:::

---

## Development History

Gas Town has gone through four major architectural revisions, each driven by hard-won lessons about what works and what does not in multi-agent coordination.

### v1: The Prototype

The first version was a collection of bash scripts managing Claude Code sessions in tmux. It proved the concept -- multiple agents could work in parallel on the same project -- but coordination was fragile and everything broke constantly.

**Lessons learned:**

- Agents need persistent state that survives crashes
- Manual coordination does not scale beyond 5 agents
- Merge conflicts are the #1 operational problem

### v2: Beads

The second version introduced **Beads**, the git-backed issue tracking system. This gave agents a shared, persistent record of work state. Beads became the coordination primitive -- instead of agents talking directly to each other, they communicated through shared work items.

**Lessons learned:**

- Shared state works, but agents need explicit communication too
- A merge queue is essential once you have more than 3 parallel workers
- Health monitoring cannot be an afterthought

### v3: Python

The third version rewrote the core in Python, adding the agent hierarchy (Mayor, Deacon, Witness), the Refinery merge queue, and the mail/nudge communication system. This was the first version that could reliably run 10+ agents.

**Lessons learned:**

- Python's GIL and process model created performance bottlenecks at scale
- The Erlang/OTP supervision pattern (implemented in Python) was the right model
- The system needed to be faster and more reliable for production use

### v4: Go (Current)

The current version is written in Go, providing:

- Fast daemon process with low overhead
- Native concurrency for lifecycle management
- Single binary distribution
- Sub-millisecond command response times

Go was chosen for operational characteristics, not language preference. The daemon needs to be fast, reliable, and simple. Go excels at all three.

---

## Mad Max Naming and Theming

Gas Town's naming comes from the Mad Max: Fury Road universe. The fictional Gas Town is an oil refinery citadel controlled by a warlord. The metaphor maps surprisingly well to a multi-agent orchestration system:

| Mad Max | Gas Town Concept |
|---------|------------------|
| **Gas Town** | The workspace -- the central hub of operations |
| **Mayor** | The coordinator who runs Gas Town |
| **Rigs** | War rigs -- the vehicles (projects) being managed |
| **Polecats** | The warriors who swing between vehicles on poles, performing quick raids |
| **Refinery** | Where crude output is processed into usable product (code is merged to main) |
| **Witness** | "Witness me!" -- the monitor who watches and validates |
| **Convoy** | A group of vehicles (tasks) traveling together |
| **Deacon** | A religious figure who keeps order -- the health monitor |

The alternative name "Gastown" (one word) references Vancouver B.C.'s historic Gastown district, a nod to the software industry's Pacific Northwest roots.

:::tip[Embracing the Theme]

The Mad Max theme is intentional. Managing 20 AI agents simultaneously is chaotic, high-stakes, and occasionally explosive. The theme sets appropriate expectations. If you want a calm, predictable development experience, Gas Town is not it.

:::

---

## Erlang/OTP Inspiration

Gas Town's architecture borrows directly from Erlang/OTP, the telecommunications platform known for extreme reliability (nine-nines uptime):

### Supervisor Trees

```
                      Daemon
                        |
                      Deacon
                     /      \
              Witness:A    Witness:B
              /    \          |
        Polecat  Polecat   Polecat
```

Each level monitors the level below it. When a child crashes, its supervisor decides what to do (restart, escalate, or ignore). This creates a self-healing system where individual agent failures do not cascade.

### Mailbox Pattern

Agents communicate through mailboxes -- asynchronous message queues. An agent can send mail to any other agent, and the recipient processes messages on its own schedule. This decouples agents temporally -- they do not need to be active simultaneously to communicate.

### "Let It Crash" Philosophy

Rather than writing defensive code to prevent every possible failure, Gas Town follows Erlang's "let it crash" philosophy:

- Polecats are expected to crash sometimes
- Witnesses detect the crash and handle recovery
- Work persists on hooks -- nothing is lost
- A fresh polecat can pick up where the crashed one left off

### Process Isolation

Each agent runs in its own session with its own state. A crash in one agent cannot corrupt another agent's state. This isolation is what makes Gas Town reliable at scale.

---

## Software Survival 3.0

Yegge's "Software Survival 3.0" thesis extends beyond coding tools to a broader claim about software itself:

### The Three Eras

| Era | Selection Pressure | Survivors |
|-----|-------------------|-----------|
| **1.0** (1960s-2000s) | Can you build it at all? | Teams with engineering capability |
| **2.0** (2000s-2020s) | Can you build it faster? | Teams with agile processes and tooling |
| **3.0** (2025+) | Can you build it with AI? | Teams that harness multi-agent AI |

### The Core Thesis

Software Survival 3.0 argues that **selection pressure on software teams will increasingly favor those who effectively use multi-agent AI**. Teams that resist or lag in adoption will be outcompeted, not because their code is worse, but because their velocity is lower.

This is not a moral argument ("you should use AI") but an evolutionary one ("teams that use AI ship faster, and shipping faster wins").

### Implications

- Solo developers with orchestrated AI can match the output of small teams
- Small teams with orchestrated AI can match the output of large teams
- Large teams that do not adopt AI orchestration will lose their advantage of scale
- The "10x developer" becomes the "100x developer" not through skill but through leverage

---

## Prediction Track Record

Yegge has publicly tracked his predictions about AI coding adoption:

### The Exponential Curve

| Year | Stage | Prediction | Outcome |
|------|-------|-----------|---------|
| 2023 | 1-2 | "Completions are just the beginning" | Correct -- chat and agents emerged within 12 months |
| 2024 | 3-4 | "IDE agents will go YOLO" | Correct -- Cursor, Windsurf, Cline all shipped autonomous modes |
| 2024 | 5 | "CLI agents will replace IDE agents for power users" | Correct -- Claude Code, Gemini CLI, Codex CLI all launched |
| 2025 | 6-7 | "Multi-agent is coming, hand-managed first" | Correct -- widespread adoption of 3-10 parallel agents |
| 2025-2026 | 8 | "Orchestration systems will emerge" | In progress -- Gas Town and competitors exist |

### Exponential Curve Intuition

```
     Capability
         ^
         |                                    *
         |                                *
         |                            *
         |                        *
         |                    *
         |                *
         |            *
         |        *
         |    *
         | *
         +---------------------------------> Time
         2023  2024  2025  2026  2027
```

The key insight: **exponential curves look flat at the beginning and vertical at the end**. Each stage seemed like a modest step when it arrived, but looking back, the cumulative progress is staggering.

From completions (early 2023) to multi-agent orchestration (2025-2026) took less than three years.

---

## "You Will Die"

One of the most polarizing aspects of Gas Town's documentation is its honest warning:

> "You will die."

This is not hyperbole. It means:

- **Your first installation will break.** Gas Town is complex software managing complex AI agents.
- **You will lose work** until you learn the landing-the-plane discipline.
- **You will burn money** before you learn to manage costs effectively.
- **You will spend hours debugging** agent coordination issues.
- **You will question whether this is worth it** approximately once per day.

The warning serves as a filter: if reading "you will die" makes you want to stop, Gas Town is not for you yet. Come back at Stage 7.

If reading it makes you want to figure out how to survive, you are the target audience.

:::warning[This is Real]

Gas Town is not a polished consumer product. It is an advanced tool for power users who are willing to invest significant time and money to get 10x throughput. The learning curve is steep, the costs are real, and the failure modes are creative. Approach it with eyes open.

:::

---

## Community Reception

Gas Town launched on GitHub and was covered on Hacker News, Reddit, and several AI development communities. The reception was characteristically divided.

### The "Concept Car" Camp

> "This is fascinating as a concept but too early for production. It's showing us what 2027 will look like."

Proponents in this camp see Gas Town as a proof of concept -- valuable for exploring what multi-agent orchestration could be, but not ready for daily use by most teams.

### The "How We Code in 2 Years" Camp

> "I've been building exactly this with bash scripts. Gas Town formalizes what Stage 7 users already do."

Proponents in this camp are already managing multiple agents and recognize Gas Town as the next logical step from their ad-hoc scripts.

### The Skeptics

> "Managing 20 AI agents is a solution looking for a problem. One good developer with one agent is fine."

Skeptics question whether the complexity of orchestration is justified by the throughput gains. This maps to historical skepticism about every new development paradigm.

### By the Numbers

As of 2025:

- **7.3k stars** on GitHub
- **600+ forks**
- Active development with regular releases
- Growing community of contributors

---

## Further Reading

The following articles by Steve Yegge provide the foundational thinking behind Gas Town:

- [Welcome to Gas Town](https://steve-yegge.medium.com/welcome-to-gas-town-4f25ee16dd04) -- Launch announcement and overview
- [Gas Town Emergency User Manual](https://steve-yegge.medium.com/gas-town-emergency-user-manual-cf0e4556d74b) -- Practical usage guide and operational patterns
- [Software Survival 3.0](https://steve-yegge.medium.com/software-survival-3-0-97a2a6255f7b) -- The broader thesis on AI's impact on software development
- [The 8 Stages of AI Coding](eight-stages.md) -- Maturity model for AI-assisted development
- [GitHub Repository](https://github.com/steveyegge/gastown) -- Source code and issue tracker
