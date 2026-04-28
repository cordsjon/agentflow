---
name: lightsout
description: "Use at end of any session, after every major deliverable (PR, panel review, batch completion), or before pivoting to a new logical task"
---

# /lightsout — End-of-Session Wrap-Up

End-of-session pipeline. Default mode is **checkpoint** (fast: promote + handover + attribution). Use `--full` for publishing, overnight DAGs, and detailed summaries.

## Modes

| Mode | Steps | When to use |
|------|-------|-------------|
| `/lightsout` (default) | 0, 1-lite, 2-lite, W, 5, 6 | After any session — cheap, fast, captures context |
| `/lightsout --full` | 0, 1, 1b, 2, 3, 4, W, 5, 6 | End-of-day or after major deliverables |
| `/lightsout --dry-run` | Show what would happen, no writes | Debugging |
| `/lightsout [date]` | Full pipeline for a specific date | Retroactive |

---

## Step 0 — Promote Pending Insights (always runs)

Inline promote-insights (do NOT invoke as separate skill — saves a tool call round-trip):

1. Read `~/.local/state/insights/pending.jsonl`
   - **If empty or missing**: report "No pending insights" and skip to Step 1
2. Filter lines where `kp_candidate: true`
3. Skip duplicates — use QMD to check for existing KPs with similar titles before grepping the full file:
   ```
   mcp__qmd__query searches=[{"type": "lex", "query": "\"<candidate title keywords>\""}]
     collections=["governance"] limit=5
   ```
   If QMD returns a matching KP entry, skip it. For edge cases where QMD might miss a match, fall back to `grep "### KP-" KNOWN_PATTERNS.md` for the highest KP number only.
4. For each KP candidate:
   - Find highest KP-N number, increment
   - Match to existing `## N.` category section (or create new section if none fit)
   - Classify FIPD action type (Fix/Investigate/Plan/Decide)
   - Write entry in format:
     ```markdown
     ### KP-N: Short descriptive title

     **Category:** [section] | **Action:** [FIPD] | **Origin:** [context] ([date])

     [Prose description of anti-pattern or lesson]

     **Correct pattern:** [Correct approach]
     ```
5. Append entries to appropriate sections in KNOWN_PATTERNS.md, update "Last updated" date
6. Archive all lines (KP and non-KP) from `pending.jsonl` to `~/.local/state/insights/archive/YYYY-MM.jsonl`
7. Clear `pending.jsonl`
8. Report: KP-N numbers promoted, non-KP archived, duplicates skipped

---

## Step 1 — Gather Completed Work

### Default mode (lite)

Single combined bash call — no separate file reads:

```bash
# Today's entries from DONE-Today (not the whole file)
grep -A 100 "^## $(date +%Y-%m-%d)" ~/projects/00_Governance/DONE-Today.md 2>/dev/null | head -100

# Git activity across ALL governed projects (auto-discovered, not hardcoded)
find ~/projects -maxdepth 2 -name ".git" -type d 2>/dev/null | while read gitdir; do
  d="$(dirname "$gitdir")"
  echo "=== $(basename "$d") ===" && git -C "$d" log --oneline --since="today" 2>/dev/null
done
```

If both return empty, note "No tracked completions today — session work was ad-hoc" and continue.

### Full mode (`--full`)

Read ALL of the following:

1. **Global DONE-Today.md** — `~/projects/00_Governance/DONE-Today.md` — **only read from today's date heading forward**, not the entire file. Use `grep -A` or read with offset.
2. **Weekly archives** — `~/projects/00_Governance/done/DONE-*.md` — scan for today's date only
3. **Git log** — `git log --oneline --since="today"` across governed project directories
4. **Todo list** — any completed items from the current session's task tracking
5. **Task inbox** — recently processed items in `~/projects/00_Governance/task-inbox/`

### Step 1b — Backlog Reconciliation (--full only)

```bash
python3 ~/projects/00_Governance/scripts/backlog_reconciler.py ~/projects/00_Governance --days 7
```

