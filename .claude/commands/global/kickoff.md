---
name: kickoff
description: "Use at session start or when resuming work — before reading pipeline files or picking the next task"
---

# /kickoff — Daily Kickoff

Automated daily kickoff sequence. Scans all pipeline files, auto-cleans shipped items,
and produces a single actionable summary.
Replaces manually reading 4+ files at session start.

**Target:** Session start → first productive action in <2 minutes.

---

## Protocol

### Step 1 — Scan pipeline files

Read these files (all reads in parallel):

1. `INBOX.md` — count untriaged bullet items below the `---` separator
2. `BACKLOG.md` — count items in each section (Ideation, Refining, Ready). For Ready items, extract title + `#N` priority
3. `TODO-Today.md` — count unchecked `- [ ]` items. Extract the first unchecked item as "next task"
4. `DONE-Today.md` — count items completed today (items with today's date or HH:MM timestamps)
5. `MEMORY.md` — read `retro_stories_since_last` counter

### Step 2 — Auto-groom backlog

Lightweight grooming pass that runs automatically every kickoff. Prevents zombie accumulation.

**2a. Archive shipped items (write):**
Scan `BACKLOG.md` for struck-through (`~~`) items and items marked SHIPPED/FIXED/RESOLVED/SUPERSEDED/DONE/Parked.
For each found:
- Append a 1-line summary to `done/BACKLOG-ARCHIVE.md` under a `### Grooming Pass {YYYY-MM-DD}` header (create header only if items found, reuse if today's header already exists)
- Remove the item (and all its indented sub-lines) from `BACKLOG.md`
- Count removals per section

**2b. Duplicate scan (read-only):**
Within each section, check for items that share a title keyword match (same feature name appearing in 2+ bullets). Flag duplicates in the report — do NOT auto-merge (merging requires human judgement).

**2c. Quick staleness flag (read-only):**
For active (non-struck-through) items only:
- Ideation items with a date > 14 days ago → flag as stale
- Refining items with a date > 14 days ago and no spec link → flag as stale
- Items referencing deprecated platforms (PowerShell `.ps1`, `D:\`, WinForms) on macOS → flag as platform-blocked

**2d. Report:**
```
GROOMING:    {N} archived ({N} Ideation, {N} Refining, {N} Ready)
             {N} stale · {N} duplicates · {N} platform-blocked
             (or "Clean — no action needed")
```

If 0 items found across all checks, print the "Clean" variant and skip the detail lines.

### Step 2f — Paperclip ↔ BACKLOG sync (write)

```bash
python3 ~/projects/00_Governance/scripts/paperclip_backlog_sync.py
```

Reconcile drift accumulated since last lightsout. Reads Paperclip for `done` issues with `US-XX-NN` ids, ticks matching ACs in `BACKLOG.md`, rewrites State lines to `SHIPPED (GET-N done YYYY-MM-DD)`. Idempotent — skips blocks already containing `SHIPPED`. Include the reconcile count in the kickoff summary if non-zero.

### Step 2e — QMD context scan (read-only)

Query QMD for recent activity in the active project's collection to surface specs, plans, and design docs the next task may depend on. This replaces manually grepping for markdown files.

```
mcp__qmd__query searches=[
  {"type": "lex", "query": "spec plan design"},
  {"type": "vec", "query": "recent implementation plan or spec for current sprint"}
] collections=["<active-project-collection>"] limit=5
```

- Use the project's QMD collection name (e.g., `svg-paint`, `consigliere`, `keto`, `poster-engine`, `governance`)
- If the project has no QMD collection, skip silently
- Include top 3 results (title + file path) in the summary under `CONTEXT:`
- This gives the session awareness of recent design decisions without reading full files

### Step 3 — Check governance state

6. `.autopilot` — read semaphore state (`run` / `pause` / missing)
7. Cross-project priority check via QMD (not hardcoded file read):
   ```
   mcp__qmd__query searches=[
     {"type": "lex", "query": "Ready priority cross-project"},
     {"type": "vec", "query": "high priority cross-project backlog items that outrank local work"}
   ] collections=["governance"] limit=5
   ```
   Flag any governance-level Ready items that outrank the local project queue.

### Step 4 — Produce summary

Print this summary (adapt counts from actual data):

```
KICKOFF — SVG-PAINT — {YYYY-MM-DD}
════════════════════════════════════════
INBOX:       {N} untriaged items
BACKLOG:     {N} Ideation · {N} Refining · {N} Ready
GROOMING:    {grooming summary from Step 2d}
QUEUE:       {N} unchecked ({N} done today)
AUTOPILOT:   {state}
RETRO:       {N}/10 stories until next retro
CONTEXT:     {top 3 QMD results: title (file), or "No recent docs"}
════════════════════════════════════════
```

### Step 5 — Suggest next action

Based on the state, suggest exactly ONE next action:

| Condition | Suggestion |
|-----------|-----------|
| INBOX has items | "→ Run `/triage` to process {N} INBOX items" |
| INBOX empty + Ready items exist + Queue empty | "→ Run `/workflow` to queue {N} Ready items (#{N}: {title})" |
| Queue has unchecked items | "→ Resume queue. Next: **{task description}**" |
| Queue has unchecked + autopilot=run | "→ Autopilot is active. Next task: **{task description}**" |
| Queue has unchecked + autopilot=pause | "→ Autopilot paused. Write `run` to `.autopilot` to resume, or pick up manually" |
| Everything empty | "→ Check ROADMAP.md for next initiative to refine" |
| Retro counter >= 10 | "→ **Retro due!** Run `/kaizen` before starting next task" |
| Governance BACKLOG has higher-priority items | "→ **Cross-project priority:** {item} outranks local queue" |
| Stale items > 5 | "→ Run `/backlog-grooming` for full staleness + orphan review" |

If multiple conditions apply, prioritize: retro due > cross-project > INBOX > Queue > Ready > stale > empty.

### Step 6 — STOP

Never start implementation. The user decides what to do based on the summary.

---

## Rules

- Step 2a (archive) is the ONLY write operation — all other steps are read-only
- All file reads in parallel for speed
- Summary format is fixed — don't add prose or explanations
- Exactly ONE suggested next action — don't overwhelm with choices
- If a file doesn't exist or is empty, report 0 for that section
- If DONE-Today.md has items but no timestamps, count all items
- Archive pass is idempotent — running twice produces the same result
- Never modify active (non-struck-through) items
- Never change priorities (`#N` ordering is human-owned)
- For full staleness/orphan/dependency analysis, use `/backlog-grooming`

## Dry Run

When `--dry-run` is passed, **do not scan files or archive items**. Instead, output a synopsis:

| Action | Target | What Would Change |
|--------|--------|-------------------|
| read | `INBOX.md`, `BACKLOG.md`, `TODO-Today.md`, `DONE-Today.md`, `MEMORY.md` | Parallel pipeline file scan |
| archive | `BACKLOG.md` → `done/BACKLOG-ARCHIVE.md` | Remove shipped/struck-through items (Step 2a — only write operation) |
| scan | `BACKLOG.md` sections | Duplicate detection + staleness flags (read-only) |
| read | `.autopilot`, `governance/BACKLOG.md` | Governance state check |
| report | stdout | Summary + single next-action suggestion |

Include which files exist and estimated item counts per section.
End with confidence: **High** (all files present), **Medium** (some files missing), or **Low** (critical files missing).
