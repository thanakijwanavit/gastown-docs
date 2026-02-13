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
```

### Database Management

```bash
gt dolt init           # Initialize and repair workspace configuration
gt dolt init-rig       # Initialize a new rig database
gt dolt list           # List available rig databases
gt dolt sql            # Open interactive Dolt SQL shell
```

### Migration & Recovery

```bash
gt dolt migrate        # Migrate existing databases to centralized data directory
gt dolt rollback       # Restore .beads directories from a migration backup
gt dolt recover        # Detect and recover from Dolt read-only state
gt dolt fix-metadata   # Update metadata.json in all rig .beads directories
```

### Remote Sync

```bash
gt dolt sync           # Push Dolt databases to DoltHub remotes
```

## Common Workflows

### Initial Setup

```bash
gt dolt init           # Set up centralized Dolt data directory
gt dolt start          # Start the server
gt dolt status         # Verify it's running
```

### Recovering from Read-Only State

If beads operations fail with "database is read-only" errors:

```bash
gt dolt recover        # Auto-detect and fix read-only state
gt dolt status         # Verify recovery
```

### Adding a New Rig

```bash
gt dolt init-rig       # Creates database for the new rig
gt dolt list           # Verify it appears
```

## See Also

- [Beads](../concepts/beads.md) — The work tracking system backed by Dolt
- [Configuration](configuration.md) — Town-level settings
