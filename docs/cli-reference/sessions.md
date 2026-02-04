---
title: "Session & Handoff"
sidebar_position: 8
description: "Commands for managing agent sessions, handoffs between sessions, molecules (multi-step workflows), and formulas (reusable workflow templates)."
---

# Session & Handoff

Commands for managing agent sessions, handoffs between sessions, molecules (multi-step workflows), and formulas (reusable workflow templates).

---

## Session Management

### `gt handoff`

End session and hand off to a fresh agent session.

```bash
gt handoff [bead-or-role] [options]
```

**Description:** The canonical way to end any agent session. It handles all roles: Mayor, Crew, Witness, Refinery, and Deacon respawn with a fresh Claude instance. Polecats call `gt done --status DEFERRED` instead (Witness handles lifecycle). When given a bead ID, hooks that work first, then restarts. Any molecule on the hook is auto-continued by the new session.

**Options:**

| Flag | Description |
|------|-------------|
| `--subject`, `-s` | Subject for handoff mail |
| `--message`, `-m` | Message body for handoff mail |
| `--collect`, `-c` | Auto-collect state (status, inbox, beads) into handoff message |
| `--watch`, `-w` | Switch to new session (default: `true`) |
| `--dry-run`, `-n` | Show what would be done without executing |

**Example:**

```bash
# Standard handoff
gt handoff -s "Context filling" -m "Completed 3/5 test fixes"

# Hook a bead and restart
gt handoff gt-abc12 -s "Fix the login bug"

# Auto-collect state into handoff mail
gt handoff -c

# Hand off a specific role's session
gt handoff crew
gt handoff mayor
```

:::tip[Handoff Best Practice]
Always include a clear message describing what was accomplished and what remains. The next session relies on this context to continue work effectively.
:::

---

### `gt resume`

Resume from parked work or check for handoff messages.

```bash
gt resume [options]
```

**Description:** Checks for parked work (from `gt park`) and whether its gate has cleared. If the gate is closed, restores the hook with previous work and displays context notes. With `--handoff`, checks inbox for handoff messages instead.

**Options:**

| Flag | Description |
|------|-------------|
| `--status` | Just show parked work status without resuming |
| `--handoff` | Check inbox for handoff messages instead of parked work |
| `--json` | Output in JSON format |

**Example:**

```bash
# Check for and resume parked work
gt resume

# Just show status
gt resume --status

# Check for handoff messages
gt resume --handoff
```

---

### `gt park`

Park current work on a gate for async resumption.

```bash
gt park <gate-id> [options]
```

**Description:** When waiting for an external condition (timer, CI, human approval), park your work on a gate. Saves your current hook state, adds you as a waiter on the gate, and stores context notes. After parking, exit the session safely. Use `gt resume` to check for cleared gates and continue.

**Options:**

| Flag | Description |
|------|-------------|
| `--message`, `-m` | Context notes for resumption |
| `--dry-run`, `-n` | Show what would be done without executing |

**Example:**

```bash
# Create a gate and park on it
bd gate create --await timer:30m --title "Coffee break"
gt park <gate-id> -m "Taking a break, will resume auth work"

# Park on a human approval gate
bd gate create --await human:deploy-approval
gt park <gate-id> -m "Deploy staged, awaiting approval"

# Park on a GitHub Actions gate
bd gate create --await gh:run:123456789
gt park <gate-id> -m "Waiting for CI to complete"
```

:::note
`gt park` parks work on a gate (async wait). `gt rig park` parks a rig (stops its agents). These are different commands.
:::

---

### `gt prime`

Initialize agent context for a new or resumed session.

```bash
gt prime [options]
```

**Description:** Loads the full agent context including role, identity, configuration, hook state, and CLAUDE.md instructions. This is the first command an agent runs in a new session.

**Options:**

| Flag | Description |
|------|-------------|
| `--role <role>` | Override the agent role |
| `--verbose` | Show detailed priming information |

**Example:**

```bash
# Standard prime (reads GT_ROLE from environment)
gt prime

# Prime with explicit role
gt prime --role witness
```

:::note

