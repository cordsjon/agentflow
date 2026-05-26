---
name: postdeploy-retro
description: "After a deploy, capture what reality revealed that intent missed. Trigger surface for Compounding-Engineering style learnings — flows into existing pending.jsonl → KNOWN_PATTERNS.md pipeline."
---

# /postdeploy-retro — Post-Deploy Surprise Capture

A different trigger surface for the same learning loop as `/lightsout`. Session-end captures what *happened* during the session; this captures what *production revealed* about a deploy — the gap between intent and reality. Both feed `~/.local/state/insights/pending.jsonl` and get promoted to `KNOWN_PATTERNS.md` on the next `/lightsout` run.

## Usage

```
/postdeploy-retro <project>            # uses last 24h window
/postdeploy-retro <project> --since=2h # custom lookback (s/m/h/d)
/postdeploy-retro <project> --dry-run  # surface candidates, no capture
```

`<project>` is one of the deploy targets — typically `gtxs`, `getaccess`, `poster-engine`, `consigliere`, `svgpaint`, `syllabus`. Maps to a project directory under `~/projects/`.

## When to run

- Immediately after `deploy.sh` finishes (manual deploys)
- Within a few hours after a deploy when prod feedback has had time to land (errors, slow pages, user signals)
- NOT before a deploy — this is reality-vs-intent, both halves must exist

## Step 1 — Resolve the project + deploy window

```bash
PROJECT="$1"                        # passed by the user
SINCE="${SINCE:-1d}"                # default 24h window
PROJ_DIR=$(find ~/projects -maxdepth 2 -type d -iname "*${PROJECT}*" 2>/dev/null | head -1)
[ -z "$PROJ_DIR" ] && { echo "No project dir matched '$PROJECT'"; exit 1; }
echo "Project: $PROJ_DIR"
echo "Window:  --since=$SINCE"
```

Report what was resolved before continuing.

## Step 2 — Gather deploy signals (single batched read)

Three signal sources, all inside one bash block so the model sees them together:

```bash
# 1. Recent commits in the project repo
git -C "$PROJ_DIR" log --oneline --since="$SINCE" 2>/dev/null | head -30

echo "---"

# 2. Deploy log tail — look for the canonical deploy.sh in known locations
for log_candidate in "$PROJ_DIR/deploy.log" "$PROJ_DIR/logs/deploy.log" "$HOME/.local/state/deploys/${PROJECT}.log"; do
  [ -f "$log_candidate" ] && { echo "=== $log_candidate ==="; tail -40 "$log_candidate"; break; }
done

echo "---"

# 3. Any HANDOVER references to this project since the window started
find ~/projects/00_Governance -maxdepth 1 -name "HANDOVER-*.md" -newermt "$(date -v-1d +%Y-%m-%d 2>/dev/null || date -d '1 day ago' +%Y-%m-%d)" 2>/dev/null | while read f; do
  grep -l -i "$PROJECT" "$f" 2>/dev/null
done

exit 0
```

If all three are empty, report "No deploy signals in window — nothing to retro on" and exit. Do NOT fabricate insights.

## Step 3 — Identify surprises (the actual model work)

From the signals gathered in Step 2, identify **1–5 things that reality revealed which the commits/intent didn't predict**. Examples of valid retros:

- A bug fix landed because something broke in prod that local testing didn't catch → *why didn't the test catch it?* That's a learning.
- A deploy succeeded but a feature didn't work end-to-end → *gap between deploy-success and feature-working*.
- A pattern repeated from a prior deploy → *the prior learning didn't make it into KNOWN_PATTERNS, or it did but wasn't applied*.
- A revert / rollback / hotfix in the window → strongest signal of intent-vs-reality gap.

Examples of **invalid** retros (skip these):

- "We shipped X" — not a surprise, that's intent.
- "Tests passed" — not a surprise, that's expected.
- Restating commit messages.

If nothing genuinely surprised, report "No surprises — deploy ran clean against intent" and exit. Empty retros are correct outcomes.

## Step 4 — Capture each surprise

For each genuine surprise, call `capture_insight.py` once. Use `--no-kp` for project-narrow observations; default (KP-candidate) for cross-cutting learnings.

```bash
python3 ~/projects/00_Governance/scripts/capture_insight.py \
  "INSIGHT TEXT — what was surprising, and what it implies for next time" \
  "postdeploy-retro: <project> deploy on YYYY-MM-DD"
```

The context string MUST start with `postdeploy-retro:` so future audits can grep this trigger surface separately from session-end captures.

On `--dry-run`: print the would-be capture commands instead of running them.

## Step 5 — Report

Brief, ≤6 lines:

```
Post-deploy retro: <project>
Window: --since=<value>
Signals: <N commits, deploy log: found|missing, handovers: <count>>
Surprises captured: <N>
Promotion: next /lightsout will fingerprint-dedupe vs KNOWN_PATTERNS.md before promoting KP-candidates.
```

## Design notes

- **No lock acquisition.** Unlike `/lightsout`, this skill writes only to `pending.jsonl` (append-only, atomic) via the same path session-end uses. The promotion step (`/lightsout` Step 0) still serializes via `promote_insights.py`.
- **No retro markdown file.** Insights go straight to the existing pipeline. If a per-retro audit trail becomes useful later, add a `--write-retro` flag that drops a markdown under `~/projects/00_Governance/post-deploy-retros/YYYY-MM-DD-<project>.md` — but only after the simpler form has been used long enough to know it's worth the storage.
- **Auto-trigger is a future upgrade.** A `deploy.sh` shell-hook variant could fire this skill automatically post-deploy, but requires editing every project's deploy script. Manual invocation first; auto only if the loop proves valuable.
- **Empty retros are the goal long-term.** "No surprises" is the steady state when learnings have been internalized. Frequency of non-empty retros is itself a signal — rising count = drift; declining = compounding works.
