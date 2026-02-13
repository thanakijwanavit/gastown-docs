---
title: "Plugins"
sidebar_position: 5
description: "Extend Gas Town with custom gate plugins, action hooks, and scheduled tasks at the town or rig level."
---

# Plugins

Gas Town's plugin system extends the platform with custom automation, gates, and scheduled tasks. Plugins can operate at the town level (affecting all rigs) or at the rig level (scoped to a single project).

---

## Plugin Locations

### Town-Level Plugins

Town-level plugins live in `~/gt/plugins/` and are available across all rigs.

```text
~/gt/plugins/
├── eslint-gate/
│   ├── plugin.json
│   └── run.sh
├── deploy-notify/
│   ├── plugin.json
│   └── run.sh
└── cost-alert/
    ├── plugin.json
    └── run.sh
```

### Rig-Level Plugins

Rig-level plugins live in `<rig>/plugins/` and only affect that specific project.

```text
~/gt/myproject/plugins/
├── integration-tests/
│   ├── plugin.json
│   └── run.sh
└── coverage-check/
    ├── plugin.json
    └── run.sh
```

:::note

When a plugin exists at both levels with the same name, the rig-level plugin takes precedence for that rig.

:::

---

## Gate Types

Gates are the primary mechanism plugins use to control workflow execution. A gate blocks progress until its condition is met.

### Cooldown Gate

Enforces a minimum time delay between actions.

```json
{
  "name": "deploy-cooldown",
  "type": "cooldown",
  "config": {
    "duration": "10m",
    "scope": "rig"
  }
}
```

Use cases:

- Prevent rapid-fire deployments
- Rate-limit API calls
- Enforce review periods between merges

### Cron Gate

Opens at scheduled times based on a cron expression.

```json
{
  "name": "nightly-tests",
  "type": "cron",
  "config": {
    "schedule": "0 2 * * *",
    "timezone": "America/Los_Angeles"
  }
}
```

Use cases:

- Nightly test suite execution
- Scheduled deployments
- Periodic cleanup tasks

### Condition Gate

Opens when a boolean condition evaluates to true.

```json
{
  "name": "tests-pass",
  "type": "condition",
  "config": {
    "command": "npm test",
    "success_exit_code": 0,
    "retry_interval": "5m",
    "max_retries": 3
  }
}
```

Use cases:

- Block merges until tests pass
- Wait for a service to be healthy
- Check external API availability

### Event Gate

Opens in response to a specific event in the activity stream.

```json
{
  "name": "convoy-complete",
  "type": "event",
  "config": {
    "event_type": "convoy.completed",
    "filter": {
      "convoy_id": "$CONVOY_ID"
    }
  }
}
```

Use cases:

- Trigger deployment after all convoy work merges
- Send notifications on escalation events
- Chain workflows based on activity events

### Manual Gate

Requires explicit human approval to open.

```json
{
  "name": "production-deploy",
  "type": "manual",
  "config": {
    "approvers": ["human"],
    "prompt": "Approve production deployment?",
    "notify_channels": ["email:human"]
  }
}
```

Use cases:

- Production deployment approval
- Sensitive data access authorization
- High-risk operation confirmation

---

## Plugin Structure

Every plugin requires a `plugin.json` manifest and an executable entry point.

### plugin.json

```json
{
  "name": "integration-tests",
  "version": "1.0.0",
  "description": "Run integration test suite as a merge gate",
  "author": "yourname",
  "type": "gate",
  "gate_type": "condition",
  "trigger": "pre-merge",
  "config": {
    "command": "./run.sh",
    "timeout": "10m",
    "success_exit_code": 0,
    "retry_on_failure": true,
    "max_retries": 2
  },
  "inputs": {
    "rig": "$RIG_NAME",
    "branch": "$BRANCH_NAME",
    "bead": "$BEAD_ID"
  },
  "outputs": {
    "report": "test-results.json"
  }
}
```

### Manifest Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Unique plugin identifier |
| `version` | Yes | Semantic version |
| `description` | Yes | Human-readable description |
| `author` | No | Plugin author |
| `type` | Yes | Plugin type: `gate`, `action`, `hook`, `schedule` |
| `gate_type` | If gate | One of: `cooldown`, `cron`, `condition`, `event`, `manual` |
| `trigger` | Yes | When to execute: `pre-merge`, `post-merge`, `on-spawn`, `on-done`, `manual` |
| `config` | Yes | Plugin-specific configuration |
| `inputs` | No | Variables passed to the plugin (supports `$VAR` substitution) |
| `outputs` | No | Expected output files or values |

### Entry Point (run.sh)

The entry point receives inputs as environment variables and should exit with the appropriate code:

