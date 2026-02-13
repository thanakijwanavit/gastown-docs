---
title: "gt formula"
sidebar_position: 16
description: "Manage workflow formulas — reusable TOML/JSON templates that define multi-step molecules with variables and composition rules."
---

# gt formula

Manage workflow formulas — reusable templates that define multi-step molecules.

Formulas are TOML/JSON files that define workflows with steps, variables, and composition rules. They can be "poured" to create [molecules](/docs/concepts/molecules) or "wisped" for ephemeral patrol cycles.

## Search Paths

Formulas are loaded from these locations (in priority order):

1. `.beads/formulas/` — Project-level formulas
2. `~/.beads/formulas/` — User-level formulas
3. `$GT_ROOT/.beads/formulas/` — Orchestrator-level (shared across all rigs)

## Commands

### `gt formula list`

List all available formulas from all search paths.

```bash
gt formula list
```

### `gt formula show <name>`

Display formula details including steps, variables, and composition rules.

```bash
gt formula show shiny
gt formula show witness-patrol
```

### `gt formula run <name>`

Execute a formula by pouring it into a new molecule and dispatching it. Variables can be passed as flags.

```bash
gt formula run shiny --pr=123
gt formula run code-review --bead=gt-abc
```

### `gt formula create <name>`

Create a new formula template in the project's `.beads/formulas/` directory.

```bash
gt formula create my-workflow
```

## How Formulas Relate to Molecules

- A **formula** is a blueprint (static template)
- A **[molecule](/docs/concepts/molecules)** is a live instance created from a formula
- "Pouring" a formula creates a molecule with concrete variable bindings
- Multiple molecules can be poured from the same formula simultaneously

See [Formula Workflow](/docs/workflows/formula-workflow) for a step-by-step guide to creating and using formulas.

## See Also

- [Molecules](/docs/concepts/molecules) — Running workflow instances
- [MEOW Stack](/docs/concepts/meow-stack) — The layered workflow abstraction model
- [Formula Workflow](/docs/workflows/formula-workflow) — End-to-end formula usage guide
