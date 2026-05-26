# /kaizen — Kaizen Reflection Retro

Manual retro session: run today's reflection, review open findings, and triage HIGH items.

## Step 1 — Run today's reflection

```bash
REFLECT=~/projects/00_Governance/scripts/reflection.py
TODAY=$(date +%Y-%m-%d)
REPORT=~/projects/00_Governance/reflections/${TODAY}.md

if [ -f "$REPORT" ]; then
  echo "Reflection already ran today ($TODAY). Using existing report."
else
  echo "Running reflection for $TODAY..."
  python3 "$REFLECT"
fi
cat "$REPORT"
```

## Step 2 — Show open HIGH items from KAIZEN.md

```bash
python3 - <<'EOF'
from pathlib import Path
import re

kaizen = Path.home() / "projects/00_Governance/KAIZEN.md"
text = kaizen.read_text()

lines = [l for l in text.splitlines() if "| HIGH |" in l and "| open |" in l]
print(f"\n=== OPEN HIGH ITEMS ({len(lines)} total) ===\n")
for l in lines:
    cols = [c.strip() for c in l.split("|")]
    # cols: ['', date, id, lens, sev, suggestion, status, '']
    if len(cols) >= 7:
        print(f"[{cols[2]}] {cols[3]}: {cols[5][:120]}")
        print()
EOF
```

## Step 3 — Triage

For each HIGH item presented:
- **Promote to INBOX** if it represents a concrete, actionable task. Append to `~/projects/00_Governance/INBOX.md`:
  ```
  - [KAIZEN:{id}] {lens}: {suggestion}
  ```
- **Mark resolved** if it was already addressed: update KAIZEN.md `Status` column from `open` → `resolved` for that row (use sed or Edit tool — match by ID).
- **Leave open** if not actionable yet.

After triage, report:
```
KAIZEN RETRO — {date}
  Promoted to INBOX: {N} items
  Marked resolved:   {N} items
  Left open:         {N} items (HIGH: {N}, MED: {N})
```

## Rules

- Never delete rows from KAIZEN.md — only change Status column
- Only promote HIGH items to INBOX automatically; MED/LOW stay in tracker unless user explicitly asks
- If today's reflection fails (Ollama down), run with `--dry-run` and note in report
- After triage, check if any HIGH item maps to an existing BACKLOG US — if so, link rather than duplicate
