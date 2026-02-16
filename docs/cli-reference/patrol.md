---
title: "gt patrol"
sidebar_position: 19
description: "Manage patrol cycle digests — aggregate ephemeral per-cycle data into daily summaries."
---

# gt patrol

Manage patrol cycle digests.

Patrol cycles ([Deacon](../agents/deacon.md), [Witness](../agents/witness.md), [Refinery](../agents/refinery.md)) create ephemeral per-cycle digests to avoid JSONL pollution. This command aggregates them into concise daily summaries.

## Commands

### `gt patrol digest`

Aggregate patrol cycle digests into a daily summary bead.

```bash
gt patrol digest              # Aggregate today's patrol digests
gt patrol digest --yesterday  # Aggregate yesterday's patrol digests
gt patrol digest --dry-run    # Preview what would be aggregated
```

**Options:**

| Flag | Description |
|------|-------------|
| `--yesterday` | Aggregate yesterday's digests instead of today's |
| `--dry-run` | Preview what would be aggregated without writing |
| `--agent <type>` | Filter to a specific agent type (witness, refinery, deacon) |
| `--rig <name>` | Filter to a specific rig |

**Examples:**

```bash
# Aggregate all of today's patrol data
gt patrol digest

# See what a specific Witness reported
gt patrol digest --agent witness --rig myproject

# Preview without writing
gt patrol digest --dry-run

# Aggregate yesterday's data (useful for morning reviews)
gt patrol digest --yesterday
```

### `gt patrol start`

Request a fresh patrol cycle from all patrol agents.

```bash
gt patrol start               # Trigger patrol across all agents
gt patrol start --rig myapp   # Trigger patrol for a specific rig
```

This nudges patrol agents to run their check cycle immediately rather than waiting for the next scheduled tick.

:::tip
Use `gt patrol digest --dry-run` during morning reviews to see what happened overnight without writing any changes. This gives you a quick health overview before committing to aggregation.
:::

## What Are Patrol Cycles?

Patrol is the core monitoring pattern in Gas Town. Three agent types run continuous [patrol molecules](../concepts/patrol-cycles.md):

| Agent | Interval | Patrol Focus |
|-------|----------|-------------|
| **[Witness](../agents/witness.md)** | 5 min | Monitors polecats — checks health, detects stalls, cleans up zombies |
| **[Refinery](../agents/refinery.md)** | 5 min | Monitors merge queue — processes MRs, rebases, merges to main |
| **[Deacon](../agents/deacon.md)** | 5 min | Monitors all agents — checks Witnesses, handles escalations, files death warrants |

Each patrol cycle generates ephemeral data (heartbeats, status checks, health reports). Without aggregation, this data accumulates rapidly. `gt patrol digest` compresses it into concise daily summaries.

## How Digest Aggregation Works

```text
Per-cycle data:
  witness-patrol-14:00 → "3 polecats healthy, 0 stalled"
  witness-patrol-14:05 → "3 polecats healthy, 1 nudged"
  witness-patrol-14:10 → "2 polecats healthy, 1 escalated"
  ...

After gt patrol digest:
  patrol-daily-2026-02-13 → "Witness: 288 cycles, 285 healthy, 2 nudged, 1 escalated"
```

The per-cycle ephemeral data is removed after aggregation, keeping the beads database clean while preserving the audit trail.

:::warning
Running `gt patrol digest` deletes the per-cycle ephemeral data after aggregation. If you need to preserve raw per-cycle data for debugging, use `--dry-run` first to inspect it before aggregating.
:::

## When to Run Digests

- **Automatically**: The Deacon can be configured to run digests at end of day
- **Manually**: Run `gt patrol digest` during morning reviews
- **On demand**: Use `--dry-run` to check patrol health without writing

## See Also

- **[Patrol Cycles](../concepts/patrol-cycles.md)** -- Deep dive on the patrol pattern and discovery over tracking
- **[Monitoring](../operations/monitoring.md)** -- Operational monitoring patterns
- **[gt krc](krc.md)** -- TTL-based lifecycle for ephemeral patrol data
- **[Witness](../agents/witness.md)** -- Per-rig patrol agent
- **[Deacon](../agents/deacon.md)** -- Town-wide health coordinator
- **[Diagnostics](diagnostics.md)** -- Other diagnostic and observability commands
