---
title: "Guides"
sidebar_position: 0
description: "In-depth guides for using Gas Town effectively: usage patterns, architecture, cost management, multi-runtime support, and design philosophy."
---

# Guides

This section provides in-depth guides for using Gas Town effectively, understanding its design philosophy, and getting the most out of multi-agent AI development.

---

## Sections

| Guide | Description |
|-------|-------------|
| [Usage Guide](usage-guide.md) | Comprehensive walkthrough for day-to-day Gas Town usage |
| [The 8 Stages of AI Coding](eight-stages.md) | Understanding where Gas Town fits in the AI coding maturity model |
| [Multi-Runtime Support](multi-runtime.md) | Using Gas Town with Claude, Gemini, Codex, Cursor, and more |
| [Cost Management](cost-management.md) | Monitoring and optimizing token spend |
| [Background & Philosophy](philosophy.md) | Why Gas Town exists, its history, and design philosophy |
| [Architecture Guide](architecture.md) | Comprehensive tour of Gas Town's multi-agent architecture |
| [Troubleshooting](troubleshooting.md) | Solutions for common Gas Town problems and workarounds |
| [Glossary](glossary.md) | Complete terminology reference for all Gas Town concepts |

## Who Are These Guides For?

Gas Town is a power tool. These guides assume you are:

- Comfortable with the command line and git
- Already using AI coding agents (Claude Code, Gemini CLI, Codex, etc.)
- Ready to coordinate **multiple** agents working in parallel
- Willing to invest time learning a new operational model

If you are new to AI-assisted coding, start with a single agent (Stage 5-6 in the [8 Stages model](eight-stages.md)) before adopting Gas Town.

## Learning Paths by Role

Different roles need different guides. Find your starting point:

### Developer (writing code with Gas Town)

1. **[The 8 Stages of AI Coding](eight-stages.md)** — Understand where you are on the maturity curve
2. **[Usage Guide](usage-guide.md)** — Day-to-day workflows: slinging work, monitoring polecats, reviewing output
3. **[Multi-Runtime Support](multi-runtime.md)** — If you use Gemini, Codex, or Cursor alongside Claude

### Operator (running Gas Town in production)

1. **[Architecture Guide](architecture.md)** — How agents, rigs, and supervision fit together
2. **[Usage Guide](usage-guide.md)** — Core commands and operational patterns
3. **[Cost Management](cost-management.md)** — Token budgets, model tiers, and cost alerts
4. **[Troubleshooting](troubleshooting.md)** — Diagnosis and recovery for common failures

### Evaluator (deciding whether to adopt Gas Town)

1. **[The 8 Stages of AI Coding](eight-stages.md)** — Is your team ready for multi-agent orchestration?
2. **[Background & Philosophy](philosophy.md)** — Why Gas Town exists and the design thinking behind it
3. **[Architecture Guide](architecture.md)** — Technical overview of the system

## Reading Order

For new Gas Town users, we recommend this sequential reading order:

1. **[The 8 Stages of AI Coding](eight-stages.md)** -- Understand where Gas Town fits and whether you are ready for it
2. **[Background & Philosophy](philosophy.md)** -- Understand why Gas Town exists and the mental model behind it
3. **[Architecture Guide](architecture.md)** -- Understand how the agents, rigs, and pipelines fit together
4. **[Usage Guide](usage-guide.md)** -- Learn the day-to-day workflows and commands
5. **[Multi-Runtime Support](multi-runtime.md)** -- If you use agents other than Claude Code
6. **[Cost Management](cost-management.md)** -- Essential for anyone running at scale

:::tip[Already Running Gas Town?]

If you have completed the [Getting Started](../getting-started/index.md) guide and have a working installation, jump straight to the [Usage Guide](usage-guide.md) for practical workflows and patterns.

:::

## From the Blog

- [Cost Tracking and Optimization](/blog/cost-optimization) -- Practical strategies for managing token spend at scale
- [Multi-Runtime Workflows](/blog/multi-runtime-workflows) -- Using Gas Town with Claude, Gemini, Codex, and more
- [What Stage Are You?](/blog/eight-stages-self-assessment) -- Self-assessment for AI coding maturity
- [5 Common Pitfalls When Starting](/blog/common-pitfalls) -- Mistakes to avoid as a new Gas Town user

## Related

- **[Getting Started](../getting-started/index.md)** — Installation and first steps
- **[Core Concepts](../concepts/index.md)** — The primitives that power Gas Town
- **[Operations](../operations/index.md)** — Running and monitoring the system in production
- **[CLI Reference](../cli-reference/index.md)** — Complete command reference