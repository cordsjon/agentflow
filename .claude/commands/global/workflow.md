---
name: workflow
description: Use to convert BACKLOG.md#Ready items into an executable TODO-Today task queue. Runs DOR gate, decomposes into atomic tasks, appends quality tail, and marks items as converted. This is the Outer Loop population step — it feeds the Inner Loop (autopilot).
---

# /workflow — Backlog → TODO-Today Converter

Convert `BACKLOG.md#Ready` items into an executable TODO-Today task queue.
This is the Outer Loop population step — it feeds the Inner Loop (autopilot).

---

## Protocol

### Step 1 — Read Ready items
Read `BACKLOG.md#Ready`. Identify item(s) to convert.
If Ready is empty → report "No Ready items — check BACKLOG#Refining" and STOP.

### Step 2 — DOR gate
Detect item type: `[bug]` / `[hotfix]` items use **Bug DOR-lite** (see `DOR.md`); all other items use full DOR.

- Full DOR passes → proceed to Step 3
- Full DOR fails → move item back to `BACKLOG.md#Refining` with a note on the specific gap. STOP for that item.
- Bug DOR-lite: check root cause documented + fix plan + regression test named. Fails → STOP, note gap.

### Step 3 — Break into atomic tasks

**Feature items:**
Decompose into tasks where each task:
- Maps to one User Story (or one AC within a US)
- Results in one atomic commit
- Has a clear test file target
- Fits within a single working session

**Bug items (`[bug]` or `[hotfix]`):**
Use this task format (no US reference required — root cause replaces it):
```markdown
- [ ] **[BUG] One-line description**
  - Root cause: [specific file/mechanism — from DOR-lite]
  - Fix: [1-3 concrete steps]
  - Regression test: [test file + test name]
  - Risk: CLAUDE.md §3.[N]
```

Maximum 10 tasks per batch. If more are needed, split into phases.

### Step 4 — Always add quality tail

**Feature items:** last task in every batch must be:
```
- [ ] **Quality tail: greenlight + cleanup**
  - AC: `greenlight --all` 100% green, no Medium+ findings
  - Test: existing suite
  - Risk: §3.4 Explicit Exceptions
```

**Bug items:** last two tasks must be (in order):
```
- [ ] **Quality tail: greenlight + cleanup**
  - AC: `greenlight --all` 100% green, no Medium+ findings
  - Test: existing suite
  - Risk: §3.4 Explicit Exceptions
- [ ] **[BUG] Doc tail: QUALITY_AUDIT.md + KNOWN_PATTERNS.md**
  - AC: ≥1 new finding in QUALITY_AUDIT.md; pattern added to KNOWN_PATTERNS.md if root cause is reusable
  - Test: n/a — documentation review
  - Risk: CLAUDE.md §3.12 (document bug learnings)
```

### Step 5 — Write to TODO-Today.md
Append tasks to `TODO-Today.md#Queue` using this format:
```markdown
- [ ] **[US-X.Y] Task description**
  - AC: [what done looks like — testable statement]
  - Test: tests/test_epicX_feature.py
  - Risk: CLAUDE.md §3.[N] [Commandment name]
```
For `[BUG]` tasks, use the bug format from Step 3 instead.

### Step 6 — Remove from BACKLOG
Move the processed item from `BACKLOG.md#Ready` — mark it as `→ TODO-Today (YYYY-MM-DD)`.

### Step 7 — Report
```
Converted: [item name]
Tasks added to TODO-Today: [N]
Quality tail: ✓ appended
DOR: ✓ all tasks passed
```

---

## Rules

- Every batch ends with a quality tail task — no exceptions
- Bug batches end with two tail tasks: greenlight tail + doc tail — both mandatory
- Feature tasks require a User Story reference; bug tasks require root cause + regression test instead
- Never skip the DOR gate — features that fail full DOR and bugs that fail DOR-lite go back to Refining
- Never add more than 10 tasks per batch — split large items into phases
- Both tail tasks count toward the 10-task limit

## Dry Run

When `--dry-run` is passed, **do not modify any files**. Instead, output a synopsis:

| Action | Target | What Would Change |
|--------|--------|-------------------|
| read | `BACKLOG.md#Ready` | Identify item(s) to convert |
| check | DOR gate | Validate readiness (full DOR or Bug DOR-lite) |
| decompose | Ready item | List atomic tasks that would be created (max 10) |
| write | `TODO-Today.md#Queue` | Task queue entries that would be appended |
| append | quality/doc tail | Tail tasks that would be added |
| update | `BACKLOG.md#Ready` | Item marked as `→ TODO-Today (date)` |

Include the Ready item name, DOR status, estimated task count, and task descriptions.
End with confidence: **High** (DOR passes, clear decomposition), **Medium** (DOR borderline), or **Low** (no Ready items or DOR fails).
