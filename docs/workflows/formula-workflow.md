---
title: "Formula Workflow"
sidebar_position: 4
description: "Run structured, repeatable workflows using predefined TOML formula templates for releases, code reviews, and audits."
---

# Formula Workflow

The **Formula Workflow** uses predefined TOML templates to orchestrate structured, repeatable processes. Instead of describing work in free-form text, you select a formula that defines the exact steps, run it with variables, and let Gas Town execute the workflow. This is ideal for standardized processes like releases, design explorations, and audits.

---

## When to Use This Workflow

- You have a repeatable process with defined steps
- You want consistency across executions (every release follows the same steps)
- You want to leverage built-in formulas for code review, design, or audits
- You are creating custom workflows for your team

:::info[Prerequisites]

- Gas Town installed with at least one rig
- Formulas available in `.beads/formulas/`
- For convoy formulas: Tmux and multiple polecats

:::

## Overview

```mermaid
graph LR
    F["Formula<br/>(TOML template)"] -->|gt formula run| M["Molecule<br/>(live instance)"]
    M --> S1["Step 1: Design ✓"]
    M --> S2["Step 2: Implement ●"]
    M --> S3["Step 3: Review ○"]
    M --> S4["Step 4: Test ○"]
    M --> S5["Step 5: Submit ○"]
```

## Step-by-Step

### Step 1: Browse Available Formulas

List all available formulas in your workspace:

```bash
gt formula list
```

Example output:

```text
Name                        Type      Steps  Description
shiny                       workflow  5      Design-implement-review-test-submit
shiny-secure                workflow  6      Shiny with security audit
code-review                 convoy    10     Parallel multi-dimension code review
design                      convoy    6      Parallel design exploration
security-audit              convoy    4      Security-focused analysis
mol-polecat-work            workflow  9      Full polecat work lifecycle
rule-of-five                convoy    5      Five-perspective analysis
...
```

### Step 2: Examine a Formula

View the details of a formula before running it:

```bash
gt formula show shiny
```

This shows:

- Description and purpose
- Step sequence with dependencies
- Required and optional variables
- For convoy formulas: parallel legs and synthesis step

### Step 3: Run the Formula

Run a formula with the required variables:

```bash
# Run a simple workflow formula
gt formula run shiny --var feature="Add notification system"

# Run with multiple variables
gt formula run shiny --var feature="Add notifications" --var assignee="polecat/toast"
```

For convoy formulas with parallel execution:

```bash
# Run a code review
gt formula run code-review --pr=42

# Run a design exploration
gt formula run design --problem="Redesign the merge queue"

# Run with a specific preset
gt formula run code-review --pr=42 --preset=gate
```

### Step 4: Track Progress

Monitor the molecule's progress through its steps:

```bash
# Show molecule status
gt mol status

# Show detailed progress
gt mol progress <mol-id>

# Show the dependency graph
gt mol dag <mol-id>
```

Example progress output:

```text
Molecule: mol-shiny-x1y2z "Add notification system"
Formula: shiny v1
Progress: 2/5 steps complete

Steps:
  [✓] design          Design Add notification system
  [✓] implement       Implement Add notification system
  [●] review          Review implementation
  [ ] test            Test Add notification system
  [ ] submit          Submit for merge
```

### Step 5: Advance Steps

For workflow formulas, the assigned agent advances through steps. You can also manually mark steps:

```bash
# Mark current step as done
gt mol step done

# The next step becomes active automatically
gt mol status
```

### Step 6: Completion

When all steps are complete, the molecule finishes. For convoy formulas, the synthesis step runs after all parallel legs complete.

## Formula Types in Detail

### Workflow Formulas

Workflow formulas define a linear (or DAG) sequence of steps executed by a single agent:

```mermaid
graph LR
    A[design] --> B[implement]
    B --> C[review]
    C --> D[test]
    D --> E[submit]
```

**Built-in workflow formulas:**

| Formula | Steps | Use Case |
|---------|-------|----------|
| `shiny` | 5 | Standard: design, implement, review, test, submit |
| `shiny-secure` | 6 | Adds security audit after review |
| `shiny-enterprise` | 7+ | Full enterprise gates (human approvals) |
| `mol-polecat-work` | 9 | Complete polecat lifecycle with preflight |

**Example: The `shiny` formula**

```toml
[[steps]]
id = "design"
title = "Design {{feature}}"
description = "Think carefully about architecture..."

[[steps]]
id = "implement"
needs = ["design"]
title = "Implement {{feature}}"
description = "Write the code..."

[[steps]]
id = "review"
needs = ["implement"]
title = "Review implementation"
description = "Self-review the changes..."

[[steps]]
id = "test"
needs = ["review"]
title = "Test {{feature}}"
description = "Write and run tests..."

[[steps]]
id = "submit"
needs = ["test"]
title = "Submit for merge"
description = "Final check and submit..."
```

### Convoy Formulas

Convoy formulas spawn multiple parallel agents (legs), each working on a different dimension of a problem. A synthesis step combines the results:

```mermaid
graph TD
    Start[Formula Run] --> L1[Leg: correctness]
    Start --> L2[Leg: security]
    Start --> L3[Leg: performance]
    Start --> L4[Leg: elegance]

    L1 --> Synth[Synthesis]
    L2 --> Synth
    L3 --> Synth
    L4 --> Synth

    Synth --> Result[Unified Output]
```

