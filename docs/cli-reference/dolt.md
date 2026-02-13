---
title: "gt dolt"
sidebar_position: 17
description: "Manage the Dolt SQL server that provides multi-client access to all rig bead databases."
---

# gt dolt

Manage the Dolt SQL server for Gas Town beads storage.

The Dolt server provides multi-client access to all rig databases, avoiding the single-writer limitation of embedded Dolt mode. Each rig (hq, gastown, beads, etc.) has its own database within the centralized data directory.

## Server Configuration

| Setting | Value |
|---------|-------|
| Port | 3307 (avoids conflict with MySQL on 3306) |
| User | root (default Dolt user, no password for localhost) |
| Data directory | `.dolt-data/` (contains all rig databases) |

## Commands

### Lifecycle

```bash
gt dolt start          # Start the Dolt server
gt dolt stop           # Stop the Dolt server
gt dolt status         # Show server status (running, port, connections)
gt dolt logs           # View Dolt server logs
```text

### Database Management

```bash
gt dolt init           # Initialize and repair workspace configuration
gt dolt init-rig       # Initialize a new rig database
gt dolt list           # List available rig databases
gt dolt sql            # Open interactive Dolt SQL shell
```text

### Migration & Recovery

```bash
gt dolt migrate        # Migrate existing databases to centralized data directory
gt dolt rollback       # Restore .beads directories from a migration backup
gt dolt recover        # Detect and recover from Dolt read-only state
gt dolt fix-metadata   # Update metadata.json in all rig .beads directories
```text

### Remote Sync

```bash
gt dolt sync           # Push Dolt databases to DoltHub remotes
```text

:::warning
The Dolt server uses port 3307 by default to avoid conflicts with MySQL on port 3306. If you have another service on 3307, you will need to change the Dolt port before starting.
:::

## Common Workflows

### Initial Setup

```bash
gt dolt init           # Set up centralized Dolt data directory
gt dolt start          # Start the server
gt dolt status         # Verify it's running
```text

### Recovering from Read-Only State

If beads operations fail with "database is read-only" errors:

```bash
gt dolt recover        # Auto-detect and fix read-only state
gt dolt status         # Verify recovery
```text

This typically happens when the Dolt server shuts down uncleanly or when multiple writers conflict. The `recover` command detects the issue and restarts the server with a clean lock state.

:::caution
If you see repeated "database is read-only" errors, do not attempt to manually edit lock files in `.dolt-data/`. Always use `gt dolt recover` which handles lock cleanup atomically.
:::

### Adding a New Rig

When a new rig is created, it needs its own database:

```bash
gt dolt init-rig       # Creates database for the new rig
gt dolt list           # Verify it appears in the database list
```text

### Inspecting Data with SQL

The `sql` subcommand opens an interactive SQL shell connected to the running Dolt server. Useful for debugging beads state:

```bash
gt dolt sql
# Then in the SQL shell:
# USE gastowndocs;
# SELECT * FROM beads WHERE status = 'in_progress';
# SHOW TABLES;
```text

### Migration from Embedded Mode

If upgrading from embedded Dolt (per-rig `.beads/` databases) to the centralized server:

```bash
gt dolt migrate        # Move databases to centralized .dolt-data/
gt dolt start          # Start the server against the new location
gt dolt fix-metadata   # Update rig metadata to point to the server
```text

If migration goes wrong, roll back:

```bash
gt dolt rollback       # Restore from the pre-migration backup
```text

## Architecture

```text
$GT_ROOT/
├── .dolt-data/              ← Centralized data directory
│   ├── hq/                  ← HQ (town-level) database
│   ├── gastowndocs/         ← Per-rig database
│   ├── beads/               ← Per-rig database
│   └── ...
└── gt/
    └── gastowndocs/
        └── .beads/
            └── metadata.json  ← Points to Dolt server on port 3307
```text

All `bd` commands route through the Dolt server automatically when it's running. If the server is down, commands fall back to embedded mode (single-writer).

## See Also

- [Beads](../concepts/beads.md) — The work tracking system backed by Dolt
- [Configuration](configuration.md) — Town-level settings
- [gt krc](krc.md) — TTL-based lifecycle for ephemeral data stored in Dolt
- [Monitoring](../operations/monitoring.md) — Operational monitoring patterns