`gt prime` should be run after compaction, clear, or new session. It is the canonical way to restore agent identity and context.

:::

---

### `gt seance`

Inspect a completed or crashed session.

```bash
gt seance <session-id> [options]
```

**Description:** Examines the state and artifacts from a previous session, including its hook state, messages sent, activity log, and exit condition. Named after "communicating with the dead" -- useful for debugging crashed or failed sessions.

**Options:**

| Flag | Description |
|------|-------------|
| `--json` | Output in JSON format |
| `--verbose` | Show full session transcript excerpts |
| `--artifacts` | List all session artifacts |

**Example:**

```bash
gt seance sess-abc123
gt seance sess-abc123 --verbose
```

**Sample output:**

```
Session: sess-abc123
Agent: polecat/toast
Rig: myproject
Duration: 45m
Exit: COMPLETED
Hook: gt-abc12 (completed)
Messages sent: 3
Commits: 4
Branch: fix/login-bug
```

---

### `gt checkpoint`

Save a session checkpoint.

```bash
gt checkpoint [options]
```

**Description:** Saves the current session state without exiting. Creates a snapshot that can be resumed later if the session crashes or is interrupted.

**Options:**

| Flag | Description |
|------|-------------|
| `--message <text>` | Checkpoint description |
| `--name <name>` | Named checkpoint for easy reference |

**Example:**

```bash
gt checkpoint --message "Before attempting risky refactor"
gt checkpoint --name pre-migration
```

---

## Molecules

Molecules are multi-step workflow execution units. They break complex work into a directed acyclic graph (DAG) of steps that can be executed sequentially, in parallel, or with dependencies.

### `gt mol status`

Show molecule execution status.

```bash
gt mol status [options]
```

**Description:** Displays the status of the currently active molecule, including completed steps, current step, and remaining steps.

**Options:**

| Flag | Description |
|------|-------------|
| `--json` | Output in JSON format |

**Example:**

```bash
gt mol status
```

**Sample output:**

```
Molecule: auth-refactor
Status: in_progress
Progress: 3/7 steps

STEP   STATUS       DESCRIPTION              AGENT
1      completed    Create migration script   polecat/toast
2      completed    Update data models        polecat/alpha
3      completed    Migrate endpoints         polecat/bravo
4      in_progress  Update tests              polecat/charlie
5      pending      Run integration suite     -
6      pending      Update documentation      -
7      pending      Deploy to staging         -
```

---

### `gt mol current`

Show the currently executing step.

```bash
gt mol current [options]
```

**Options:**

| Flag | Description |
|------|-------------|
| `--json` | Output in JSON format |

**Example:**

```bash
gt mol current
```

---

### `gt mol progress`

Show a progress summary for the active molecule.

```bash
gt mol progress [options]
```

**Options:**

| Flag | Description |
|------|-------------|
| `--json` | Output in JSON format |

**Example:**

```bash
gt mol progress
```

---

### `gt mol step done`

Mark the current molecule step as completed.

```bash
gt mol step done [options]
```

**Description:** Marks the current step as complete and advances the molecule to the next step (or triggers parallel steps if the DAG allows).

**Options:**

| Flag | Description |
|------|-------------|
| `--message <text>` | Completion notes |
| `--output <data>` | Step output data for downstream steps |
| `--skip-next` | Skip the next step |

**Example:**

```bash
gt mol step done --message "All endpoints migrated, 47 files changed"
```

---

### `gt mol attach`

Attach a molecule to a pinned bead.

```bash
gt mol attach <molecule-id> [options]
```

**Description:** Attaches a molecule to the current agent's hook, joining the workflow execution.

**Example:**

```bash
gt mol attach mol-auth-001
```

---

### `gt mol attach-from-mail`

Attach a molecule from a mail message.

```bash
gt mol attach-from-mail <mail-id>
```

**Description:** Extracts and attaches a molecule from a mail bead. Used when work arrives via the mail system rather than direct slinging.

**Example:**

```bash
gt mol attach-from-mail hq-mail-abc
```

---

### `gt mol detach`

Detach from a molecule without stopping it.

```bash
gt mol detach [options]
```

