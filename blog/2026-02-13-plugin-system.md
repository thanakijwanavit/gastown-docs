---
title: "Extending Gas Town with Plugins"
description: "How Gas Town's plugin system lets you customize agent behavior, add quality gates, and integrate with external services."
slug: plugin-system
authors: [gastown]
tags: [plugins, architecture, customization, operations]
---

Gas Town ships with sensible defaults, but every team has unique needs. The plugin system lets you extend and customize agent behavior without forking the core -- adding custom quality gates, integrating external services, and shaping how agents work in your environment.

<!-- truncate -->

## What Are Plugins?

Plugins are scripts or configurations that hook into Gas Town's lifecycle events. When a polecat completes work, when the Refinery processes a merge, when the Witness detects a stall -- each of these events can trigger plugin code.

```text
~/gt/myproject/
├── plugins/
│   ├── pre-merge/        # Runs before Refinery merges
│   │   └── lint-check.sh
│   ├── post-merge/       # Runs after successful merge
│   │   └── notify-slack.sh
│   ├── on-stall/         # Runs when Witness detects a stall
│   │   └── alert-pagerduty.sh
│   └── quality-gates/    # Custom quality gate definitions
│       └── coverage.toml
```

Plugins live in the rig's `plugins/` directory and are version-controlled alongside your code. This means plugin changes go through the same review process as code changes.

```mermaid
flowchart LR
    subgraph Lifecycle["Plugin Hook Points"]
        SP[on-spawn] --> PM[pre-merge]
        PM --> PO[post-merge]
        PO --> OS[on-stall]
        OS --> ON[on-nuke]
    end
    PM -->|fail| RJ[Reject MR]
    PM -->|pass| MG[Merge to Main]
    PO --> SL[Notify Slack]
```

## Plugin Types

### Quality Gate Plugins

The most common plugin type adds **custom quality gates** to the Refinery merge process. Out of the box, the Refinery runs tests and checks for clean rebasing. Quality gate plugins add additional checks:

```mermaid
timeline
    title Plugin Deployment Lifecycle
    Development : Write plugin script
                : Test manually in isolation
    Testing : Deploy with fail_action=warn
            : Monitor for false positives
    Stabilization : Fix edge cases
                  : Tune timeouts and thresholds
    Production : Promote to fail_action=reject
               : Plugin blocks failing merges
    Maintenance : Monitor plugin logs
                : Update as codebase evolves
```

```toml
# plugins/quality-gates/coverage.toml
name = "coverage-check"
description = "Ensure test coverage doesn't drop below 80%"
stage = "pre-merge"
command = "scripts/check-coverage.sh"
fail_action = "reject"   # reject | warn | notify
threshold = 80
```

When the Refinery processes a merge request, it runs all quality gate plugins in sequence. If any gate with `fail_action = "reject"` fails, the merge is blocked and a bead is created for the polecat to fix the issue.

### Notification Plugins

Notification plugins fire on lifecycle events and integrate Gas Town with external services:

```bash
#!/bin/bash
# plugins/post-merge/notify-slack.sh
# Called with: $1 = branch name, $2 = merge commit SHA

curl -X POST "$SLACK_WEBHOOK_URL" \
  -H 'Content-Type: application/json' \
  -d "{\"text\": \"Merged: $1 ($2)\"}"
```

Common notification targets include Slack, Discord, PagerDuty, and email. The plugin receives context about the event (branch name, bead ID, agent identity) as environment variables or arguments.

### Lifecycle Plugins

Lifecycle plugins run at specific points in an agent's lifecycle:

| Hook Point | When It Fires | Use Case |
|-----------|--------------|----------|
| `pre-merge` | Before Refinery merges a branch | Lint, coverage, security scan |
| `post-merge` | After successful merge | Notifications, deployment triggers |
| `on-stall` | When Witness detects a stuck polecat | Custom alerting, automatic remediation |
| `on-spawn` | When a new polecat is created | Environment setup, dependency install |
| `on-nuke` | When a polecat sandbox is destroyed | Cleanup, resource deallocation |
| `on-cycle` | When a persistent agent cycles | Metrics collection, health reporting |

## Writing a Plugin

A minimal plugin is a shell script in the right directory:

```bash
#!/bin/bash
# plugins/pre-merge/security-scan.sh
# Exit 0 = pass, Exit 1 = fail

echo "Running security scan..."
npm audit --audit-level=high

if [ $? -ne 0 ]; then
  echo "FAIL: High-severity vulnerabilities found"
  exit 1
fi

echo "PASS: No high-severity vulnerabilities"
exit 0
```

Make it executable and place it in the appropriate hook directory:

```bash
chmod +x plugins/pre-merge/security-scan.sh
git add plugins/pre-merge/security-scan.sh
git commit -m "Add pre-merge security scan plugin"
```

:::note[Plugins Are Discovered Automatically via Filesystem Convention]
The Refinery scans `plugins/pre-merge/`, `plugins/post-merge/`, and other hook directories for executable scripts on every merge cycle. No registration step, no configuration file, no restart required. Drop an executable script into the right directory, commit it, and the Refinery will run it on the next merge. This filesystem-based convention keeps the plugin system simple and discoverable.
:::

The Refinery will automatically discover and run it during merge processing. No registration or configuration beyond the file itself is needed — convention over configuration keeps the plugin system simple. For security considerations when adding external scripts, see [Security Model](/blog/security-model).

