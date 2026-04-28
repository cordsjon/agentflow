---
name: sh-handoff
description: "Use when session context is heavy (>20 tool calls), before switching to an unrelated task, or when handing off to a fresh session"
---

# Handoff — Context Save

Produce a `HANDOVER.md` document that captures the full session state so the next session (or agent) can resume without context loss.

## When to Run

- At the end of every `/sh:loop` iteration (step 13)
- Before `/sh:autopilot` stops (queue complete or paused)
- On manual session end
- When switching between agents or worktrees

## Filename

`HANDOVER-{PROJECT}-{YYYY-MM-DD-HHmm}.md` in the project root (or `00_Governance/` for cross-project sessions).

**Examples:** `HANDOVER-75_Coaching-2026-04-27-1557.md`, `HANDOVER-30_SVG-PAINT-2026-04-27-2230.md`

Never overwrite an existing handover — each session gets its own file.

## Template

```markdown
# HANDOVER — [project] — [date] [time]

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
- [ ] Query QMD for project context before exploring codebase
- [ ] Check `.autopilot` semaphore state
- [ ] Review TODO-Today.md queue
- [ ] Verify git state matches above
- [ ] Continue from next unchecked item
```

## Process

1. **Gather state** — read TODO-Today.md, DONE-Today.md, git status, git log
2. **Capture decisions** — any architectural choices, tradeoffs, or interpretations made
3. **Note open questions** — anything that needs human input or clarification
4. **Re-index QMD** — QMD is the default first-read method for all markdown discovery. The next session depends on QMD being current.
   ```bash
   # Trigger re-index for the active project's collection
   curl -s http://localhost:3131/api/reindex -X POST -H 'Content-Type: application/json' \
     -d '{"collection": "<active-project-collection>"}' 2>/dev/null || echo "QMD reindex skipped"
   ```
   Then verify with a QMD query for a document you created or modified this session:
   ```
   mcp__qmd__query searches=[{"type": "lex", "query": "<title or keyword from session doc>"}]
     collections=["<active-project-collection>"] limit=3
   ```
   If the document doesn't appear, warn in HANDOVER.md under Open Questions: "QMD index may be stale — verify after session."
5. **Write HANDOVER-{PROJECT}-{YYYY-MM-DD-HHmm}.md** — in project root (or `00_Governance/` for cross-project sessions). Never overwrite an existing file.
6. **Update memory** — persist key decisions to `.claude/memory.md` if not already there

## Session Attribution (always runs)

After writing HANDOVER.md, attribute this session's primary project for the token burn dashboard:

```bash
mkdir -p ~/.local/state/codeburn
SESSION_ID=$(basename "$(ls -t ~/.claude/projects/-Users-jcords-macmini-projects/*.jsonl | head -1)" .jsonl)
echo "{\"session_id\": \"$SESSION_ID\", \"project\": \"<canonical project name>\", \"date\": \"$(date +%Y-%m-%d)\"}" >> ~/.local/state/codeburn/session-projects.jsonl
```

Determine the primary project from the session's work (DONE-Today entries, git activity, file paths touched). Use canonical names (`30_SVG-PAINT`, `50_KETO`, `20_CONSIGLIERE`, etc.).

## Key Rules

- **Never overwrite** — each session writes a new uniquely named file; old handovers accumulate as history
- Git state must be captured from actual `git status` and `git log` output, not assumed
- If autopilot is pausing due to findings, include the finding summary in Open Questions
- The resume checklist is fixed — always include all 6 items
- QMD indexing of session additions is mandatory before writing HANDOVER.md — the next session depends on QMD for context
