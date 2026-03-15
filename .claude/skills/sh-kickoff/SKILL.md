---
name: sh:kickoff
description: "Daily session startup scan — assess pipeline state and determine next actions."
disable-model-invocation: true
---

# Daily Kickoff

Run at the start of each working session to understand pipeline state and determine next actions.

## Steps (in order)

### 0. Scan INBOX
Read INBOX.md for untriaged items. If any exist, offer to run `/sh:triage`.

### 1. Check BACKLOG Ready
Read BACKLOG.md#Ready for items waiting to be queued. If any exist, offer to run `/sh:workflow`.

### 2. Check TODO-Today
Read TODO-Today.md for unchecked `[ ]` items. If any exist, offer to resume `/sh:autopilot`.

### 3. If Everything Empty
Read ROADMAP.md and suggest what to refine next. Surface any items approaching staleness.

## Additional Checks

- **Staleness scan:** Flag items in Ideation > 2 weeks without graduation
- **Staleness scan:** Flag items in Refining > 2 weeks without spec or graduation
- **Orphan detection:** Flag items with no `Next:` action, no owner, no linked spec
- **Risk review:** Surface any risks from BACKLOG#Risks that relate to current work
- **Retro check:** If retro counter >= 10, trigger `/sh:retro` before starting work
- **Memory check:** Read `.claude/memory.md` for context from previous sessions

## Output

Report the pipeline state concisely:

```
## Kickoff -- [date]

- INBOX: N untriaged items
- BACKLOG: N in Ideation, N in Refining, N Ready
- TODO-Today: N queued, N done
- Retro counter: N/10
- Stale items: [list or "none"]
- Recommendation: [next action with /sh: command]
```
