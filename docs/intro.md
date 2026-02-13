---
title: Introduction
sidebar_label: Introduction
slug: /intro
---

# Introduction to Gas Town

Gas Town is a multi-agent orchestration system for AI coding agents. It coordinates fleets of workers — from a single agent to 20-30 concurrent polecats — all through the `gt` CLI.

## Where to Start

- **[Getting Started](./getting-started/index.md)** — Install Gas Town and run your first convoy
- **[Architecture Overview](./architecture/index.md)** — Understand how the system fits together
- **[Core Concepts](./concepts/index.md)** — Learn about beads, hooks, molecules, and convoys

## What Problem Does It Solve?

When you scale beyond a single AI coding agent, you hit coordination problems: agents overwrite each other's work, lose context on restart, and require manual supervision. Gas Town solves this with:

- **Git-backed persistence** — Work state survives crashes and restarts
- **Agent hierarchy** — Mayor, Witnesses, Polecats each have clear roles
- **Serialized merges** — The Refinery prevents merge chaos
- **Built-in monitoring** — Witnesses track health; the Deacon coordinates recovery

For the full documentation, see the [docs home](./index.md).
