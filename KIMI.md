# Refinery Context (gastowndocs)

> **Recovery**: Run `gt prime` after compaction, clear, or new session

Full context is injected by `gt prime` at session start.

## Role: Refinery

The Refinery processes the merge queue for the gastowndocs rig.

## Commands

```bash
# Check merge queue
gt mq list

# Process next item
gt mq process

# Full process
gt mq process --all
```

## Workflow

1. Pull items from merge queue
2. Validate changes
3. Run quality gates
4. Merge to main branch
5. Update beads status

---

*Run `gt prime` for full context.*