- Exit 2 (stale stories): include in **Open Items** with `[RECONCILER]` tag
- Exit 0: note "Backlog reconciler: clean"

---

## Step 2 — Summarize Session

### Default mode (lite)

Brief summary — 5-10 lines max:

```
## Session Summary — YYYY-MM-DD
- [Project]: [what was done, 1 line per item]
- Decisions: [key decisions, if any]
- KPs promoted: [list]
- Open: [carry-forward items]
```

### Full mode (`--full`)

Full structured summary with commit hashes, grouped by project:

```
## Session Summary — YYYY-MM-DD

### Completed
#### [Project Name]
- [US-XX: story title] — [brief outcome] (commit: `abc1234`)

### Decisions Made
- [decision with rationale]

### Open Items / Carry Forward
- [anything unfinished]

### Memories Updated
- [list any memory files created/updated]

### Governance State
- Pending suggestions: [count from ~/.local/state/governance/suggestions.jsonl]
- Last scan: [age from ~/.local/state/governance/last-scan.txt]
- Last retro: [age from ~/.local/state/governance/last-retro.txt]
- Pending insights: [count from ~/.local/state/insights/pending.jsonl]
```

---

## Step 2b — Automation Debt Sweep (always runs)

Sweep accumulated automation debt from `/reflect` scans into Paperclip tickets.

**Step 2b.0 — Inline reflect scan (always runs before the sweep):**
Before reading the pending file, run the `/reflect` scan inline on this session's work. The historical producer (post-commit hook → manual `/reflect` invocation) proved unreliable — the hook exited silently and the slash command was rarely invoked, so `pending.jsonl` stayed at 0 regardless of actual debt. Running the scan here closes the producer/consumer loop deterministically.

- Review the session transcript for the five patterns in `~/.claude/commands/reflect.md` (inline scripts, manual service calls, data transformation, manual orchestration, manual deployment)
- For each gap found, append a JSON line to `~/.local/state/automation-debt/pending.jsonl` in the schema defined by the reflect skill
- If the session was pure read/discussion or pure filesystem ops against external systems (no inline orchestration), report `reflect: clean` and continue
- Do NOT brainstorm fixes here — just log gaps. `/analyze-debt` does the root-cause work later.

1. Read `~/.local/state/automation-debt/pending.jsonl`
   - **If empty or missing**: report "No automation debt" and skip
2. Group entries by `project`
3. For each project group with 2+ entries: create ONE Paperclip issue titled `Automation debt: [project] — [N] CLI/service gaps` with all gaps listed in the description
4. For single entries: create individual Paperclip issues
5. Use `/paperclip` skill shorthand resolution for project + agent assignment (default: CTO for design decisions, Engineer for implementation)
6. Archive all entries to `~/.local/state/automation-debt/archive/YYYY-MM.jsonl`
7. Clear `pending.jsonl`
8. Report: N gaps swept into M Paperclip tickets

---

## Step 3 — Overnight DAGs (--full only)

**Pre-check before any DAG calls:**
```bash
# Single call: check all DAG states at once
for dag in phantom-autoresearch-panels phantom-autoresearch-memory phantom-autoresearch-router; do
  /opt/homebrew/opt/dagu/bin/dagu status "$dag" 2>/dev/null | head -1
done
```

**Rules:**
- **ppv-sweep**: NEVER start (user policy: stopped permanently)
- **phantom-autoresearch-***: Only start if the preflight step passes (currently blocked — scripts not implemented, US-PH-08/09/10). If all three show "not yet implemented" in status, report once: "Phantom autoresearch DAGs not yet built (US-PH-08/09/10)" and skip.
- **Other overnight DAGs**: Check `~/.config/dagu/dags/` for DAGs tagged `overnight` without `schedule:`. Start if not already running.

Log: "Started N overnight DAGs: [names]" or "No overnight DAGs to start"

---

## Step 4 — Publish to gtxs.eu (--full only)

