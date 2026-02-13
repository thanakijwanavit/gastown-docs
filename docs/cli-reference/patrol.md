---
title: "gt patrol"
sidebar_position: 19
description: "Manage patrol cycle digests — aggregate ephemeral per-cycle data into daily summaries."
---

# gt patrol

Manage patrol cycle digests.

Patrol cycles (Deacon, Witness, Refinery) create ephemeral per-cycle digests to avoid JSONL pollution. This command aggregates them into daily summaries.

## Commands

### `gt patrol digest`

Aggregate patrol cycle digests into a daily summary bead.

```bash
gt patrol digest              # Aggregate today's patrol digests
gt patrol digest --yesterday  # Aggregate yesterday's patrol digests
gt patrol digest --dry-run    # Preview what would be aggregated
```

## What Are Patrol Cycles?

Patrol is the core monitoring pattern in Gas Town. Three agent types run continuous patrol molecules:

| Agent | Patrol Focus |
|-------|-------------|
| **Witness** | Monitors polecats — checks health, detects crashes, validates work |
| **Refinery** | Monitors merge queue — processes MRs, rebases, merges to main |
| **Deacon** | Monitors all agents — handles escalations, files death warrants |

Each patrol cycle generates ephemeral data (heartbeats, status checks, health reports). Without aggregation, this data accumulates rapidly. `gt patrol digest` compresses it into concise daily summaries.

## See Also

- [Monitoring](/docs/operations/monitoring) — Operational monitoring patterns
- [gt krc](/docs/cli-reference/krc) — TTL-based lifecycle for ephemeral patrol data
- [Witness](/docs/agents/witness) — Per-rig patrol agent
- [Deacon](/docs/agents/deacon) — Town-wide health coordinator
