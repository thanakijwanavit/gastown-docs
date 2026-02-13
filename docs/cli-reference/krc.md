---
title: "gt krc"
sidebar_position: 20
description: "Key Record Chronicle — TTL-based lifecycle management for ephemeral operational data like patrol heartbeats and status checks."
---

# gt krc

Key Record Chronicle (KRC) manages TTL-based lifecycle for ephemeral data.

Operational data like patrol heartbeats, status checks, and health reports decays in forensic value over time. KRC provides configurable TTLs to automatically prune expired events, keeping the beads database lean.

## Commands

### `gt krc stats`

Show statistics about ephemeral data — counts by event type, age distribution, storage usage.

```bash
gt krc stats              # Human-readable summary
gt krc stats --json       # Machine-readable output
```

**Options:**

| Flag | Description |
|------|-------------|
| `--json` | Output in JSON format |

### `gt krc prune`

Remove expired events based on configured TTLs. Events are removed from both `.events.jsonl` and `.feed.jsonl`. The operation is atomic (uses temp files and rename).

```bash
gt krc prune              # Remove expired events
gt krc prune --dry-run    # Preview what would be pruned (no changes)
gt krc prune --auto       # Daemon mode: only prune if PruneInterval has elapsed
```

**Options:**

| Flag | Description |
|------|-------------|
| `--dry-run` | Preview changes without modifying files |
| `--auto` | Daemon mode: only prune if PruneInterval has elapsed since last run |

### `gt krc decay`

Show forensic value decay report — visualize how data value decreases over time.

```bash
gt krc decay              # Human-readable decay report
gt krc decay --json       # Machine-readable output
```

Each event type follows one of four decay curves:

| Curve | Behavior | Typical Events |
|-------|----------|---------------|
| `rapid` | Value drops quickly | Heartbeats, pings |
| `steady` | Linear decay over time | Session events, patrol cycles |
| `slow` | Value persists longer | Errors, escalations |
| `flat` | Full value until near TTL | Audit events, death warrants |

Events with low forensic scores are candidates for aggressive pruning.

**Options:**

| Flag | Description |
|------|-------------|
| `--json` | Output in JSON format |

### `gt krc config`

View or modify TTL configuration for event types.

```bash
gt krc config                      # Show current TTL settings
gt krc config set patrol_* 12h     # Set TTL for patrol events to 12 hours
gt krc config set heartbeat_* 6h   # Set TTL for heartbeat events to 6 hours
gt krc config set default 3d       # Set default TTL to 3 days
gt krc config reset                # Reset to default configuration
```

**Subcommands:**

| Subcommand | Description |
|------------|-------------|
| `set <pattern> <ttl>` | Set TTL for event type matching glob pattern |
| `reset` | Reset all TTLs to default values |

TTL durations use Go-style shorthand: `6h` (hours), `3d` (days), `1w` (weeks).

### `gt krc auto-prune-status`

Show the auto-prune scheduling state — whether automatic pruning is active and when it last ran.

```bash
gt krc auto-prune-status
```

## Data Levels

KRC manages **Level 0** (ephemeral) data as defined in the Dolt storage design:

| Level | Examples | Default TTL | Forensic Value |
|-------|----------|-------------|----------------|
| 0 (Ephemeral) | Patrol heartbeats, status checks, health pings | Hours | Decays rapidly |
| 1 (Operational) | Work assignments, progress updates | Days-weeks | Moderate |
| 2 (Archival) | Completed beads, audit trails | Permanent | High |

KRC only manages Level 0. Higher levels are managed by Dolt directly.

## How Auto-Pruning Works

When configured, KRC can run pruning automatically at a set interval:

1. **PruneInterval** defines how often pruning runs (e.g., every 6 hours)
2. The Deacon's patrol cycle triggers `gt krc prune --auto`
3. The `--auto` flag checks whether the interval has elapsed since the last prune
4. If the interval has passed, expired events are pruned atomically
5. Use `gt krc auto-prune-status` to verify the schedule is active

This keeps the beads database lean without manual intervention.

## Relationship to Patrol

Patrol agents are the primary producers of Level 0 data. Each 5-minute patrol cycle generates heartbeats, status checks, and health reports. Without KRC pruning, this data accumulates rapidly — hundreds of events per day per rig.

The typical flow:

```
Patrol agents → generate ephemeral events → KRC prunes expired → gt patrol digest aggregates
```

Use `gt krc stats` to monitor accumulation rates and tune TTLs accordingly.

## See Also

- [gt patrol](patrol.md) — Patrol digest aggregation
- [gt dolt](dolt.md) — Dolt SQL server management
- [Patrol Cycles](../concepts/patrol-cycles.md) — The patrol monitoring pattern
- [Monitoring](../operations/monitoring.md) — Operational monitoring patterns
