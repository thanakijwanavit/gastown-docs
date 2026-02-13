# Troubleshooting Guide

This guide covers common errors and their solutions when working with Gas Town.

## Dolt Database Locked

### Symptoms
- Error message: `database is locked` or `database table locked`
- Commands fail with SQL connection errors
- `gt hook` or `bd list` commands panic or timeout

### Causes
1. **Multiple processes accessing the database simultaneously**
2. **Stale lock files from crashed sessions**
3. **Dolt server not running or unreachable**
4. **Split-brain scenario: Dolt server unreachable at 127.0.0.1:3307**

### Solutions

**1. Check Dolt server status**
```bash
gt dolt status
```

**2. Start the Dolt server if not running**
```bash
gt dolt start
```

**3. Remove stale lock files**
```bash
rm -f /home/gastown/gt/gastowndocs/.beads/.jsonl.lock
rm -f /home/gastown/gt/gastowndocs/.beads/dolt-access.lock
```

**4. Restart Dolt server**
```bash
gt dolt stop
gt dolt start
```

**5. If database is corrupted, re-import from JSONL**
```bash
cd /home/gastown/gt/gastowndocs/.beads
bd import -i issues.jsonl
```

**6. Use `--allow-stale` flag for read-only operations**
```bash
bd ready --allow-stale
bd show <issue-id> --allow-stale
```

## Session Died During Startup

### Symptoms
- Agent session exits immediately after starting
- `gt prime` fails with identity collision errors
- Error: `worker is locked by another agent: PID ...`

### Causes
1. **Zombie sessions holding locks**
2. **Stale agent lock files**
3. **Identity collision with another agent**
4. **Missing agent beads or configuration**

### Solutions

**1. Run gt doctor to diagnose and fix issues**
```bash
gt doctor --fix
```

**2. Check for stale locks and remove if necessary**
```bash
rm /home/gastown/gt/.runtime/agent.lock
```

**3. Verify the Dolt server is running**
```bash
gt dolt status
```

**4. Check for zombie sessions**
```bash
gt doctor
# Look for: zombie-sessions, orphan-processes
```

**5. Restart from the correct directory**
```bash
cd /home/gastown/gt/gastowndocs/polecats/toast
gt prime
```

## gt sling Timeouts

### Symptoms
- `gt sling` command hangs or times out
- Unable to spawn new agents
- Session creation fails after extended wait

### Causes
1. **Daemon not running**
2. **Resource exhaustion (too many sessions)**
3. **Tmux server issues**
4. **Permission issues with runtime directories**

### Solutions

**1. Check daemon status**
```bash
gt status
# Look for daemon status in output
```

**2. Restart the daemon if needed**
```bash
gt daemon restart
```

**3. Check current session count**
```bash
gt list
```

**4. Clean up orphaned sessions**
```bash
gt doctor --fix
```

**5. Verify tmux is working**
```bash
tmux ls
```

## Polecat Won't Stay Running

### Symptoms
- Polecat session exits immediately after starting
- `gt done` was not run after previous work
- Agent keeps restarting with "HEALER CHECK" messages

### Causes
1. **No work on hook and no mail (ephemeral worker)**
2. **Database sync issues preventing work assignment**
3. **Missing worktree or incorrect directory**
4. **Work completed but `gt done` not run**

### Solutions

**1. Check if there's work on the hook**
```bash
gt hook
```

**2. Check for mail assignments**
```bash
gt mail inbox --all
```

**3. If no work, run gt done to exit cleanly**
```bash
gt done
```

**4. Verify correct working directory**
```bash
pwd  # Should show .../polecats/<name>/
```

**5. Check for database issues and fix**
```bash
gt doctor --fix
gt dolt start  # if needed
```

**6. Claim available work if idle**
```bash
bd ready --allow-stale  # See available work
bd update <issue-id> --status=in_progress --assignee=<polecat-name>
```

## Witness Offline

### Symptoms
- No patrol cycles running
- `gt session status gastowndocs/witness` shows session missing
- No cleanup of completed polecats

### Causes
1. **Witness session crashed or was killed**
2. **Tmux session lost**
3. **Configuration issues**

### Solutions

**1. Check witness session status**
```bash
gt session status gastowndocs/witness
```

**2. Restart the witness**
```bash
gt session start gastowndocs/witness
```

**3. Or use sling to respawn**
```bash
gt sling gastowndocs/witness
```

**4. Verify witness configuration**
```bash
ls -la /home/gastown/gt/gastowndocs/witness/
```

**5. Check witness logs for errors**
```bash
cat /home/gastown/gt/gastowndocs/witness/*.log 2>/dev/null || echo "No logs found"
```

**6. Run doctor to fix any configuration issues**
```bash
gt doctor --fix
```

## General Recovery Steps

When multiple issues occur simultaneously:

**1. Stop all Gas Town processes**
```bash
gt dolt stop
```

**2. Clean up lock files**
```bash
rm -f /home/gastown/gt/.runtime/agent.lock
rm -f /home/gastown/gt/gastowndocs/.beads/*.lock
```

**3. Run comprehensive doctor check**
```bash
gt doctor --fix
```

**4. Start services in order**
```bash
gt dolt start
gt daemon start  # if not auto-started
```

**5. Verify health**
```bash
gt status
bd ready --allow-stale
```

## Getting Help

If issues persist after trying these solutions:

1. **Check the system status**: `gt status`
2. **Review recent logs**: `/home/gastown/gt/gastowndocs/.beads/daemon.log`
3. **Mail the Mayor for cross-rig issues**: `gt mail send mayor/ -s "Help needed" -m "..."`
4. **Escalate critical issues**: `gt escalate "Description" -s CRITICAL`
