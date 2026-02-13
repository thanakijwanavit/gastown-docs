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
gt krc stats
```

### `gt krc prune`

Remove expired events based on configured TTLs.

```bash
gt krc prune              # Remove expired events
gt krc prune --dry-run    # Preview what would be pruned (no changes)
```

### `gt krc decay`

Show forensic value decay report — visualize how data value decreases over time.

```bash
gt krc decay
```

### `gt krc config`

View or modify TTL configuration for event types.

```bash
gt krc config                      # Show current TTL settings
gt krc config set patrol_* 12h     # Set TTL for patrol events to 12 hours
gt krc config set heartbeat_* 6h   # Set TTL for heartbeat events to 6 hours
```

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

## See Also

- [gt patrol](/docs/cli-reference/patrol) — Patrol digest aggregation
- [gt dolt](/docs/cli-reference/dolt) — Dolt SQL server management
- [Monitoring](/docs/operations/monitoring) — Operational monitoring patterns