**Fast pre-check (1 tool call):**
```bash
grep -c "^## $(date +%Y-%m-%d)" ~/projects/00_Governance/DONE-Today.md 2>/dev/null || echo "0"
```
If 0: "No publishable items today — skipping." and move to Step 5.

If > 0, proceed with full pipeline:

Config: `~/projects/deploy/lightsout-config.json`

**4a — Filter, Classify & Type**
Cross-reference today's DONE-Today items against `allow_list.allowed_topics`. Skip `blocked_topics` silently.

| Type | Target |
|------|--------|
| **learning** | **Both** — gtxs.eu + getaccess.net |
| **use-case** | **getaccess.net only** |
| **analysis** | **getaccess.net only** |

Classify gtxs.eu learnings: `ai-use-cases/claude-code/` (Claude Code/DevOps) or `ai-use-cases/` (other AI tools).
Deduplicate: skip if page already exists.

**4b — Secret Scan (BLOCKING GATE)**
Scan ALL source content against `secret_patterns` in config. Match = STOP.

**4c — Generate HTML**

*For gtxs.eu (learnings):*
- Dark theme: `#0a0c10` deep, `#12151c` card, `#1a1e28` elevated
- Fonts: DM Serif Display / Source Sans 3 / IBM Plex Mono
- Structure: fixed nav → hero → content sections → "Key Prompts" → related links → footer

*For getaccess.net:*
- Use nav pattern from existing `~/projects/deploy/site-getaccess/articles/`
- Add entry to `content.json`

**4d — Write & Update Indexes**
Write HTML files. Update index pages for both sites.

**4e — Final Secret Scan (BLOCKING GATE)**
Re-scan generated HTML. Match = STOP + remove.

**4f — Deploy**
```bash
cd ~/projects/deploy && bash deploy.sh push-all
```

---

## Step W — Wiki Update (always runs)

Update the governance wiki (localhost:3100) for any project that was touched this session. The wiki is internal documentation — the threshold is **"did anything change?"**, not "is this publishable?"

### What triggers a wiki update

Any of these in the session's completed work:
- App changes (new features, bug fixes, UI changes, new pages/routes)
- Infrastructure/environment changes (deploy config, ports, Docker, VPS)
- Architecture changes (new modules, schema migrations, dependency changes)
- Skill/command changes (new skills, modified skills, new hooks)
- Claude Code config changes (CLAUDE.md, settings.json, MCP servers)
- New integrations or API endpoints

Routine operations that do NOT trigger wiki updates: running existing tests, reading code without changing it, pure backlog/planning work with no implementation.

### Wiki page routing

Use `wiki.py` CLI for all writes — never inline content in bash (escaping fails with special chars).

```
~/projects/00_Governance/wiki/scripts/wiki.py set-section <page-path> "<section heading>" <file.md>
```

**Discover the wiki page via QMD** — do NOT use a hardcoded mapping table. Query the `governance` collection for the wiki export file:

```
mcp__qmd__query searches=[
  {"type": "lex", "query": "wiki_path \"<project-keyword>\""}
] collections=["governance"] limit=3
```

The wiki export files at `governance/wiki/export-md/` contain frontmatter with `wiki_path` and `wiki_id`. Extract `wiki_path` from the QMD result to use with `wiki.py set-section`.

**Examples:** searching `"paperclip"` returns `wiki_path: "infrastructure/paperclip"`, `"svgpaint"` returns `wiki_path: "svgpaint"`, `"keto"` returns `wiki_path: "keto"`.

If QMD returns no wiki page for a touched project, **CREATE the page first**, then update it. Never skip a wiki update because no page exists. Use `wiki.py create "<title>" --path "<path>"` (or equivalent wiki.py create command) to register the page, then use `set-section` as normal. Note "Wiki page created: [path]" in the report.

### How to update

1. **Identify touched projects** from Step 1/2 completed work
2. **For each project with wiki page:**
   - Write a markdown snippet to `/tmp/wiki-<project>-update.md` with the changes
   - Use `set-section` to replace or append a dated section heading (e.g., "Recent Changes (2026-04-15)")
   - For new features: add to the relevant existing section instead of always creating "Recent Changes"
