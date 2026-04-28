---
name: reflect
description: "Use after completing any multi-step task — scans for manual work that should be automated programmatically. Fires automatically after git commits via hook, or invoke manually."
---

# /reflect — Automation Debt Scanner

After every task completion, scan what you just did and identify manual steps that should be code.

## When This Fires

- **Automatically** via PostToolUse hook after `git commit`
- **Manually** when you recognize you just did multi-step manual work
- **From /lightsout** Step 2b sweeps accumulated debt into Paperclip tickets

## The Scan

Review the conversation since the last commit or task start. For each action you took, ask:

### 1. Inline Scripts
Did I write `python3 -c "..."` or multi-line bash to achieve the outcome?
→ Each one is a missing CLI command or service method.

### 2. Manual Service Calls
Did I call a service method (TaggingService, EntityTaxonomyService, etc.) that has no CLI/API surface?
→ Missing CLI command.

### 3. Data Transformation
Did I manually convert between formats (XLSX→DB, DB→XLSX, API→DB, JSON→table)?
→ Missing `ingest` or `export` command.

### 4. Manual Orchestration
Did I sequence steps that should be a pipeline (ingest → normalize → tag → export)?
→ Missing DAG or compound CLI command.

### 5. Manual Deployment
Did I SCP files, run migrations via SSH, or restart services by hand?
→ Missing deploy script.

### 6. Unregistered CLIs (mandatory scan)

Check git status for any new `.py` or `.sh` files created in this session:

```bash
git diff --name-only --diff-filter=A HEAD~1 HEAD 2>/dev/null | grep -E '\.(py|sh)$'
# or for uncommitted work:
git status --short | grep '^?' | grep -E '\.(py|sh)$'
```

For each new file, check if it's a CLI entry point:
```bash
grep -l "if __name__\|argparse\|import click\|import typer" <file>  # Python
head -1 <file> | grep -q '^#!'  # Shell
```

For each detected CLI, verify registration exists in `~/.claude/projects/-Users-jcords-macmini-projects/memory/`:
- `reference_<name>_cli.md`
- `feedback_use_<name>_cli.md`

If either file is missing → gap type `Registration`.

## Output Format

Emit a `## Automation Debt` block in your response. Keep it tight:

```
## Automation Debt

| Gap | What I did manually | What should exist | Project |
|-----|--------------------|--------------------|---------|
| CLI | 50-line XLSX ingest script | `entity ingest-xlsx` | Consigliere |
| Service | NACE→slug resolution by hand | `TaxonomyService.resolve_nace()` | Consigliere |
| Deploy | SCP + raw SQL migration | `scripts/deploy-vps.sh` | Consigliere |
| Registration | Created `scripts/foo.sh`, no memory files | `reference_foo_cli.md` + `feedback_use_foo_cli.md` | ProjectX |
```

## Rules

- **Do NOT brainstorm solutions** — just identify gaps. Brainstorming is a separate step.
- **Do NOT create Paperclip tickets** — /lightsout does that in bulk.
- **Do NOT skip** because the task was "simple" — simple tasks with manual steps are the highest-value automation targets.
- **Append to `~/.local/state/automation-debt/pending.jsonl`** for /lightsout to sweep:

```json
{"date": "YYYY-MM-DD", "gap": "CLI", "manual": "XLSX ingest script", "target": "entity ingest-xlsx", "project": "Consigliere"}
```

- If the scan finds zero debt (pure code changes, no manual orchestration), emit: `## Automation Debt: Clean` and move on.

## Integration Points

- **/analyze-debt**: Deep analysis skill — takes reflect output, root-causes each gap, writes governance-grade user stories to BACKLOG.md + KP entries. Use when 3+ gaps accumulate or a pipeline fails standalone.
- **/lightsout Step 2b**: Reads `pending.jsonl`, creates Paperclip tickets for each gap, archives file. For lightweight stubs only — use `/analyze-debt` for infrastructure-grade debt.
- **Rudi Schlosser (AutoEng)**: Paperclip agent that owns automation debt triage — receives tickets from Step 2b or `/analyze-debt`.
- **verification-before-completion**: When verifying task completion, include automation debt scan as final gate step
- **Post-commit hook**: Injects reminder into conversation to trigger this scan
