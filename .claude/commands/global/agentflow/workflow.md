---
name: agentflow-workflow
description: Generate TODO-Today queue from BACKLOG Ready items. Use when populating the execution queue, starting a new batch of work, or converting Ready backlog items into actionable queue tasks.
disable-model-invocation: true
argument-hint: [spec-file-or-backlog-item]
---

# Workflow — Ready to Queue

Convert BACKLOG#Ready items into TODO-Today.md queue tasks.

## Steps

1. **Read BACKLOG.md#Ready** — identify items eligible for queuing
2. **Priority order:**
   - Critical Path items first (locked sequence, cannot be reordered)
   - Then `#N` numbered items (lower number = higher priority)
   - Then unnumbered items (FIFO)
3. **Dependency check:** Skip any item with `needs: X` if X is not yet in DONE-Today or archives
4. **DOR gate:** Verify each item passes Definition of Ready before generating queue items
5. **Generate queue** in TODO-Today.md `## Queue` section
6. **Always append quality tail** as final items in every batch

## Queue Task Format

```markdown
> **>>> NEXT**

## Queue

- [ ] **Phase: Task description**
  `/command "args" --attribute`
  _Context: brief notes, file refs, links_
```

- Queue order = optimal execution sequence
- First unchecked `[ ]` = next task for autopilot
- Bold phase label: implement, test, refactor, spike, docs, etc.

## Mandatory Quality Tail

Every batch MUST end with these items:

```markdown
- [ ] **analyze: Quality scan of changed files**
  `/sc:analyze "<changed files>" --focus quality`
- [ ] **cleanup: Fix findings and enforce standards**
  `/sc:cleanup --type all`
- [ ] **commit: Atomic conventional commit**
  `/commit-smart`
- [ ] **deploy: Run deployment**
  `deploy`
```

For M+ size tasks, insert deep audit before cleanup:
```markdown
- [ ] **audit: Deep security/perf/architecture scan**
  `/production-code-audit`
```

## Dependency Tracking

Inline format in BACKLOG items:
- `needs: X` — item is blocked until X ships
- `blocks: Y` — this item must ship before Y

When an item completes, check if it unblocks any `needs:` items and suggest queuing them next.

## Arguments

- `$ARGUMENTS` — optional path to spec file or BACKLOG item name
- If provided, generate queue specifically for that item
- If omitted, process all Ready items in priority order

See [queue-format.md](queue-format.md) for detailed format reference.
