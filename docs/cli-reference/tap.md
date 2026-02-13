---
title: "gt tap"
sidebar_position: 20
description: "Hook handlers for Claude Code PreToolUse and PostToolUse events. Implements policy guards, auditing, and input transformation."
---

# gt tap

Hook handlers for Claude Code PreToolUse and PostToolUse events.

```bash
gt tap [command]
```

## Description

Tap commands are called by Claude Code hooks to implement policies, auditing, and input transformation. They tap into the tool execution flow to guard, audit, inject, or check.

The tap system uses Claude Code's hook mechanism to intercept tool calls at two points:

- **PreToolUse** — Before a tool executes (can block or modify input)
- **PostToolUse** — After a tool executes (can log or validate output)

| Handler | Hook Type | Purpose | Status |
|---------|-----------|---------|--------|
| `guard` | PreToolUse | Block forbidden operations (exit 2) | Available |
| `audit` | PostToolUse | Log/record tool executions | Planned |
| `inject` | PreToolUse | Modify tool inputs (updatedInput) | Planned |
| `check` | PostToolUse | Validate after execution | Planned |

## Subcommands

| Command | Description |
|---------|-------------|
| [`guard`](#gt-tap-guard) | Block forbidden operations (PreToolUse hook) |

---

## gt tap guard

Block forbidden operations via Claude Code PreToolUse hooks.

```bash
gt tap guard [command]
```

Guard commands exit with code 2 to BLOCK tool execution when a policy is violated. They're called before the tool runs, preventing the forbidden operation entirely.

### Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Operation allowed (not in Gas Town agent context) |
| `2` | Operation **BLOCKED** (policy violation in agent context) |

Guards only activate when running as a Gas Town agent (crew, polecat, witness, etc.). Humans running outside Gas Town are unaffected.

### Available Guards

| Guard | Description |
|-------|-------------|
| [`pr-workflow`](#gt-tap-guard-pr-workflow) | Block PR creation and feature branches |

---

### gt tap guard pr-workflow

Block PR workflow operations in Gas Town.

```bash
gt tap guard pr-workflow
```

Gas Town workers push directly to main. PRs add friction that breaks the autonomous execution model ([GUPP principle](../concepts/gupp.md)). This guard enforces that pattern by blocking:

- `gh pr create` — PR creation
- `git checkout -b` — Feature branch creation
- `git switch -c` — Feature branch creation

### Hook Configuration

Configure in `.claude/settings.local.json`:

```json
{
  "PreToolUse": [{
    "matcher": "Bash(gh pr create*)",
    "hooks": [{"command": "gt tap guard pr-workflow"}]
  }]
}
```

### Examples

```bash
# Test the guard directly (returns exit code 2 if in agent context)
gt tap guard pr-workflow

# Example: agent tries to create a PR
# Hook intercepts: gt tap guard pr-workflow → exits 2 → tool call BLOCKED
```

:::tip

See the [Operations Guide](../operations/troubleshooting.md) and [Lifecycle Management](../operations/lifecycle.md) for more on how hooks integrate with the Gas Town agent lifecycle.

:::

## Related

- [Git Workflow Guide](../guides/git-workflow.md) -- Why Gas Town uses direct-to-main instead of PRs
- [GUPP (Propulsion Principle)](../concepts/gupp.md) -- The autonomous execution model that tap guards enforce
