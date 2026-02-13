---
title: "gt formula"
sidebar_position: 16
description: "Manage workflow formulas — reusable TOML/JSON templates that define multi-step molecules with variables and composition rules."
---

# gt formula

Manage workflow formulas — reusable templates that define multi-step molecules.

Formulas are TOML/JSON files that define workflows with steps, variables, and composition rules. They can be "poured" to create [molecules](../concepts/molecules.md) or "wisped" for ephemeral patrol cycles.

## Search Paths

Formulas are loaded from these locations (in priority order):

1. `.beads/formulas/` — Project-level formulas
2. `~/.beads/formulas/` — User-level formulas
3. `$GT_ROOT/.beads/formulas/` — Orchestrator-level (shared across all rigs)

When multiple formulas share the same name, the highest-priority path wins. This allows project-level overrides of shared formulas.

:::tip
Use `--dry-run` with `gt formula run` to preview what a formula will do before executing it. This is especially useful when testing custom formulas or unfamiliar workflows.
:::

## Commands

### `gt formula list`

List all available formulas from all search paths.

```bash
gt formula list            # List all formulas
gt formula list --json     # JSON output for scripting
```

**Options:**

| Flag | Description |
|------|-------------|
| `--json` | Output as JSON |

### `gt formula show <name>`

Display formula details including steps, variables, and composition rules.

```bash
gt formula show shiny              # Show the canonical workflow
gt formula show witness-patrol     # Show a patrol formula
gt formula show shiny --json       # Machine-readable output
```

**Options:**

| Flag | Description |
|------|-------------|
| `--json` | Output as JSON |

**Output includes:**

- Formula metadata (name, type, description)
- Variables with defaults and constraints
- Steps with dependency relationships
- Composition rules (extends, aspects)

### `gt formula run <name>`

Execute a formula by pouring it into a new molecule and dispatching it. Variables can be passed as flags.

```bash
# Run the canonical shiny workflow
gt formula run shiny --var feature="Add notifications"

# Run on a specific PR
gt formula run shiny --pr=123

# Run in a specific rig
gt formula run security-audit --rig=beads

# Preview what would happen without executing
gt formula run release --dry-run

# Run default formula (from rig config)
gt formula run
```

**Options:**

| Flag | Description |
|------|-------------|
| `--pr <N>` | GitHub PR number to run the formula against |
| `--rig <name>` | Target a specific rig (default: current or gastown) |
| `--dry-run` | Preview execution without actually running |

If no formula name is provided, uses the default formula configured in the rig's `settings/config.json` under `workflow.default_formula`.

### `gt formula create <name>`

Create a new formula template in the project's `.beads/formulas/` directory.

```bash
gt formula create my-task                    # Create task formula (default)
gt formula create my-workflow --type=workflow # Multi-step workflow with dependencies
gt formula create nightly-check --type=patrol # Repeating patrol cycle
```

**Options:**

| Flag | Description |
|------|-------------|
| `--type <type>` | Formula type: `task`, `workflow`, or `patrol` (default: `task`) |

## Formula Types

| Type | Purpose | Example |
|------|---------|---------|
| `task` | Single-step, one-shot work | A quick bugfix or one-off task |
| `workflow` | Multi-step sequence with dependencies | `shiny` — design, implement, review, test, submit |
| `patrol` | Repeating cycle (used for wisps) | `mol-witness-patrol` — continuous health monitoring |

:::note
If no formula name is provided to `gt formula run`, it uses the default formula from the rig's `settings/config.json` under `workflow.default_formula`. Configure this to avoid typing the formula name every time.
:::

## How Formulas Relate to Molecules

- A **formula** is a blueprint (static template)
- A **[molecule](../concepts/molecules.md)** is a live instance created from a formula
- "Pouring" a formula creates a molecule with concrete variable bindings
- Multiple molecules can be poured from the same formula simultaneously
- "Wisping" creates an ephemeral patrol molecule that repeats its cycle

## Example: The `shiny` Formula

The canonical Gas Town workflow formula:

```toml
description = "Engineer in a Box - design before you code."
formula = "shiny"
type = "workflow"
version = 1

[[steps]]
id = "design"
title = "Design {{feature}}"

[[steps]]
id = "implement"
needs = ["design"]
title = "Implement {{feature}}"

[[steps]]
id = "review"
needs = ["implement"]
title = "Review implementation"

[[steps]]
id = "test"
needs = ["review"]
title = "Test {{feature}}"

[[steps]]
id = "submit"
needs = ["test"]
title = "Submit for merge"

[vars.feature]
description = "The feature being implemented"
required = true
```

See [Formula Workflow](../workflows/formula-workflow.md) for a step-by-step guide to creating and using formulas.

## See Also

- [Molecules](../concepts/molecules.md) — Running workflow instances
- [MEOW Stack](../concepts/meow-stack.md) — The layered workflow abstraction model
- [Formula Workflow](../workflows/formula-workflow.md) — End-to-end formula usage guide
- [Convoys](convoys.md) — Parallel multi-agent workflows (convoy-type formulas)
