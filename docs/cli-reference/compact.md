---
title: "gt compact"
sidebar_position: 19
description: "Apply TTL-based compaction to ephemeral wisps. Promotes stuck wisps to permanent beads and deletes closed wisps past their TTL."
---

# gt compact

Apply TTL-based compaction policy to ephemeral wisps.

```bash
gt compact [flags]
gt compact [command]
```

## Description

```mermaid
flowchart TD
    A[gt compact] --> B[Scan wisps in rig]
    B --> C{For each wisp}
    C --> D{Has keep label<br/>or comments?}
    D -->|Yes| E[Promote to permanent bead]
    D -->|No| F{Past TTL?}
    F -->|No| G[Skip - within TTL]
    F -->|Yes| H{Status?}
    H -->|Closed| I[Delete wisp]
    H -->|Open| E
    E --> J[Report: promoted]
    I --> K[Report: deleted]
    G --> L[Report: skipped]
```

[Wisps](../concepts/wisps.md) are lightweight, ephemeral beads (heartbeats, pings, patrol reports). Over time they accumulate and need cleanup. Compaction applies TTL (time-to-live) policies:

- **Non-closed wisps past TTL** are promoted to permanent beads (something is stuck)
- **Closed wisps past TTL** are deleted (Dolt `AS OF` preserves history)
- **Wisps with comments, references, or `keep` labels** are always promoted

### TTLs by Wisp Type

| Type | TTL |
|------|-----|
| `heartbeat`, `ping` | 6 hours |
| `patrol`, `gc_report` | 24 hours |
| `recovery`, `error`, `escalation` | 7 days |
| Default (untyped) | 24 hours |

## Subcommands

| Command | Description |
|---------|-------------|
| [`report`](#gt-compact-report) | Generate and send compaction digest report |

## Flags

| Flag | Short | Description |
|------|-------|-------------|
| `--dry-run` | | Preview compaction without making changes |
| `--rig <name>` | | Compact a specific rig (default: current rig) |
| `--verbose` | `-v` | Show each wisp decision |
| `--json` | | Output results as JSON |

## Examples

```bash
gt compact               # Run compaction
gt compact --dry-run     # Preview what would happen
gt compact --verbose     # Show each wisp decision
gt compact --json        # Machine-readable output
gt compact --rig gastown # Compact a specific rig
```

---

## gt compact report

Generate a compaction digest and send it to deacon/ (cc mayor/).

```bash
gt compact report [flags]
```

The daily digest shows per-category breakdown of deleted, promoted, and active wisps, plus any promotions with reasons and detected anomalies.

The weekly rollup (`--weekly`) aggregates the past 7 days of compaction event beads and sends trend data to mayor/.

**Flags:**

| Flag | Short | Description |
|------|-------|-------------|
| `--dry-run` | | Preview report without sending |
| `--date <YYYY-MM-DD>` | | Report for specific date (default: today) |
| `--weekly` | | Generate weekly rollup instead of daily digest |
| `--verbose` | `-v` | Verbose output |
| `--json` | | Output report as JSON |

**Examples:**

```bash
gt compact report              # Run compaction + send daily digest
gt compact report --dry-run    # Preview the report without sending
gt compact report --weekly     # Send weekly rollup to mayor/
```

## When to Run Compaction

### Automated (Recommended)

The Deacon runs compaction automatically as part of its patrol cycle. The daily digest goes to the Deacon, and the weekly rollup goes to the Mayor. No manual intervention is needed for normal operations.

```text
Daemon heartbeat (3m) → Deacon patrol → gt compact → gt compact report
```

### Manual

Run compaction manually when:

- Investigating wisp accumulation after a long outage
- Cleaning up after a large convoy with many patrol wisps
- Verifying compaction behavior before changing TTL configuration

```bash
# Always preview first
gt compact --dry-run --verbose

# Then compact
gt compact --verbose
```

## Understanding the Output

A typical compaction run produces output like:

```text
Compacting gastowndocs...
  Scanned: 47 wisps
  Deleted: 12 (closed, past TTL)
  Promoted: 2 (open, past TTL — possible stuck work)
  Skipped: 33 (within TTL or has keep label)
```

- **Deleted**: Closed wisps whose TTL has expired. These were successfully completed work steps.
- **Promoted**: Open wisps past their TTL. This usually indicates something is stuck — check the promoted bead for context.
- **Skipped**: Wisps that are either still within their TTL or have the `keep` label.

## Troubleshooting

### Wisps Not Being Compacted

If `gt compact --dry-run` shows no wisps to process, check that:

1. The rig has wisps: `bd list --type wisp`
2. The wisps have exceeded their TTL (see table above)
3. You're targeting the correct rig: `gt compact --rig <name>`

### Unexpected Promotions

Wisps are promoted (instead of deleted) when they're still open past their TTL — this usually means something is stuck. Check the promoted bead for context:

```bash
# After compaction reports a promotion
bd show <promoted-bead-id>

# Common causes: stalled heartbeats, unresolved patrol findings
```

:::warning
Compaction is irreversible for deletions. Use `--dry-run` first to verify what will be removed. Dolt's `AS OF` feature preserves historical data, but direct recovery is not straightforward.
:::

## Related

- [Wisps](../concepts/wisps.md) -- The ephemeral beads that compaction manages
- [Diagnostics](./diagnostics.md) -- Other maintenance and diagnostic commands

### Blog Posts

- [Session Cycling: How Gas Town Agents Handle Context Limits](/blog/session-cycling) -- How Gas Town agents automatically hand off work when their context window fills up
- [The Deacon: Gas Town's Background Coordinator](/blog/deacon-patrol) -- How the Deacon runs compaction as part of its automated patrol cycle
