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

Hand off work to a new session.

```bash
gt handoff [flags]
```

**Description:** Performs a graceful session transition, handling all roles. For polecats it calls `gt done --status DEFERRED`. When given a bead ID, hooks that work first then restarts. When given a role name, hands off that role's session. The current session saves its state into a handoff message, then exits. The next session picks up from where the previous one left off. This is the standard way to deal with context limits.

**Options:**

| Flag | Short | Description |
|------|-------|-------------|
| `--subject` | `-s` | Subject for handoff mail |
| `--message` | `-m` | Message body for handoff mail |
| `--collect` | `-c` | Auto-collect state (status, inbox, beads) into handoff message |
| `--dry-run` | `-n` | Show what would be done without executing |
| `--watch` | `-w` | Switch to new session (for remote handoff, default true) |

**Example:**

```bash
# Standard handoff with message
gt handoff -m "Completed 3/5 test fixes, remaining: auth_test.go and api_test.go"

# Handoff with auto-collected state
gt handoff -c -m "At step 3 of molecule, next: run integration tests"

# Handoff a specific bead (hooks it first, then restarts)
gt handoff gt-abc12

# Handoff a specific role's session
gt handoff witness

# Dry run to preview
gt handoff -n -m "Preview handoff"
```

:::tip[Handoff Best Practice]

Always include a clear message describing what was accomplished and what remains. The next session relies on this context to continue work effectively. Use `--collect` to automatically include status, inbox, and bead information.

:::

---

### `gt resume`

Resume work that was parked on a gate, or check for handoff messages.

```bash
gt resume [flags]
```

**Description:** Checks for parked work (from `gt park`) and whether its gate has cleared. Can also check for handoff messages from other sessions.

**Options:**

| Flag | Description |
|------|-------------|
| `--handoff` | Check for handoff messages instead of parked work |
| `--status` | Just show parked work status without resuming |
| `--json` | Output as JSON |

**Example:**

```bash
# Resume parked work (checks if gate has cleared)
gt resume

# Just check status of parked work
gt resume --status

# Check for handoff messages
gt resume --handoff

# Output as JSON
gt resume --json
```

---

### `gt park`

Park current work on a gate, allowing the agent to exit safely.

```bash
gt park <gate-id> [flags]
```

**Description:** When you need to wait for an external condition (timer, CI, human approval), park your work on a gate. The agent can then exit safely, and `gt resume` will check if the gate has cleared.

**Options:**

| Flag | Short | Description |
|------|-------|-------------|
| `--message` | `-m` | Context notes for resumption |
| `--dry-run` | `-n` | Show what would be done without executing |

**Example:**

```bash
# Create a timer gate and park on it
gt gate create timer --duration 30m
gt park gate-abc123 -m "Waiting for CI pipeline to complete"

# Park on an existing gate with dry run
gt park gate-def456 -n

# Park with context notes
gt park gate-ghi789 -m "Waiting for human approval on PR #42"
```

---

### `gt prime`

Detect the agent role from the current directory and output context.

```bash
gt prime [flags]
```

**Description:** Detects the agent role from the current directory and outputs the full agent context including role, identity, configuration, hook state, and CLAUDE.md instructions. This is the first command an agent runs in a new session.

**Options:**

| Flag | Description |
|------|-------------|
| `--hook` | Hook mode: read session ID from stdin JSON (for LLM runtime hooks) |
| `--dry-run` | Show what would be injected without side effects |
| `--explain` | Show why each section was included |
| `--state` | Show detected session state only |
| `--json` | Output state as JSON (requires `--state`) |

**Example:**

```bash
# Standard prime (detects role from current directory)
gt prime

# Show what would be injected without side effects
gt prime --dry-run

# Show why each context section was included
gt prime --explain

# Show detected session state
gt prime --state

# Output state as JSON
gt prime --state --json
```

:::note

`gt prime` should be run after compaction, clear, or new session. It is the canonical way to restore agent identity and context.

:::

---

### `gt seance`

Talk to predecessor sessions.

```bash
gt seance [flags]
```

**Description:** Seance lets you literally talk to predecessor sessions. Instead of parsing logs, seance spawns a Claude subprocess that resumes a predecessor session with full context. Without flags, lists recent sessions.

**Options:**

| Flag | Short | Description |
|------|-------|-------------|
| `--talk` | `-t` | Session ID to commune with |
| `--prompt` | `-p` | One-shot prompt (with `--talk`) |
| `--recent` | `-n` | Number of recent sessions to show (default 20) |
| `--rig` | | Filter by rig name |
| `--role` | | Filter by role |
| `--json` | | Output as JSON |

**Example:**

```bash
# List recent sessions
gt seance

# List sessions filtered by rig
gt seance --rig myproject

# Talk to a predecessor session
gt seance -t sess-abc123

# One-shot question to a predecessor session
gt seance -t sess-abc123 -p "What was the root cause of the auth bug?"

# List recent sessions as JSON
gt seance --json --recent 10
```

---

### `gt checkpoint`

Manage checkpoints for polecat session crash recovery.

```bash
gt checkpoint <subcommand>
```

**Description:** Checkpoints capture current work state so that if a session crashes, the next session can resume. This is not a direct command -- it has subcommands for writing, reading, and clearing checkpoints.

**Subcommands:**

| Subcommand | Description |
|------------|-------------|
| `gt checkpoint write` | Write a checkpoint of current session state |
| `gt checkpoint read` | Read and display the current checkpoint |
| `gt checkpoint clear` | Clear the checkpoint file |

**Example:**

```bash
# Write a checkpoint of current state
gt checkpoint write

# Read the current checkpoint
gt checkpoint read

# Clear the checkpoint file
gt checkpoint clear
```

---

## Molecules

Molecules are multi-step workflow execution units. They break complex work into a directed acyclic graph (DAG) of steps that can be executed sequentially, in parallel, or with dependencies.

**Aliases:** `gt mol`, `gt molecule`

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

`gt mol step` is a subcommand of `gt mol` with its own sub-subcommand `done`.

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

Attach to a running molecule.

```bash
gt mol attach <molecule-id> [options]
```

**Description:** Attaches the current agent to an active molecule, joining the workflow execution.

**Example:**

```bash
gt mol attach mol-auth-001
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

### `gt mol attach-from-mail`

Attach to a molecule from a mail message.

```bash
gt mol attach-from-mail [options]
```

**Description:** Attaches the current agent to a molecule based on information from a received mail message.

**Example:**

```bash
gt mol attach-from-mail
```

---

### `gt mol attachment`

Manage molecule attachments.

```bash
gt mol attachment [options]
```

**Description:** Work with attachments associated with the current molecule.

**Example:**

```bash
gt mol attachment
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
