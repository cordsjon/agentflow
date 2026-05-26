---
name: agentflow-triage
description: Triage raw input from INBOX.md into the Scrumban pipeline. Use when processing new ideas, bugs, feature requests, or any unstructured input that needs to be classified and routed to the correct pipeline stage.
disable-model-invocation: true
---

# Triage — INBOX to Pipeline

Process raw input and route it into the correct pipeline stage.

## Pipeline Flow

```
INBOX.md --> BACKLOG.md (Ideation --> Refining --> Ready) --> TODO-Today.md --> DONE-Today.md
```

## Triage Steps

1. **Read INBOX.md** — scan for untriaged items (any line without a stage marker)
2. **Classify each item:**

| Classification | Route To | Criteria |
|---------------|----------|----------|
| `[idea]` | BACKLOG#Ideation | New feature, enhancement, exploration |
| `[bug]` | BACKLOG#Ideation or #Refining | Defect with reproduction steps |
| `[hotfix]` | TODO-Today (fast-track) | Actively blocking development |
| `[question]` | Answer inline, no queue item | Clarification needed, no action |
| `[tooling]` | BACKLOG#Ideation | Build, CI, dev experience improvement |
| `[debt]` | BACKLOG#Ideation | Technical debt, refactoring need |

3. **Write the BACKLOG entry** with classification tag, brief description, and `Next:` action
4. **Remove from INBOX** — item moves, it doesn't copy
5. **STOP** — never implement during triage

## Queue-First Invariant

Even for obvious inline bugs, the sequence is always:
1. Triage -> classify
2. Write queue item (BACKLOG or TODO-Today for hotfix)
3. STOP

**Never implement during triage. Never commit without a queue item having existed first.**

## BACKLOG Entry Format

```markdown
### [classification] Brief title
Description of the item.
Origin: INBOX (date)
Next: /sc:brainstorm (or appropriate next action)
```

## Hotfix Fast-Track

If classified as `[hotfix]` (actively blocking):
1. Verify Bug DOR-lite passes (see `/agentflow-dor`)
2. Move directly to TODO-Today.md as next queue item
3. Skip Ideation/Refining stages

See [pipeline.md](pipeline.md) for full stage definitions.