**Description:** Removes the current agent from the molecule while allowing other agents to continue. The molecule continues execution with remaining participants.

**Example:**

```bash
gt mol detach
```

---

### `gt mol burn`

Abort and discard a molecule.

```bash
gt mol burn <molecule-id> [options]
```

**Description:** Terminates molecule execution and discards all in-progress work. Completed steps are preserved but remaining steps are cancelled.

**Options:**

| Flag | Description |
|------|-------------|
| `--force` | Skip confirmation |

**Example:**

```bash
gt mol burn mol-auth-001
gt mol burn mol-auth-001 --force
```

:::danger

Burning a molecule cancels all pending and in-progress steps. This cannot be undone.

:::

---

### `gt mol squash`

Squash molecule steps into a single work item.

```bash
gt mol squash <molecule-id> [options]
```

**Description:** Combines the outputs of all completed molecule steps into a single consolidated result. Useful when a multi-step workflow should produce a single merge request.

**Options:**

| Flag | Description |
|------|-------------|
| `--message <text>` | Squash commit message |

**Example:**

```bash
gt mol squash mol-auth-001 --message "Complete auth refactor"
```

---

### `gt mol dag`

Display the molecule's step dependency graph.

```bash
gt mol dag [molecule-id] [options]
```

**Description:** Shows the directed acyclic graph of steps, their dependencies, and current execution state. Helps visualize the workflow structure.

**Options:**

| Flag | Description |
|------|-------------|
| `--format <fmt>` | Output format: `text`, `mermaid`, `json` |

**Example:**

```bash
gt mol dag

# Generate Mermaid diagram
gt mol dag --format mermaid
```

**Sample output (text):**

```
1: Create migration script [completed]
├── 2: Update data models [completed]
│   ├── 3: Migrate endpoints [completed]
│   │   └── 4: Update tests [in_progress]
│   │       └── 5: Run integration suite [pending]
│   └── 6: Update documentation [pending]
└── 7: Deploy to staging [pending] (depends: 5, 6)
```

---

## Formulas

Formulas are reusable workflow templates that define molecule structures. They encode repeatable multi-step processes.

### `gt formula list`

List available formulas.

```bash
gt formula list [options]
```

**Options:**

| Flag | Description |
|------|-------------|
| `--json` | Output in JSON format |

**Example:**

```bash
gt formula list
```

**Sample output:**

```
NAME                 STEPS   DESCRIPTION
feature-standard     5       Standard feature development workflow
bug-fix              3       Bug fix with test and validation
refactor             7       Multi-phase refactoring pipeline
release              4       Release preparation and deployment
```

---

### `gt formula show`

Show details of a formula.

```bash
gt formula show <name> [options]
```

**Options:**

| Flag | Description |
|------|-------------|
| `--json` | Output in JSON format |

**Example:**

```bash
gt formula show feature-standard
```

---

### `gt formula run`

Execute a formula as a new molecule.

```bash
gt formula run <name> [options]
```

**Description:** Instantiates a formula into a running molecule, assigning it to the current context.

**Options:**

| Flag | Description |
|------|-------------|
| `--rig <name>` | Target rig |
| `--bead <id>` | Associated bead |
| `--param <key=value>` | Set formula parameters (repeatable) |
| `--dry-run` | Show what would happen without executing |

**Example:**

```bash
gt formula run feature-standard --rig myproject --bead gt-abc12

gt formula run refactor --param "target=auth-module" --param "scope=endpoints"

gt formula run release --dry-run
```

---

### `gt formula create`

Create a new formula.

```bash
gt formula create <name> [options]
```

**Description:** Creates a new formula template from a definition or interactively.

**Options:**

| Flag | Description |
|------|-------------|
| `--from <file>` | Load formula definition from a YAML/JSON file |
| `--from-molecule <id>` | Create a formula from an existing molecule's structure |
| `--description <text>` | Formula description |

**Example:**

```bash
# Create from a file
gt formula create my-workflow --from workflow.yaml

# Create from an existing molecule
gt formula create api-migration --from-molecule mol-auth-001 --description "API version migration workflow"
```