3. **Report:** "Wiki updated: [page-path] — [brief description]" per page, or "No wiki-eligible changes"

### Section format

```markdown
## Recent Changes (YYYY-MM-DD)

### [Feature/Fix Name]
[1-3 sentences describing what changed and why]

| Detail | Value |
|--------|-------|
| Files changed | `file1.py`, `file2.html` |
| Deployment | [deployed/not deployed] |
| Known issues | [if any] |
```

For schema/migration changes, update the existing schema section rather than appending.
For new routes/endpoints, update the existing API/Pages table.

---

## Step W2 — Ingest Prompt Usage (always runs, pre-HANDOVER)

Refresh the claude-usage-systray Habits tab by ingesting new user prompts from `~/.claude/projects/*/conversations/*.jsonl` into the prompt-usage DB. Runs **before** HANDOVER is written so the post-run log state is visible to the next session. Non-blocking — ingest failure never aborts `/lightsout` (AC-14).

**Rules:**
- **30-second hard timeout** — if ingest stalls (large backlog, locked DB), we abort and move on.
- **Failure is logged, not raised** — on non-zero exit or timeout, append a one-line warning to HANDOVER.md so the next session sees the signal, then continue.
- **Log sink is `~/.local/state/prompt-usage-ingest.log`** — same path the hourly launchd job writes to (AC-13), so history is unified.
- **Never block session end.**

```bash
# Ingest prompt usage (non-blocking — 30s timeout, log-only failure)
# HANDOVER_PATH is set in Step 5 — ingest warnings are appended there if needed
mkdir -p "$HOME/.local/state"
cd /Users/jcords-macmini/projects/claude-usage-systray
if command -v timeout >/dev/null 2>&1; then
  timeout 30 python3 -m engine.ingest_prompts 2>&1 \
    | tee -a "$HOME/.local/state/prompt-usage-ingest.log"
  STATUS=${PIPESTATUS[0]}
  [ "$STATUS" -eq 124 ] && INGEST_WARN="⚠ ingest timed out at 30s"
  [ "$STATUS" -ne 0 ] && [ "$STATUS" -ne 124 ] && INGEST_WARN="⚠ ingest failed (see log)"
else
  python3 -m engine.ingest_prompts 2>&1 \
    | tee -a "$HOME/.local/state/prompt-usage-ingest.log"
  STATUS=${PIPESTATUS[0]}
  [ "$STATUS" -ne 0 ] && INGEST_WARN="⚠ ingest failed (see log)"
fi
# $INGEST_WARN (if set) is appended to the HANDOVER file written in Step 5
```

Report: `ingest: <N> msgs, <P>% matched, <M> unmatched` (from script stdout) or `ingest: skipped — <reason>`.

---

## Step 5 — Handoff Note (always runs)

Write a uniquely named handover file — no prompt, no confirmation.

**Filename pattern:** `HANDOVER-{PROJECT}-{YYYY-MM-DD-HHmm}.md`
**Location:** `~/projects/00_Governance/`
**Example:** `HANDOVER-75_Coaching-2026-04-27-1557.md`

Derive `{PROJECT}` from the session's primary project (same as Step 6 attribution — use canonical names: `30_SVG-PAINT`, `50_KETO`, `20_CONSIGLIERE`, `75_Coaching`, `00_Governance`, etc.). If multiple projects were touched, use the one with the most DONE-Today entries or most commits.

Include:
- Last task and queue position
- All completed work (same detail as Step 2 summary)
- Decisions made
- Open items / carry-forwards
- Overnight DAGs started (if --full)
- Workspace state: last KP number, pending suggestions, scan/retro age, pending insights
- Resume checklist

### Step 5b — Commit Governance Changes (always runs)