```bash
#!/bin/bash
# run.sh - Integration test plugin

echo "Running integration tests for rig: $RIG_NAME"
echo "Branch: $BRANCH_NAME"
echo "Bead: $BEAD_ID"

cd "$RIG_PATH/refinery/rig"

# Run tests
npm run test:integration 2>&1 | tee test-output.log
EXIT_CODE=${PIPESTATUS[0]}

# Generate report
if [ $EXIT_CODE -eq 0 ]; then
    echo '{"status": "passed", "tests": "all"}' > test-results.json
else
    echo '{"status": "failed", "log": "test-output.log"}' > test-results.json
fi

exit $EXIT_CODE
```

---

## Plugin Commands

### `gt plugin list`

List all available plugins.

```bash
# List all plugins
gt plugin list

# List town-level plugins only
gt plugin list --scope town

# List rig-level plugins
gt plugin list --rig myproject

# JSON output
gt plugin list --json
```

Sample output:

```text
Town plugins:
  eslint-gate       gate/condition   pre-merge   v1.0.0
  deploy-notify     action           post-merge  v1.2.0
  cost-alert        schedule         cron        v0.9.0

Rig: myproject
  integration-tests gate/condition   pre-merge   v1.0.0
  coverage-check    gate/condition   pre-merge   v1.1.0
```

### `gt plugin show`

View details of a specific plugin.

```bash
gt plugin show integration-tests
gt plugin show integration-tests --rig myproject
```

### `gt plugin run`

Manually trigger a plugin execution.

```bash
# Run a plugin
gt plugin run integration-tests --rig myproject

# Run with custom inputs
gt plugin run integration-tests --rig myproject --input branch=feature/auth

# Dry run (show what would happen)
gt plugin run integration-tests --dry-run
```

### `gt plugin history`

View the execution history of a plugin.

```bash
# View recent executions
gt plugin history integration-tests

# Filter by status
gt plugin history integration-tests --status failed

# Filter by time
gt plugin history integration-tests --since 7d

# JSON output
gt plugin history --json
```

Sample output:

```text
Plugin: integration-tests (last 5 runs)

  2025-06-15 14:23  PASSED  branch: fix/login    12.4s
  2025-06-15 13:01  FAILED  branch: feat/auth     8.2s  (exit code 1)
  2025-06-15 12:45  PASSED  branch: fix/typo      6.1s
  2025-06-14 22:00  PASSED  branch: feat/api     15.3s
  2025-06-14 18:30  PASSED  branch: fix/css        4.8s
```

---

## Creating Custom Plugins

### Step 1: Create the Plugin Directory

```bash
# Town-level plugin
mkdir -p ~/gt/plugins/my-plugin

# Or rig-level plugin
mkdir -p ~/gt/myproject/plugins/my-plugin
```

### Step 2: Write the Manifest

Create `plugin.json`:

```json
{
  "name": "my-plugin",
  "version": "1.0.0",
  "description": "Custom quality gate that checks code coverage",
  "type": "gate",
  "gate_type": "condition",
  "trigger": "pre-merge",
  "config": {
    "command": "./run.sh",
    "timeout": "5m",
    "success_exit_code": 0
  },
  "inputs": {
    "rig": "$RIG_NAME",
    "branch": "$BRANCH_NAME",
    "min_coverage": "80"
  }
}
```

### Step 3: Write the Entry Point

Create `run.sh`:

```bash
#!/bin/bash
set -e

echo "Checking code coverage for $RIG_NAME ($BRANCH_NAME)"
echo "Minimum required: ${MIN_COVERAGE}%"

cd "$RIG_PATH/refinery/rig"

# Run coverage tool
COVERAGE=$(go test -coverprofile=cover.out ./... 2>&1 | grep "coverage:" | awk '{print $2}' | tr -d '%')

echo "Coverage: ${COVERAGE}%"

if (( $(echo "$COVERAGE >= $MIN_COVERAGE" | bc -l) )); then
    echo "PASS: Coverage meets threshold"
    exit 0
else
    echo "FAIL: Coverage ${COVERAGE}% is below minimum ${MIN_COVERAGE}%"
    exit 1
fi
```

### Step 4: Make Executable and Test

```bash
chmod +x ~/gt/plugins/my-plugin/run.sh

# Test manually
gt plugin run my-plugin --rig myproject

# Check it appears in the list
gt plugin list
```

---

## Plugin Environment Variables

Plugins receive these variables automatically:

| Variable | Description |
|----------|-------------|
| `$RIG_NAME` | Name of the current rig |
| `$RIG_PATH` | Absolute path to the rig directory |
| `$BRANCH_NAME` | Git branch being processed |
| `$BEAD_ID` | Bead ID associated with the work |
| `$CONVOY_ID` | Convoy ID if work is part of a convoy |
| `$AGENT_NAME` | Name of the agent triggering the plugin |
| `$AGENT_ROLE` | Role of the triggering agent |
| `$GT_HOME` | Path to the town directory |
| `$PLUGIN_DIR` | Path to the plugin's own directory |

