---
title: "Communication"
sidebar_position: 5
description: "Commands for inter-agent messaging, notifications, escalations, and broadcasts. Gas Town's communication layer is built on Erlang-inspired mailbox patterns w..."
---

# Communication

Commands for inter-agent messaging, notifications, escalations, and broadcasts. Gas Town's communication layer is built on Erlang-inspired mailbox patterns with asynchronous message passing as the default.

---

## Mail

The mail system provides asynchronous message passing between agents. Each agent has a mailbox that persists across session restarts.

### `gt mail inbox`

View incoming messages.

```bash
gt mail inbox [options]
```

**Description:** Lists messages in the current agent's inbox. Messages are stored as JSONL files and persist across restarts.

**Options:**

| Flag | Description |
|------|-------------|
| `--unread` | Show only unread messages |
| `--from <agent>` | Filter by sender |
| `--limit <n>` | Maximum number of messages to show |
| `--since <duration>` | Show messages from the last N hours/minutes |
| `--json` | Output in JSON format |

**Example:**

```bash
# View all inbox
gt mail inbox

# View unread only
gt mail inbox --unread

# Messages from the Mayor in the last hour
gt mail inbox --from mayor --since 1h
```

**Sample output:**

```
ID     FROM        TIME     READ   SUBJECT
m-001  deacon      5m ago   *      Witness myproject unresponsive
m-002  polecat     15m ago  .      gt-abc12 completed
m-003  mayor       30m ago  .      New convoy assigned: hq-cv-002
```

---

### `gt mail send`

Send a message to another agent.

```bash
gt mail send <address> [flags]
```

**Description:** Sends an asynchronous message to another agent's mailbox. The recipient will see it on their next inbox check.

**Address formats:**

| Format | Target |
|--------|--------|
| `mayor/` | Mayor inbox |
| `<rig>/witness` | Rig's Witness |
| `<rig>/refinery` | Rig's Refinery |
| `<rig>/<polecat>` | Polecat |
| `<rig>/crew/<name>` | Crew worker |
| `--human` | Special: human overseer |

**Options:**

| Flag | Description |
|------|-------------|
| `-s`, `--subject <text>` | Message subject |
| `-m`, `--body <text>` | Message body |

**Example:**

```bash
gt mail send mayor/ -s "Need guidance" -m "Blocked on API design decision for auth module"
gt mail send greenplace/witness -s "Health alert" -m "Refinery queue backing up"
```

---

### `gt mail read`

Read a specific message.

```bash
gt mail read <message-id>
```

**Description:** Displays the full content of a message and marks it as read.

**Example:**

```bash
gt mail read m-001
```

---

### `gt mail mark-read`

Mark messages as read.

```bash
gt mail mark-read <message-id>...
```

**Description:** Marks one or more messages as read.

**Example:**

```bash
gt mail mark-read m-001 m-002
```

---

### `gt mail mark-unread`

Mark messages as unread.

```bash
gt mail mark-unread <message-id>...
```

**Description:** Marks one or more messages as unread.

**Example:**

```bash
gt mail mark-unread m-003
```

---

### `gt mail peek`

Preview messages without marking them as read.

```bash
gt mail peek [message-id] [options]
```

**Description:** Shows message content without changing its read status. Without an ID, peeks at the most recent unread message.

**Options:**

| Flag | Description |
|------|-------------|
| `--count <n>` | Number of messages to peek at |

**Example:**

```bash
gt mail peek
gt mail peek m-001
gt mail peek --count 5
```

---

### `gt mail reply`

Reply to a message.

```bash
gt mail reply <message-id> [options]
```

**Description:** Sends a reply to the sender of a message, preserving the conversation thread.

**Options:**

| Flag | Description |
|------|-------------|
| `--body <text>` | Reply body |
| `--all` | Reply to all recipients in the thread |

**Example:**

```bash
gt mail reply m-001 --body "Acknowledged, restarting the witness now"
```

---

### `gt mail search`

Search messages.

```bash
gt mail search <query> [options]
```

**Description:** Full-text search across all messages in the mailbox.

**Options:**

| Flag | Description |
|------|-------------|
| `--from <agent>` | Filter by sender |
| `--since <duration>` | Search within time window |
| `--limit <n>` | Maximum results |
| `--json` | Output in JSON format |

**Example:**

```bash
gt mail search "merge conflict"
gt mail search "blocked" --from polecat --since 24h
```

---

### `gt mail thread`

View a conversation thread.

```bash
gt mail thread <message-id> [options]
```

**Description:** Shows all messages in a conversation thread, from the original message through all replies.

**Options:**

| Flag | Description |
|------|-------------|
| `--json` | Output in JSON format |

**Example:**

```bash
gt mail thread m-001
```

---

### `gt mail channel`

Manage or view named channels.

```bash
gt mail channel [name] [options]
```

**Description:** Without arguments, lists available channels. With a channel name, shows messages in that channel. Channels are named mailboxes for topic-based communication.