Per the global CLAUDE.md allowlist (pre-authorized: `KNOWN_PATTERNS.md`, `HANDOVER-*.md`, `BACKLOG.md` + project-scoped variants), Step 5b auto-commits **only those files**. Everything else in `00_Governance` stays dirty until explicit user review — splitting the staging to sneak unapproved paths in would launder the permission gate (explicitly prohibited by KP-744).

```bash
cd ~/projects/00_Governance && {
  # Stage KNOWN_PATTERNS.md and BACKLOG.md if changed
  ALLOWED=(KNOWN_PATTERNS.md BACKLOG.md)
  CHANGED_ALLOWED=()
  for f in "${ALLOWED[@]}"; do
    git diff --quiet -- "$f" 2>/dev/null || CHANGED_ALLOWED+=("$f")
  done
  # Stage new HANDOVER-*.md files (untracked, pattern-matched)
  HANDOVER_NEW=$(git ls-files --others --exclude-standard 'HANDOVER-*.md')
  [ -n "$HANDOVER_NEW" ] && CHANGED_ALLOWED+=($HANDOVER_NEW)
  if [ ${#CHANGED_ALLOWED[@]} -eq 0 ]; then
    echo "Governance allowlist clean — no commit needed"
  else
    git add "${CHANGED_ALLOWED[@]}"
    git commit -m "chore(governance): /lightsout session wrap-up $(date +%Y-%m-%d)"
    echo "Governance committed: ${CHANGED_ALLOWED[*]}"
  fi
  # Report (do not stage) other dirty files so user sees them
  OTHER=$(git status --porcelain | wc -l | tr -d ' ')
  [ "$OTHER" -gt 0 ] && echo "Note: $OTHER other governance files dirty — review manually"
}
```

Rules:
- **HANDOVER files are never overwritten** — each session produces a unique timestamped file.
- **Strict allowlist, not pattern-based** — only `KNOWN_PATTERNS.md`, `BACKLOG.md`, and new `HANDOVER-*.md` files (+ per-project variants). Adding other files violates the policy Stream A set 2026-04-20.
- **No split-commit workaround** — if you're tempted to stage a non-allowlist file alongside, STOP and ask the user. Splitting the commit launders permission.
- **Scope is `00_Governance` only** — project repos (SVG-PAINT, Consigliere, KETO, etc.) never auto-commit here.
- **No `--no-verify`** — honor pre-commit hooks.
- **Push is not part of this step** — local commit only.
- **Skip when clean** — idempotent when re-run in a clean tree.

---

## Step 6 — Session Attribution (always runs)

```bash
# Find session UUID
ls -t ~/.claude/projects/-Users-jcords-macmini-projects/*.jsonl | head -1
```

Determine primary project from session work. Append to `~/.local/state/codeburn/session-projects.jsonl`:
```bash
mkdir -p ~/.local/state/codeburn
echo '{"session_id": "<uuid>", "project": "<canonical name>", "date": "YYYY-MM-DD"}' >> ~/.local/state/codeburn/session-projects.jsonl
```

---

## Usage

```
/lightsout              # checkpoint (default): Steps 0, 1-lite, 2-lite, Wiki, 5, 6
/lightsout --full       # full pipeline: all steps including publish, DAGs + Wiki
/lightsout --dry-run    # show what would happen, no writes
/lightsout [date]       # retroactive for a specific date (implies --full)
```

### When to use which

- **After any session**: `/lightsout` (default) — 6-10 tool calls, captures everything essential + wiki
- **End of day**: `/lightsout --full` — 15-25 tool calls, publishes articles, starts DAGs
- **After major deliverable** (PR, panel review, batch completion): `/lightsout` then fresh session
- **Session-length-guard warning** (25 tool calls): `/lightsout` immediately, then fresh session

### Cost Discipline

The default mode exists because context replay is the hidden cost multiplier — every turn resends the full conversation. A checkpoint in a 300K session costs 6x per turn vs a fresh 50K session. Rules:
- After every commit: evaluate `/lightsout` if context is heavy
- Never start a new logical task in a bloated session
- Cache-aware: sleep ≤270s in loops to stay inside 5-min prompt cache TTL
