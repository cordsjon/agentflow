# Pipeline Stage Reference

## Flow Diagram

```
INBOX.md --/triage--> BACKLOG.md --/workflow--> TODO-Today.md --/autopilot--> DONE-Today.md
                         |
              Ideation -> Refining -> Ready
```

## Classification Guide

| Signal | Classification | Route |
|--------|---------------|-------|
| "it would be nice if..." | `[idea]` | Ideation |
| "X is broken / doesn't work" | `[bug]` | Ideation or Refining |
| Server down, build broken | `[hotfix]` | TODO-Today (fast-track) |
| "How does X work?" | `[question]` | Answer inline |
| CI/build/tooling improvement | `[tooling]` | Ideation |
| "We should refactor..." | `[debt]` | Ideation |
| Screenshot of error | `[bug]` | Ideation |
| Link to article/resource | `[idea]` or `[question]` | Depends |
| User correction/feedback | `[bug]` or `[idea]` | Depends |

## BACKLOG Sections

### Ideation
Raw ideas with brainstorm output pending.
```markdown
### [idea] Dark mode support
User wants dark mode for the UI.
Origin: INBOX (2026-03-11)
Next: brainstorm
```

### Refining
Has brainstorm output, spec in progress.
```markdown
### [idea] Dark mode support
Brainstorm complete: requirements/BRAINSTORM_DARK_MODE.md
Next: spec-panel critique
```

### Ready
Spec approved, DOR passed, waiting for queue.
```markdown
### [idea] Dark mode support · S · #3
Spec: requirements/SPEC_DARK_MODE.md (score: 7.5)
DOR: passed
```

## Priority Markers

- `#N` — priority number (lower = higher priority)
- Items in `## Critical Path` are locked in sequence
- `needs: X` — blocked until X ships
- `blocks: Y` — must ship before Y