**Options:**

| Flag | Description |
|------|-------------|
| `--create <name>` | Create a new channel |
| `--subscribe` | Subscribe to a channel |
| `--unsubscribe` | Unsubscribe from a channel |
| `--limit <n>` | Message limit |

**Example:**

```bash
# List channels
gt mail channel

# View channel messages
gt mail channel alerts

# Create a channel
gt mail channel --create deployments
```

---

### `gt mail queue`

View the outgoing message queue.

```bash
gt mail queue [options]
```

**Description:** Shows messages that are queued for delivery but have not yet been picked up by their recipients.

**Options:**

| Flag | Description |
|------|-------------|
| `--json` | Output in JSON format |

**Example:**

```bash
gt mail queue
```

---

### `gt mail announces`

View or manage announcement messages.

```bash
gt mail announces [options]
```

**Description:** Shows broadcast announcements that have been sent to all agents. Announcements are high-visibility messages from the Mayor or Overseer.

**Options:**

| Flag | Description |
|------|-------------|
| `--since <duration>` | Filter by time |
| `--json` | Output in JSON format |

**Example:**

```bash
gt mail announces
gt mail announces --since 24h
```

---

### `gt mail archive`

Archive messages.

```bash
gt mail archive <message-id>...
```

**Description:** Archives one or more messages, removing them from the active inbox without deleting them.

**Example:**

```bash
gt mail archive m-001 m-002
```

---

### `gt mail claim`

Claim a message from a queue.

```bash
gt mail claim <queue>
```

**Description:** Claims the next available message from a shared queue for processing. The message is locked to the claiming agent until released.

**Example:**

```bash
gt mail claim work-queue
```

---

### `gt mail release`

Release a claimed queue message.

```bash
gt mail release <message-id>
```

**Description:** Releases a previously claimed message back into the queue so another agent can pick it up.

**Example:**

```bash
gt mail release m-005
```

---

### `gt mail clear`

Clear all messages from an inbox.

```bash
gt mail clear
```

**Description:** Removes all messages from the current agent's inbox.

**Example:**

```bash
gt mail clear
```

---

### `gt mail delete`

Delete messages.

```bash
gt mail delete <message-id>...
```

**Description:** Permanently deletes one or more messages from the mailbox.

**Example:**

```bash
gt mail delete m-001 m-002
```

---

### `gt mail group`

Manage mail groups.

```bash
gt mail group [name] [flags]
```

**Description:** Create and manage mail groups for sending messages to multiple agents at once.

**Example:**

```bash
gt mail group
gt mail group my-team
```

---

### `gt mail hook`

Attach mail to your hook.

```bash
gt mail hook [flags]
```

**Description:** Attaches incoming mail to the agent's hook for automated processing.

**Example:**

```bash
gt mail hook
```

---

### `gt mail check`

Check for new mail.

```bash
gt mail check
```

**Description:** Checks for new incoming mail. Primarily used by hooks to poll for messages.

**Example:**

```bash
gt mail check
```

---

## Notifications & Broadcasts

### `gt nudge`

Send a synchronous message to a worker.

```bash
gt nudge <target> [message] [flags]
```

**Description:** Universal synchronous messaging API for Gas Town worker-to-worker communication. Delivers a message directly to any worker's Claude Code session.

**Options:**

| Flag | Description |
|------|-------------|
| `--message`, `-m` | Message to send |
| `--force`, `-f` | Send even if target has DND enabled |

**Target formats:**

The target can be specified using full paths or role shortcuts:

| Format | Target |
|--------|--------|
| `<rig>/<role>` | Agent by rig and role (e.g., `greenplace/witness`) |
| `<rig>/<polecat>` | Polecat by rig and name (e.g., `greenplace/furiosa`) |
| Role shortcuts | `mayor`, `witness`, `refinery`, etc. |
| Channel syntax | Named channels for group nudges |

**Example:**

```bash
# Nudge a polecat with a message
gt nudge greenplace/furiosa "Check your mail"

# Nudge with the -m flag
gt nudge greenplace/witness -m "Check polecat alpha, appears stalled"

# Force nudge through DND
gt nudge greenplace/refinery -m "Urgent: queue backing up" --force
```

:::warning

Use nudges sparingly. They interrupt the target agent's current activity. For non-urgent messages, use `gt mail send` instead.

:::

---

### `gt broadcast`

Send a message to all workers.

```bash
gt broadcast <message> [flags]
```

**Description:** Sends a message to all workers in the town or all workers in a specific rig. Used for system-wide announcements. The message is a positional argument.

**Options:**

| Flag | Description |
|------|-------------|
| `--all` | Include all agents (mayor, witness, etc.), not just workers |
| `--dry-run` | Show what would be sent without sending |
| `--rig <name>` | Only broadcast to workers in this rig |

**Example:**

