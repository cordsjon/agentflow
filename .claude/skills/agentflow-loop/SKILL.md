---
name: agentflow-loop
description: Execute the agentflow 14-step Scrumban inner loop for autonomous task processing. Use when starting autopilot mode, processing TODO-Today queue items, or running the autonomous dev loop.
disable-model-invocation: true
---

# agentflow Inner Loop

Execute the next task from TODO-Today.md using the 14-step Scrumban loop.

## Three Nested Loops

### Outer Loop (human-driven)
User populates `TODO-Today.md` via `/agentflow-workflow`. Every batch ends with a quality tail.

### Inner Loop (agent-driven) — 14 Steps

1. **Semaphore** — check `.autopilot` file. `run` = proceed, else STOP
2. **Context load** — restore active context from prior iterations
3. **Read task** — take first unchecked `[ ]` from `## Queue` in TODO-Today.md
4. **Route** — orchestrator annotates the item (see [orchestrator reference](../agentflow-orchestrator/routing.md))
   - Assign `@agent` via capability scoring
   - Check stall counter on previous item
   - Scan for unblocked dependencies
   - Preload context hints into `_Context:_` line
5. **DOR check** — verify task passes Definition of Ready. If not, pause
6. **Execute** — implement the task. For US implementations, write failing test first (TDD)
7. **Verify ACs** — confirm all acceptance criteria pass with evidence (test output, screenshots)
8. **Code review** — self-review changed files. If issues found, evaluate and fix before proceeding
9. **Cleanup sub-loop** — see below
10. **Commit** — atomic, conventional commit
11. **Branch/PR** — if on feature branch, create PR with merge strategy
12. **Move to done** — mark `[x]` in TODO-Today, move to DONE-Today with timestamp
13. **Save context** — produce handoff with git state, decisions, open questions, resume checklist
14. **Next task** — loop back to step 1. No more tasks = STOP

### Cleanup Sub-Loop (nested inside step 9)

```
run greenlight (project test suite) -> review findings

if task size >= M (Medium or Large):
    run deep security/perf/architecture scan

while Low findings exist:
    fix each Low finding
    re-run greenlight

if Medium or High findings remain:
    write finding summary
    write "pause" to .autopilot
    STOP -- human review required
```

## Key Invariants

- **No commit without greenlight** — always, no exceptions
- **Medium+ findings pause autopilot** — never downgrade, never bypass
- **Semaphore checked before EVERY task** — not just at session start
- **Save context at session end** — next session must not start blind

## Queue Task Format

```
- [ ] **Phase: Task description** `@agent` `stall:0`
  `/command "args" --attribute`
  _Context: brief notes, file refs, links -- confidence:0.85_
```

- Line 1: checkbox + **bold** phase label + task description + optional routing metadata
- Line 2: indented command prompt — directly pasteable
- Line 3 (optional): indented italic context with refs, file paths, links
- Queue order = optimal execution sequence

## Input Convention

**Everything the user sends is loop input by default** (bug, refinement, screenshot, error, link, text).
- No `/q` prefix = triage it, write TODO-Today queue item(s) FIRST, then STOP. No code changes before the queue item exists.
- `/q` prefix = question only, answer conversationally, do NOT create queue items.

For full loop reference see [claude-loop.md](claude-loop.md).