Custom inputs defined in `plugin.json` are also passed as uppercase environment variables (e.g., `min_coverage` becomes `$MIN_COVERAGE`).

---

## Debugging Plugins

When a plugin fails, the first step is understanding where and why.

### Viewing Execution Output

Plugin stdout and stderr are captured in the execution history:

```bash
# See recent runs with output
gt plugin history my-plugin --last 5

# See detailed output of a specific run
gt plugin history my-plugin --verbose
```

### Running with Debug Output

Add verbose logging to your `run.sh` during development:

```bash
#!/bin/bash
set -euo pipefail

# Debug: print all environment variables available to the plugin
echo "=== Plugin Environment ==="
echo "RIG_NAME: $RIG_NAME"
echo "RIG_PATH: $RIG_PATH"
echo "BRANCH_NAME: $BRANCH_NAME"
echo "BEAD_ID: $BEAD_ID"
echo "PLUGIN_DIR: $PLUGIN_DIR"
echo "========================="

# Your plugin logic here...
```

### Common Failure Causes

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| Plugin not found | Wrong directory or missing `plugin.json` | Check `gt plugin list` and verify path |
| Permission denied | `run.sh` not executable | `chmod +x run.sh` |
| Exit code 127 | Command not found in plugin script | Check `$PATH` or use absolute paths |
| Timeout | Plugin exceeds configured timeout | Increase `timeout` in `plugin.json` or optimize |
| Works manually, fails in pipeline | Missing environment variables | Check Plugin Environment Variables table |

### Testing Locally Before Deploying

Always test plugins outside the pipeline first:

```bash
# Dry run: shows what would happen without executing
gt plugin run my-plugin --rig myproject --dry-run

# Manual run with custom inputs to simulate different scenarios
gt plugin run my-plugin --rig myproject --input branch=main
gt plugin run my-plugin --rig myproject --input branch=feature/untested
```

---

## Plugin Types Beyond Gates

While gates are the most common plugin type, Gas Town supports four plugin types:

### Action Plugins

Actions run in response to triggers but do not block workflow progress. Use these for notifications, logging, or side effects.

```json
{
  "name": "deploy-notify",
  "type": "action",
  "trigger": "post-merge",
  "config": {
    "command": "./notify.sh",
    "timeout": "30s"
  }
}
```

### Hook Plugins

Hooks intercept lifecycle events and can modify behavior. They run synchronously at specific points in the agent lifecycle.

```json
{
  "name": "pre-spawn-check",
  "type": "hook",
  "trigger": "on-spawn",
  "config": {
    "command": "./check-capacity.sh",
    "timeout": "10s"
  }
}
```

### Schedule Plugins

Scheduled plugins run on a cron schedule independently of workflow events.

```json
{
  "name": "nightly-cleanup",
  "type": "schedule",
  "config": {
    "schedule": "0 3 * * *",
    "timezone": "America/Los_Angeles",
    "command": "./cleanup.sh",
    "timeout": "5m"
  }
}
```

---

## Plugin Best Practices

1. **Keep plugins fast.** Plugins that run as gates block the merge pipeline. Aim for under 60 seconds; use the `timeout` config to prevent runaway executions.

2. **Make plugins idempotent.** Plugins may be retried on failure. Ensure they produce the same result when run multiple times.

3. **Use exit codes correctly.** Exit code 0 means success (gate opens). Any non-zero exit code means failure (gate stays closed).

4. **Log meaningful output.** Plugin stdout is captured in the execution history. Write clear messages that help diagnose failures.

5. **Version your plugins.** Use semantic versioning in `plugin.json` and keep a changelog for team visibility.

6. **Test plugins manually first.** Use `gt plugin run --dry-run` and then `gt plugin run` before relying on them in the merge pipeline.

:::tip[Plugin Ideas]

- **Lint gate**: Run ESLint, Pylint, or golangci-lint before merge
- **Coverage gate**: Enforce minimum test coverage thresholds
- **Security scan**: Run dependency vulnerability checks
- **Deploy notifier**: Post to Slack/Discord after successful merge
- **Cost alert**: Notify when daily token spend exceeds a budget
- **Changelog enforcer**: Require changelog updates with each PR


:::

## Related

- [Gates](../concepts/gates.md) -- Async coordination primitives that plugins use to control workflow execution
- [Molecules](../concepts/molecules.md) -- Multi-step workflows that plugins can extend with custom gates and actions
- [Refinery](../agents/refinery.md) -- The merge queue agent that invokes gate plugins during validation
- [Cost Management](../guides/cost-management.md) -- Using cost alert plugins to monitor token spend