```bash
# Town-wide broadcast to all workers
gt broadcast "Maintenance window in 30 minutes, save your work"

# Rig-specific broadcast
gt broadcast "Main branch frozen for release" --rig myproject

# Include all agents, not just workers
gt broadcast "System update in progress" --all

# Preview without sending
gt broadcast "Testing broadcast" --dry-run
```

---

### `gt dnd`

Toggle do-not-disturb mode.

```bash
gt dnd [subcommand]
```

**Description:** Controls do-not-disturb mode for the current agent. Without arguments, toggles DND on or off. When enabled, suppresses non-critical notifications and nudges. Critical escalations still come through.

**Subcommands:**

| Subcommand | Description |
|------------|-------------|
| `on` | Enable do-not-disturb |
| `off` | Disable do-not-disturb |
| `status` | Show current DND status |

**Example:**

```bash
# Toggle DND
gt dnd

# Enable DND
gt dnd on

# Disable DND
gt dnd off

# Check status
gt dnd status
```

---

### `gt notify`

Control notification level for the current agent.

```bash
gt notify [level]
```

**Description:** Control the notification level for the current agent. Without arguments, shows the current notification level. With an argument, sets the level.

**Levels:**

| Level | Description |
|-------|-------------|
| `verbose` | All notifications are shown |
| `normal` | Standard notification level |
| `muted` | Suppress all notifications |

**Example:**

```bash
# Show current notification level
gt notify

# Set verbose notifications
gt notify verbose

# Set normal notifications
gt notify normal

# Mute notifications
gt notify muted
```

---

## Escalations

Escalations are priority-routed alerts for issues that need human intervention or higher-authority decisions.

### `gt escalate`

Create a new escalation.

```bash
gt escalate [description] [flags]
```

**Description:** Creates a priority-routed escalation that travels up the supervisor chain until it reaches an agent authorized to handle it. Severity levels control routing depth. The description is a positional argument.

**Options:**

| Flag | Description |
|------|-------------|
| `--severity`, `-s` | Severity level: `critical`, `high`, `medium`, `low` (default "medium") |
| `--reason`, `-r` | Detailed reason for escalation |
| `--related` | Related bead ID |
| `--source` | Source identifier (e.g., `plugin:rebuild-gt`, `patrol:deacon`) |
| `--dry-run`, `-n` | Show what would be done |
| `--json` | Output as JSON |

**Example:**

```bash
# Critical escalation
gt escalate "Production database migration failed" --severity critical

# Medium escalation with reason and related bead
gt escalate "Need design decision for API schema" -s medium -r "Blocked on auth module" --related gt-abc12

# Dry run to preview
gt escalate "Merge conflicts accumulating" -s high --dry-run
```

---

### `gt escalate list`

List all active escalations.

```bash
gt escalate list [flags]
```

**Options:**

| Flag | Description |
|------|-------------|
| `--severity <level>` | Filter by severity |
| `--status <status>` | Filter: `open`, `acked`, `closed` |
| `--json` | Output in JSON format |

**Example:**

```bash
gt escalate list
gt escalate list --severity critical --status open
```

**Sample output:**

```
ID       SEVERITY   STATUS   FROM      AGE    MESSAGE
esc-001  critical   open     witness   5m     Production DB migration failed
esc-002  medium     acked    polecat   1h     Need API schema decision
esc-003  low        open     refinery  30m    Flaky test in auth module
```

---

### `gt escalate show`

Show details of a specific escalation.

```bash
gt escalate show <escalation-id> [flags]
```

**Description:** Displays the full details of an escalation, including its history, status changes, and associated metadata.

**Options:**

| Flag | Description |
|------|-------------|
| `--json` | Output in JSON format |

**Example:**

```bash
gt escalate show esc-001
```

---

### `gt escalate ack`

Acknowledge an escalation.

```bash
gt escalate ack <escalation-id> [options]
```

**Description:** Marks an escalation as acknowledged, indicating someone is looking at it. This stops further routing up the chain.

**Options:**

| Flag | Description |
|------|-------------|
| `--message <text>` | Acknowledgment message |

**Example:**

```bash
gt escalate ack esc-001 --message "Investigating, will have fix in 15 minutes"
```

---

### `gt escalate close`

Close a resolved escalation.

```bash
gt escalate close <escalation-id> [options]
```

**Options:**

| Flag | Description |
|------|-------------|
| `--resolution <text>` | How the escalation was resolved |

**Example:**

```bash
gt escalate close esc-001 --resolution "Rolled back migration, applied fix, re-ran successfully"
```

---

### `gt escalate stale`

Find escalations that have not been acknowledged.

```bash
gt escalate stale [options]
```

**Description:** Lists escalations that have been open without acknowledgment for longer than expected, based on their severity level.

**Options:**

| Flag | Description |
|------|-------------|
| `--age <duration>` | Override stale threshold |
| `--json` | Output in JSON format |

**Example:**

```bash
gt escalate stale
gt escalate stale --age 30m
```

:::warning

Stale P0/P1 escalations indicate that critical issues are going unaddressed. These should be triaged immediately.


:::