:::danger Never Place Destructive Commands in post-merge Plugins
Post-merge plugins run after code has landed on main, and any failures at this stage cannot roll back the merge. Avoid commands that modify the repository state (like `git reset` or database migrations) in post-merge hooks. Use them strictly for read-only actions like notifications, metric collection, or triggering downstream CI pipelines.
:::

## Plugin Configuration

For more complex plugins, use a TOML configuration file:

```toml
# plugins/quality-gates/type-check.toml
name = "type-check"
description = "Run TypeScript type checking"
stage = "pre-merge"
command = "npx tsc --noEmit"
fail_action = "reject"
timeout = "120s"
retry = 1
```

| Field | Description |
|-------|-------------|
| `name` | Plugin identifier |
| `description` | Human-readable description |
| `stage` | Lifecycle hook point |
| `command` | Shell command to execute |
| `fail_action` | What happens on failure: `reject`, `warn`, or `notify` |
| `timeout` | Maximum execution time |
| `retry` | Number of retries on failure |

```mermaid
flowchart TD
    MR[Merge Request] --> P1["01-lint.sh"]
    P1 -->|pass| P2["02-type-check.sh"]
    P2 -->|pass| P3["03-test-coverage.sh"]
    P3 -->|pass| P4["04-security-scan.sh"]
    P4 -->|pass| MG[Merge to Main]
    P1 -->|fail| RJ[Reject MR]
    P2 -->|fail| RJ
    P3 -->|fail| RJ
    P4 -->|fail| RJ
```

## Plugin Ordering

When multiple plugins target the same hook point, they execute in alphabetical order by filename. Use numeric prefixes to control ordering:

```text
plugins/pre-merge/
├── 01-lint.sh
├── 02-type-check.sh
├── 03-test-coverage.sh
└── 04-security-scan.sh
```

If any plugin fails with `fail_action = "reject"`, subsequent plugins are skipped and the merge is blocked.

:::warning Always Set Timeouts on Pre-Merge Plugins
A plugin that hangs will block the entire Refinery merge queue, stalling all agents waiting for their work to land on main. Always set a `timeout` field in your plugin configuration. If a plugin cannot complete within 60 seconds, consider running it asynchronously as a post-merge notification instead of a blocking pre-merge gate.
:::

:::tip Use `warn` for New Plugins Before Promoting to `reject`
When deploying a new quality gate plugin, start with `fail_action = "warn"` so it logs failures without blocking the merge queue. Monitor the warnings for a few days to verify the plugin runs reliably, then promote it to `fail_action = "reject"` once you are confident it will not produce false positives that stall your polecats.
:::

:::info Plugin Output Is Captured in the Refinery Log
Every plugin's stdout and stderr are captured and stored in the Refinery's merge log for the associated MR. If a pre-merge plugin fails and rejects a merge, you can review the full plugin output with `gt mq log <mr-id>` to understand exactly what went wrong. This is especially useful when debugging intermittent failures in quality gate plugins that only reproduce under rebase conditions.
:::

```mermaid
sequenceDiagram
    participant PC as Polecat
    participant RF as Refinery
    participant PL as Plugins
    participant MN as Main Branch

    PC->>RF: gt done (submit MR)
    RF->>RF: Rebase onto main
    RF->>PL: Run pre-merge plugins
    PL->>PL: 01-lint.sh
    PL->>PL: 02-type-check.sh
    PL->>PL: 03-coverage.sh
    PL-->>RF: All gates pass
    RF->>MN: Merge to main
    RF->>PL: Run post-merge plugins
    PL->>PL: notify-slack.sh
```

## Best Practices

```mermaid
graph LR
    subgraph Development["Plugin Development Lifecycle"]
        W[Write Script] --> T[Test Manually]
        T --> D[Deploy as warn]
        D --> M[Monitor for False Positives]
        M -->|Stable| P[Promote to reject]
        M -->|Issues| F[Fix and Re-test]
        F --> T
    end
```

1. **Keep plugins fast.** Pre-merge plugins run on every merge. Aim for under 60 seconds total.
2. **Use `warn` for non-critical checks.** Reserve `reject` for checks that must pass (tests, security). Use `warn` for advisory checks (code style, documentation).
3. **Version control everything.** Plugins in `plugins/` are committed to git and reviewed like code.
4. **Test plugins independently.** Run your plugin scripts manually before deploying them.
5. **Set timeouts.** A plugin that hangs blocks the Refinery. Always set reasonable timeouts.
6. **Log results.** Write plugin output to a log file alongside exit codes. This makes debugging failed merges much easier when reviewing Refinery history.

## Next Steps

- [Operations: Plugins](/docs/operations/plugins) -- Detailed plugin operations guide
- [The Refinery](/docs/agents/refinery) -- How the Refinery processes merge requests
- [Quality Gates](/docs/concepts/gates) -- Built-in gate types and custom gates
- [Monitoring](/docs/operations/monitoring) -- Monitoring plugin execution and failures
- [The Refinery Deep Dive](/blog/refinery-deep-dive) -- How plugins integrate with the merge queue
- [Monitoring Your Fleet](/blog/monitoring-fleet) -- Monitoring plugin execution and failures
- [Custom Formulas](/blog/custom-formulas) -- Building custom formulas that leverage plugins
- [Hook-Driven Architecture](/blog/hook-driven-architecture) -- How lifecycle hooks power the plugin system
- [Configuration CLI Reference](/docs/cli-reference/configuration) — Commands for managing Gas Town configuration
