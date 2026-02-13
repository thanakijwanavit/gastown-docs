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

### Available Guards

| Guard | Description |
|-------|-------------|
| `pr-workflow` | Block PR creation and feature branches |

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
gt tap guard pr-workflow
```

:::tip

See the [Operations Guide](../operations/troubleshooting.md) and [Lifecycle Management](../operations/lifecycle.md) for more on how hooks integrate with the Gas Town agent lifecycle.

:::
