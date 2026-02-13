---
title: "gt seance"
sidebar_position: 15
description: "Talk to predecessor sessions. Discover recent sessions and ask questions about decisions, progress, and context from previous work."
---

# gt seance

Talk to predecessor sessions to recover context and understand decisions.

```bash
gt seance [flags]
```

## Description

Seance lets you talk to predecessor sessions directly. Instead of parsing logs, it spawns a Claude subprocess that resumes a previous session with full context. You can ask questions like:

- "Why did you make this decision?"
- "Where were you stuck?"
- "What did you try that didn't work?"

This solves the #1 handoff question: "Where did you put the stuff you left for me?"

## Session Discovery

List recent sessions discovered from events emitted by SessionStart hooks (`~/gt/.events.jsonl`).

```bash
gt seance                     # List recent sessions
gt seance --role crew         # Filter by role type
gt seance --rig gastown       # Filter by rig
gt seance --recent 10         # Last N sessions
```

## Talking to a Predecessor

The `--talk` flag spawns `claude --fork-session --resume <id>`, loading the predecessor's full context without modifying their session.

```bash
gt seance --talk <session-id>              # Interactive conversation
gt seance --talk <session-id> -p "Where is X?"   # One-shot question
```

## Flags

| Flag | Short | Description |
|------|-------|-------------|
| `--talk <id>` | `-t` | Session ID to commune with |
| `--prompt <text>` | `-p` | One-shot prompt (requires `--talk`) |
| `--recent <n>` | `-n` | Number of recent sessions to show (default: 20) |
| `--rig <name>` | | Filter by rig name |
| `--role <type>` | | Filter by role (crew, polecat, witness, etc.) |
| `--json` | | Output as JSON |

## Examples

```bash
# Discover recent sessions
gt seance
gt seance --rig myproject --role polecat

# Ask a one-shot question to a predecessor
gt seance --talk sess-abc123 -p "What was the root cause of the auth bug?"

# Start an interactive conversation with a predecessor
gt seance --talk sess-abc123
```

:::tip

Sessions are discovered from events emitted by SessionStart hooks. The `[GAS TOWN]` beacon in each session makes them searchable via `/resume`.

:::
