---
title: "Cost Management"
sidebar_position: 4
description: "Monitor and optimize Gas Town token costs with budget workflows, cost alerts, and strategies for reducing spend."
---

# Cost Management

Gas Town burns tokens. A lot of tokens. At peak usage with 10+ polecats running simultaneously, you can expect to spend approximately **$100/hour** -- roughly 10x what a single Claude Code session costs. This guide covers monitoring, understanding, and optimizing your token spend.

---

## Understanding Gas Town Costs

### Where Tokens Go

Every agent session consumes tokens. The breakdown varies by workload, but a typical distribution looks like this:

| Agent Type | % of Total Cost | Why |
|-----------|----------------|-----|
| **Polecats** | 60-70% | Writing code, running tests, iterating on implementations |
| **Witnesses** | 8-12% | Patrol cycles, health checks, nudging stuck polecats |
| **Refineries** | 5-10% | Merge conflict resolution, validation runs |
| **Mayor** | 5-10% | Strategic coordination, convoy management |
| **Deacon** | 3-5% | Health monitoring, lifecycle management |
| **Dogs/Boot** | 1-3% | Infrastructure tasks, triage |

Polecats dominate costs because they do the actual coding work -- reading files, reasoning about changes, running tests, and iterating until done.

### Cost Factors

| Factor | Impact |
|--------|--------|
| Number of polecats | Linear increase in cost |
| Task complexity | Complex tasks = more tokens per polecat |
| Codebase size | Larger codebases = more context tokens |
| Test suite runtime | Longer tests = longer sessions = more tokens |
| Merge conflicts | Conflicts spawn additional polecats for resolution |
| Patrol frequency | More frequent patrols = higher monitoring costs |

### Typical Cost Ranges

| Usage Level | Polecats | Approx. Cost/Hour | Use Case |
|-------------|----------|--------------------|----------|
| **Minimal** | 1-2 | $10-20 | Focused work, single rig |
| **Normal** | 3-5 | $30-50 | Active development, 1-2 rigs |
| **Heavy** | 6-10 | $50-100 | Multi-rig parallel development |
| **Peak** | 10-20+ | $100-200+ | Full fleet, aggressive timeline |

:::warning[Costs Add Up Fast]

An 8-hour workday at "Normal" usage (3-5 polecats) costs $240-400. At "Peak" usage, a full day can exceed $1,000. Monitor continuously and adjust your polecat count based on budget constraints.

:::

---

## Monitoring Costs

### `gt costs` Command

The primary cost monitoring tool:

```bash
# Current session costs
gt costs

# Today's costs
gt costs --today

# This week's costs
gt costs --week

# Breakdown by role
gt costs --by-role

# Breakdown by rig
gt costs --by-rig

# JSON output for external tools
gt costs --json
```

### Sample Output

```text
Gas Town Costs (today)

  Total tokens:  4,800,000 input / 1,620,000 output
  Est. cost:     $89.40

  By role:
    Polecats:    $61.30  (68.6%)  [12 sessions]
    Witnesses:   $9.80   (11.0%)  [3 sessions]
    Refineries:  $6.20   (6.9%)   [3 sessions]
    Mayor:       $7.10   (7.9%)   [1 session]
    Deacon:      $3.80   (4.3%)   [1 session]
    Other:       $1.20   (1.3%)

  By rig:
    myapp:       $52.10  (58.3%)
    api-server:  $24.80  (27.7%)
    docs:        $12.50  (14.0%)

  Hourly rate (last 3h avg): $32.40/hr
```

### Real-Time Cost Monitoring

Keep a cost watch running alongside your feed:

```bash
# In terminal 1: activity feed
gt feed

# In terminal 2: cost updates every 5 minutes
watch -n 300 gt costs --today
```

---

## Cost Optimization Strategies

### Strategy 1: Fewer Polecats

The most direct way to reduce costs. Each polecat you remove saves its proportional token spend.

```bash
# Check how many polecats are running
gt polecat list

# Remove unnecessary polecats
gt polecat remove alpha --rig myproject

# Reduce the max polecat count via rig settings
gt rig settings set --rig myproject max_polecats 3
```

:::tip[Quality Over Quantity]

Three well-targeted polecats often outperform eight unfocused ones. Assign specific, well-defined tasks rather than vague directives. Specific tasks complete faster, consuming fewer tokens.

:::

### Strategy 2: Focused Convoys

Bundle related work tightly so polecats do not waste tokens on context-switching or redundant file reads.

```bash
# Instead of many small convoys:
gt convoy create "Fix A" gt-a1
gt convoy create "Fix B" gt-b2
gt convoy create "Fix C" gt-c3

# Create one focused convoy:
gt convoy create "Auth Module Fixes" gt-a1 gt-b2 gt-c3
```

When related beads are in the same convoy, the Mayor can assign them to fewer polecats that share context, reducing redundant file reading.

### Strategy 3: Minimal Mode

Run Gas Town with reduced monitoring overhead for cost-sensitive workloads.

```bash
# Enable minimal mode
gt rig settings set minimal_mode true
```

Minimal mode:

- Increases patrol cycle intervals (5 min to 15 min)
- Reduces Witness verbosity
- Skips non-essential health checks
- Defers non-critical escalations

:::note

Minimal mode trades monitoring responsiveness for lower costs. Problems may take longer to detect. Use it for stable workloads where you are confident agents will not stall.

:::

### Strategy 4: Park Idle Rigs

Rigs you are not actively developing on still consume tokens through their Witnesses and Refineries:

```bash
# Park rigs you are not using today
gt rig park docs
gt rig park staging-env

# Unpark when needed
gt rig unpark docs
```

### Strategy 5: Time-Box Sessions

Rather than running the fleet all day, work in focused sprints:

```bash
# Morning sprint (2 hours)
gt start --all
# ... intensive work ...
gt down

# Afternoon sprint (2 hours)
gt start --all
# ... intensive work ...
gt down
```

A 2-hour sprint at "Normal" usage costs $60-100, compared to $240-400 for an 8-hour continuous run.

### Strategy 6: Reduce Context Size

Large codebases mean more input tokens per agent interaction. Reduce context costs by:

- Using focused CLAUDE.md files that only include relevant context
- Keeping project documentation concise
- Using `.gitignore` patterns to exclude unnecessary files from agent view
- Breaking monorepos into separate rigs so each polecat sees only its relevant code

### Strategy 7: Optimize Merge Flow

Merge conflicts spawn additional polecats for resolution. Reduce conflicts by:

- Assigning related files to the same polecat
- Serializing work on highly-contended files via convoy dependencies
- Running smaller, more frequent merges rather than large batches

---

## Budget-Conscious Workflows

### The "$50/day" Workflow

For teams with a $50/day budget:

```bash
# Use 2 polecats max
gt rig settings set max_polecats 2

# Enable minimal mode
gt rig settings set minimal_mode true

# Work in 2-hour focused sprints
gt start --all
# ... 2 hours of focused work ...
gt down

# Monitor costs
gt costs --today
```

### The "$200/day" Workflow

For teams with a $200/day budget:

```bash
# Use up to 5 polecats
gt rig settings set max_polecats 5

# Normal monitoring
gt rig settings set minimal_mode false

# Work in 4-hour sprints with breaks
gt start --all
# ... 4 hours ...
gt down
# ... break ...
gt start --all
# ... 4 hours ...
gt down

# Monitor costs every hour
gt costs --today --by-role
```

### The "Unlimited" Workflow

For teams where speed matters more than cost:

```bash
# Max polecats
gt rig settings set max_polecats 15

# Full monitoring
gt start --all

# Run all day, monitor hourly
watch -n 3600 gt costs --today
```

---

## Cost Alerts

Set up automated cost alerts using the plugin system:

```json
{
  "name": "cost-alert",
  "type": "schedule",
  "gate_type": "cron",
  "config": {
    "schedule": "0 * * * *",
    "command": "./check-costs.sh",
    "alert_threshold_hourly": 50,
    "alert_threshold_daily": 300
  }
}
```

Example `check-costs.sh`:

```bash
#!/bin/bash
DAILY_COST=$(gt costs --today --json | jq '.total_cost')

if (( $(echo "$DAILY_COST > 300" | bc -l) )); then
    gt escalate --severity high "Daily cost threshold exceeded: \$$DAILY_COST"
fi
```

---

## Cost Comparison

To put Gas Town costs in perspective:

| Resource | Cost/Hour | Equivalent |
|----------|-----------|------------|
| Gas Town (3 polecats) | ~$30-50 | 1/3 of a senior developer hourly rate |
| Gas Town (10 polecats) | ~$100 | ~1 senior developer hourly rate |
| Gas Town (20 polecats) | ~$200 | ~2 senior developers hourly rate |
| Single Claude Code session | ~$10 | Baseline AI coding cost |

The question is not "is this expensive?" but "is the throughput worth the cost?" Gas Town at 10 polecats can move 5-10x faster than a single developer, at roughly the same hourly cost.

---

## Cost Tracking Best Practices

1. **Check `gt costs --today` at least twice per day** -- once in the morning and once before ending your session.

2. **Set a daily budget** and configure cost alerts to notify you when approaching it.

3. **Review `gt costs --by-role` weekly** to identify agents that are disproportionately expensive. A Witness consuming 20% of total cost may indicate a health monitoring loop.

4. **Track cost per completed bead** over time. This metric tells you whether you are getting more efficient: `total_daily_cost / beads_closed_today`.

5. **Park unused rigs aggressively.** Even idle Witnesses and Refineries consume tokens during patrol cycles.

6. **Use `gt down` during breaks.** Do not leave the fleet running during lunch or meetings unless you have active work in progress.

## Related

- [Monitoring & Health](../operations/monitoring.md) -- The `gt costs` command and real-time cost tracking
- [Starting & Stopping](../operations/lifecycle.md) -- `gt down` and `gt shutdown` for controlling agent runtime
- [Minimal Mode](../workflows/minimal-mode.md) -- Reduced-overhead workflow for cost-sensitive workloads
- [Plugins](../operations/plugins.md) -- Set up cost alert plugins with cron-scheduled budget checks
