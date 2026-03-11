# Full Loop Reference

This is the complete loop specification extracted from CLAUDE-LOOP.md.

## Stage Definitions

| Stage | Location | Entry Criteria | Exit Criteria | Who Moves It |
|-------|----------|---------------|---------------|-------------|
| **Inbox** | INBOX.md | Anything — raw dump | Triaged into pipeline | User |
| **Ideation** | BACKLOG.md#Ideation | Raw idea/bug/request | Brainstorm output exists | User or Agent |
| **Refining** | BACKLOG.md#Refining | Has brainstorm output | Spec + US + AC complete | Brainstorm -> requirements -> spec-panel |
| **Ready** | BACKLOG.md#Ready | Spec + US/AC approved | Workflow generates queue | Spec-panel score >= 7.0 |
| **Queued** | TODO-Today.md | Workflow generated | All items checked | Workflow populates |
| **Done** | DONE-Today.md | Queue drained | Committed + deployed | Autopilot |

## Graduation Commands

```
Ideation -> Refining:
  Brainstorm the idea in depth
  Output: requirements doc
  Then move bullet from Ideation to Refining

Refining -> Ready:
  Catch ambiguities in requirements
  Run spec panel critique (gate: score >= 7.0)
  If architecture needed: create design spec
  Then move bullet from Refining to Ready

Ready -> Queued:
  Run workflow to populate TODO-Today.md queue
  Output: queue items (always ends with quality tail)

Queue Tail (DOD enforcement — always last items):
  1. Analyze changed files
  2. Deep audit (M+ only)
  3. Cleanup
  4. Commit
  5. Deploy
```

## Skill Chain Quick Reference

| Chain | Skills | Trigger |
|-------|--------|---------|
| Graduation | brainstorm -> requirements -> spec-panel -> workflow | New idea |
| Implementation | TDD -> verify -> review -> receive-review | Queue task |
| Quality Tail | analyze -> audit -> cleanup -> commit -> branch | Before commit |
| Context | session-handoff | Session ending |
| Retro | kaizen | Every 10 US |