**Built-in convoy formulas:**

| Formula | Legs | Use Case |
|---------|------|----------|
| `code-review` | 10 | Comprehensive code review from multiple perspectives |
| `design` | 6 | Design exploration across API, data, UX, scale, security, integration |
| `security-audit` | 4 | Focused security analysis |
| `rule-of-five` | 5 | Five-perspective general analysis |

**Code review presets:**

| Preset | Legs | Purpose |
|--------|------|---------|
| `gate` | 4 | Light review: wiring, security, smells, test-quality |
| `full` | 10 | All legs for thorough review |
| `security-focused` | 4 | Security-heavy: security, resilience, correctness, wiring |
| `refactor` | 4 | Quality focus: elegance, smells, style, commit-discipline |

```bash
# Run with a preset
gt formula run code-review --pr=42 --preset=gate

# Run specific legs only
gt formula run code-review --pr=42 --legs=security,correctness,wiring
```

## Creating Custom Formulas

### Basic Workflow Formula

Create a new TOML file in `.beads/formulas/`:

```toml
# .beads/formulas/my-release.formula.toml
description = "Release workflow for production deployment"
formula = "my-release"
type = "workflow"
version = 1

[[steps]]
id = "version-bump"
title = "Bump version to {{version}}"
description = "Update version numbers in all relevant files"

[[steps]]
id = "changelog"
title = "Update changelog"
needs = ["version-bump"]
description = "Generate and review changelog entries"

[[steps]]
id = "build"
title = "Build release artifacts"
needs = ["changelog"]
description = "Run the build pipeline and verify artifacts"

[[steps]]
id = "smoke-test"
title = "Run smoke tests"
needs = ["build"]
description = "Execute smoke test suite against built artifacts"

[[steps]]
id = "tag-release"
title = "Tag and publish v{{version}}"
needs = ["smoke-test"]
description = "Create git tag and publish release"

[vars]
[vars.version]
description = "Release version (e.g., 2.3.1)"
required = true
```

Run it:

```bash
gt formula run my-release --var version="2.3.1"
```

### Custom Convoy Formula

```toml
# .beads/formulas/incident-review.formula.toml
description = "Post-incident review from multiple perspectives"
formula = "incident-review"
type = "convoy"
version = 1

[inputs]
[inputs.incident]
description = "Incident ID or description"
type = "string"
required = true

[[legs]]
id = "timeline"
title = "Timeline Reconstruction"
focus = "What happened and when"
description = "Reconstruct the incident timeline..."

[[legs]]
id = "root-cause"
title = "Root Cause Analysis"
focus = "Why it happened"
description = "Identify the root cause..."

[[legs]]
id = "impact"
title = "Impact Assessment"
focus = "What was affected"
description = "Assess the blast radius..."

[[legs]]
id = "prevention"
title = "Prevention Plan"
focus = "How to prevent recurrence"
description = "Propose preventive measures..."

[synthesis]
title = "Incident Report"
description = "Synthesize all analyses into a unified incident report..."
depends_on = ["timeline", "root-cause", "impact", "prevention"]
```

### Formula CLI Reference

```bash
# Create a formula interactively
gt formula create my-workflow

# List all formulas
gt formula list

# Show formula details
gt formula show <name>

# Run a formula
gt formula run <name> --var key=value

# Run with preset (convoy formulas)
gt formula run <name> --preset=<preset-name>
```

## Variables and Templating

Formulas use Go `text/template` syntax for variable interpolation:

```toml
[[steps]]
title = "Implement {{.feature}}"
description = "Build the {{.feature}} feature for {{.assignee}}"
```

Variables are provided at runtime via `--var`:

```bash
gt formula run shiny --var feature="notifications" --var assignee="toast"
```

### Variable Definitions

```toml
[vars]
[vars.feature]
description = "The feature being implemented"
required = true

[vars.assignee]
description = "Who is assigned"
required = false
default = "auto"
```

| Field | Purpose |
|-------|---------|
| `description` | Explains what the variable is for |
| `required` | Whether the formula fails without it |
| `default` | Default value if not provided |

## Best Practices

:::tip[Start with Built-in Formulas]

Gas Town ships with well-tested formulas for common workflows. Try `shiny` for feature work and `code-review` for reviews before creating custom formulas.

:::

:::tip[Keep Steps Atomic]

Each step should represent one logical unit of work. If a step is too large, the agent may lose context. If too small, the overhead of step tracking outweighs the benefit.

:::

:::tip[Use Gates for External Waits]

If a step needs to wait for CI, human approval, or a timer, use a [Gate](../concepts/gates.md) instead of busy-waiting. Gates let the agent park the workflow and resume when the condition is met.

:::

:::warning[Formula Versioning]

Increment the `version` field when making breaking changes to a formula. Existing molecules poured from the old version will continue using the old step definitions.


:::

## Related

- [Molecules](../concepts/molecules.md) -- How molecules track multi-step workflows and provide crash recovery
- [Gates](../concepts/gates.md) -- Async coordination primitives used within formula steps
- [Code Review Workflow](code-review.md) -- The convoy formula for parallel multi-perspective code review
- [MEOW Stack](../concepts/meow-stack.md) -- The layered abstraction model from molecules to full orchestration