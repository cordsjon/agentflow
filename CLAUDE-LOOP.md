# The Loop — Scrumban Execution Model

> **Canonical definition.** All governed projects follow this loop.
> Include this file by reference in each project's CLAUDE.md.

---

## Pipeline Flow

```
INBOX.md ──/triage──> BACKLOG.md ──/workflow──> TODO-Today.md ──ROUTE──/autopilot──> DONE-Today.md
```

## Three Nested Loops

### Outer Loop — Queue Lifecycle (human-driven)
User or planning populates `TODO-Today.md` via `/workflow`. Every batch **always ends with a quality tail task**. Items flow: `INBOX -> BACKLOG (Ideation -> Refining -> Ready) -> /workflow -> TODO-Today`.

### Inner Loop — Autopilot (Claude-driven)
Dumb executor with lightweight routing. Reads first unchecked item, routes it, runs it, checks semaphore, loops.

1. Check `.autopilot` semaphore — `run` -> proceed, else -> **STOP**
2. **CONTEXT LOAD** — call `memory-bank:read_bank_context` to restore active context, progress, and decisions from prior iterations
3. Read first `- [ ]` task from `TODO-Today.md`
4. **ROUTE phase** — orchestrator annotates the item (see [ORCHESTRATOR.md](ORCHESTRATOR.md))
   - Assign `@agent` via capability scoring ([AGENT_CAPABILITIES.md](AGENT_CAPABILITIES.md))
   - Check stall counter on previous item
   - Scan for unblocked dependencies (cascade from last completion)
   - Preload context hints into `_Context:_` line
5. Verify task passes `DOR.md` — if not -> write to `.claude-action`, pause
6. Execute task — for US implementations, invoke `/test-driven-development` first (write failing test before implementation code per CLAUDE.md §2 rule 7)
7. Run `/verification-before-completion` — verify ACs are met with evidence (test output, screenshots) before marking task done
8. **Code Review** — run `/requesting-code-review` to self-review changed files. If review feedback surfaces issues, apply `/receiving-code-review` to evaluate and fix before proceeding
9. Enter **Cleanup Sub-Loop** (see below)
10. Commit via `/commit-smart` (atomic, per `DOD.md`)
11. If on a feature branch, run `/finishing-a-development-branch` — PR creation, branch cleanup, merge strategy
12. Move completed item to DONE-Today.md — orchestrator runs **completion cascade**
13. **CONTEXT SAVE** — run `/session-handoff` to produce HANDOVER.md with git state, modified files, decisions, open questions, and resume checklist. Also call `memory-bank:update_active_context` with current task state, blockers, next step
14. No more tasks -> write `"Queue complete"` to `.claude-action`, **STOP**

### Cleanup Sub-Loop — Quality Gate (nested inside Inner Loop)
Runs after every implementation, before every commit:
```
run greenlight -> review findings

if task size >= M (Medium or Large):
    run /production-code-audit (deep security/perf/architecture scan)

while Low findings exist:
    fix each Low finding (apply /clean-code standards during fixes)
    re-run greenlight

if Medium or High findings remain:
    write finding summary to .claude-action
    write "pause" to .autopilot
    STOP — human review required
```

---

## Key Invariants

- **No commit without greenlight** — always, no exceptions
- **Medium+ findings pause autopilot** — never downgrade, never bypass
- **Semaphore checked before EVERY task** — not just at session start
- **Update memory at session end** — run `/session-handoff` to produce HANDOVER.md. Next session must not start blind

---

## Stage Definitions

| Stage | Location | Entry Criteria | Exit Criteria | Who Moves It |
|-------|----------|---------------|---------------|-------------|
| **Inbox** | INBOX.md | Anything — raw dump | Claude triages into pipeline | User |
| **Ideation** | BACKLOG.md#Ideation | Raw idea/bug/request | `/sc:brainstorm` output exists | User or Claude |
| **Refining** | BACKLOG.md#Refining | Has brainstorm output | Spec + US + AC complete | `/sc:brainstorm` -> `/requirements-clarity` -> `/sc:spec-panel` |
| **Ready** | BACKLOG.md#Ready | Spec + US/AC approved | `/sc:workflow` generates queue | `/sc:spec-panel` score >= 7.0 |
| **Queued** | TODO-Today.md | Workflow generated | All items checked | `/sc:workflow` populates |
| **Done** | DONE-Today.md | Queue drained | Committed + deployed | Autopilot |

---

## Graduation Commands

```
Ideation -> Refining:
  /sc:brainstorm "[idea]" --depth deep
  Output: requirements doc
  Then move bullet from Ideation to Refining

Refining -> Ready:
  /requirements-clarity                (catch ambiguities before spec review)
  /sc:spec-panel requirements/[spec].md --mode critique --focus requirements
  Gate: DOR checklist + score >= 7.0 (else iterate)
  If architecture needed:
    /sc:design "[feature]" --type architecture --format spec
  Then move bullet from Refining to Ready

Ready -> Queued:
  /sc:workflow requirements/[spec].md --strategy systematic --depth deep
  Output: populates TODO-Today.md queue (always ends with quality tail)

Queue Tail (DOD enforcement — always last items):
  /sc:analyze "<changed files>" --focus quality
  /production-code-audit              (optional — M+ size tasks only)
  /sc:cleanup --type all              (enforces /clean-code standards)
  /commit-smart
  /finishing-a-development-branch     (if on feature branch — PR + merge)
  deploy
```

---

## Input Convention — `/q` prefix

**Everything the user sends is loop input by default** (bug, refinement, screenshot, error, link, text).
- No `/q` prefix -> triage it and **write TODO-Today queue item(s) FIRST — then stop**. No code changes before the queue item exists.
- `/q` prefix -> question only, answer conversationally, do NOT create queue items

**Queue-first invariant:** Even for obvious inline bugs, the sequence is always:
1. Triage -> classify
2. Write queue item to TODO-Today.md
3. STOP — autopilot picks up the queue item and implements

Never implement during triage. Never commit without a queue item having existed first.

---

## Queue Task Format

All tasks live in a single flat `## Queue` section as a checkbox list. First unchecked = next task.

**Format (3 lines per task):**
```
- [ ] **Phase: Task description**
  `/sc:command "args" --attribute`
  _Context: brief notes, file refs, links_
```

- Line 1: checkbox + **bold** phase label + task description
- Line 2: indented backtick-wrapped `/sc:` prompt — directly pasteable
- Line 3 (optional): indented italic `_Context:_` with refs, file paths, links
- **>>> NEXT** marker in blockquote above the list
- **Queue order = optimal execution sequence**

---

## Daily Kickoff

0. Read INBOX.md — triage any new items
1. Read BACKLOG.md — any Ready items? If yes, offer to `/sc:workflow` them into queue
2. Read TODO-Today.md — any unchecked items? If yes, offer to resume autopilot
3. If both empty — read ROADMAP.md, suggest what to refine next

---

## Retro Trigger

Every **10 completed stories** (counted from DONE-Today.md + archives), trigger a retrospective by invoking `/kaizen`. Do NOT use a hardcoded template — `/kaizen` guides the continuous improvement process including root cause analysis, error proofing, and standardization.

**Retro scope** (kaizen will cover these automatically):
- Workflow friction and cycle time
- Bugfixing approach quality (were root causes documented?)
- Memory file usefulness
- Inner/outer loop robustness
- Tooling gaps
- Quality gate effectiveness

Output: actionable items added to BACKLOG.md#Ideation or CLAUDE.md rule updates.
Counter tracked in project memory.
