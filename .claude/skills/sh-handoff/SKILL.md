---
name: sh:handoff
description: Save session context to HANDOVER.md for seamless continuation. Captures last task, queue position, git state, decisions, and resume checklist.
---

# Handoff — Context Save

Produce a `HANDOVER.md` document that captures the full session state so the next session (or agent) can resume without context loss.

## When to Run

- At the end of every `/sh:loop` iteration (step 13)
- Before `/sh:autopilot` stops (queue complete or paused)
- On manual session end
- When switching between agents or worktrees

## HANDOVER.md Template

```markdown
# HANDOVER — [date] [time]

## Last Completed Task
- **Task:** [task description from TODO-Today]
- **Status:** [completed | paused | blocked]
- **Outcome:** [1-2 sentence summary of what was done]

## Queue Position
- **Completed:** N of M total
- **Remaining:** [count] items in TODO-Today.md
- **Next up:** [first unchecked item description]

## Git State
- **Branch:** [current branch name]
- **Last commit:** [SHA + message]
- **Modified files:** [list of uncommitted changes, or "clean"]
- **Unpushed commits:** [count, or "all pushed"]

## Decisions Made This Iteration
- [Decision 1: what was decided and why]
- [Decision 2: ...]

## Open Questions
- [ ] [Question requiring human input]
- [ ] [Ambiguity encountered during execution]

## Resume Checklist
- [ ] Read this HANDOVER.md
- [ ] Check `.autopilot` semaphore state
- [ ] Review TODO-Today.md queue
- [ ] Verify git state matches above
- [ ] Continue from next unchecked item
```

## Process

1. **Gather state** — read TODO-Today.md, DONE-Today.md, git status, git log
2. **Capture decisions** — any architectural choices, tradeoffs, or interpretations made
3. **Note open questions** — anything that needs human input or clarification
4. **Write HANDOVER.md** — in project root, overwriting any previous handover
5. **Update memory** — persist key decisions to `.claude/memory.md` if not already there

## Key Rules

- HANDOVER.md is always overwritten (not appended) — it represents current state only
- Git state must be captured from actual `git status` and `git log` output, not assumed
- If autopilot is pausing due to findings, include the finding summary in Open Questions
- The resume checklist is fixed — always include all 5 items
