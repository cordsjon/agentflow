---
name: goal
description: "Reader and executor over ~/.local/state/goal-stop/active.json — the structured intent file with scoped USs, ordering, and exit conditions. Use to inspect the active goal, get the next critical-path US, or clear the goal. In a stamped session whose stamp matches the goal's project, /goal auto-executes the next un-ready US; otherwise it reports and stops."
argument-hint: "[status | show | clear | next]"
---

# /goal — Active Goal Inspector + Executor

Read `~/.local/state/goal-stop/active.json` — the structured intent file produced when a session commits to a multi-US objective. The file already encodes:

- `project` — topic (matches a stamp)
- `intent` — the why
- `scope_uss[]` — ordered USs with `order`, `status`, `gap`, `effort`, `rationale`
- `exit_condition.all_of[]` — predicates that signal goal complete

`/goal` is the read/execute surface on top of that file. It does NOT create goals — creating a goal requires structured input (intent + exit predicates + ordered scope) best done by hand or via a heavier skill.

## State file

```
~/.local/state/goal-stop/active.json
```

Sibling state: `~/.local/state/goal-stop/active.json.bak-<timestamp>` (from `/goal clear`).

## Behavior

### `/goal` or `/goal next` (no arg)

1. Read `active.json`. If missing → report `no active goal` and stop.
2. Find next item: `scope_uss[]` filtered by `status != "ready"`, sorted by `order` ASC, take first. If empty → all USs are ready; report goal-complete + check `exit_condition.all_of` predicates; suggest `/lightsout`.
3. Consult session stamp:
   ```bash
   source "$HOME/.claude/scripts/stamp-context.sh"
   # Provides: $SID, $STAMP_FILE, $STAMP, $GOAL_STOP
   ```
   - If `$STAMP` set AND matches `active.json.project` (or the next US's `id`) → **auto-execute**: invoke `sh:execute <us-id>` directly. No prompt. The stamp is the commitment.
   - Else → report next US (`id`, `gap`, `effort`, `rationale`), suggest `sh:execute <us-id>`, stop.

### `/goal status`

Print a table of all `scope_uss` with `order`, `id`, `status`, `gap`, `effort`. Show counts (`N ready / M total`). Show `exit_condition.all_of` predicates with which appear satisfied (best-effort, predicate-text-only). No writes.

### `/goal show`

Dump `intent`, `created_at`, `session_origin`, `project`, `branch`, `backlog_path`, and the full `scope_uss` + `exit_condition` payload. Read-only.

### `/goal clear`

Archive the active goal — does NOT delete:

```bash
SRC="$HOME/.local/state/goal-stop/active.json"
[ -f "$SRC" ] || { echo "No active goal."; exit 0; }
TS=$(date +%Y-%m-%d-%H%M)
mv "$SRC" "${SRC}.bak-${TS}"
echo "Goal archived: ${SRC}.bak-${TS}"
```

Confirm before running. Closing the session does NOT auto-clear — goal-stop persists across sessions by design (multi-session goals are common).

## Implementation

```bash
source "$HOME/.claude/scripts/stamp-context.sh"
# Provides: $SID, $STAMP_FILE, $STAMP, $GOAL_STOP

case "${ARGUMENTS:-next}" in
  clear)
    [ -f "$GOAL_STOP" ] || { echo "No active goal."; exit 0; }
    TS=$(date +%Y-%m-%d-%H%M)
    mv "$GOAL_STOP" "${GOAL_STOP}.bak-${TS}"
    echo "Goal archived: ${GOAL_STOP}.bak-${TS}"
    ;;
  status|show|next|"")
    [ -f "$GOAL_STOP" ] || { echo "No active goal at $GOAL_STOP"; exit 0; }
    # Parse and report per sub-command (see Behavior section above).
    # Use python3 -c with json.load for reliable parsing — jq may be absent.
    ;;
  *)
    echo "Usage: /goal [status | show | clear | next]"
    ;;
esac
```

Parsing the JSON: delegate to `~/.claude/scripts/goal_parse.py` — it validates the schema at the boundary and **fails loud** (exit 2) if `active.json` is missing `scope_uss[]` / `exit_condition` (old-schema drift), naming the present old keys in the error so the operator knows what to migrate. Do NOT re-implement the parse inline; that path historically silently defaulted to `[]` and miscounted "all ready."

```bash
# next un-ready US (JSON to stdout) or "no active goal" (stderr, exit 0) or schema-drift (stderr, exit 2)
python3 ~/.claude/scripts/goal_parse.py next

# table of all USs with ready/total counts
python3 ~/.claude/scripts/goal_parse.py status
```

Tests live next to it (`~/.claude/scripts/test_goal_parse.py`) — run `python3 -m unittest test_goal_parse.py -v` from that dir.

## Interaction with /stamp

`/goal` and `/stamp` compose:

| State | `/goal` (no arg) behavior |
|---|---|
| Stamped, goal matches stamp | **Auto-execute next un-ready US** via `sh:execute` |
| Stamped, goal does not match stamp | Report next US, suggest `sh:execute`, but warn: "stamp `$STAMP` does not match goal project `$goal.project` — clear one or the other" |
| Stamped, no goal | Report `no active goal`, suggest creating one or relying on stamp-string filtering of BACKLOG |
| Unstamped, goal exists | Report next US, suggest `sh:execute <us-id>`, stop |
| Unstamped, no goal | Report `no active goal`, stop |

## Anti-goals

- `/goal` does NOT create goals. Creation is heavy (intent + scope + exit) and out of scope.
- `/goal` does NOT modify `scope_uss[].status`. Status updates flow from `backlog_add.py promote` and `sh:execute` completions — never directly via this command.
- `/goal` does NOT delete `active.json`. Always archive via rename to `.bak-<timestamp>`.
- `/goal` does NOT auto-clear on session close. Goals persist by design.

## Why this skill exists

`goal-stop/active.json` is the precise mechanism for "what to do next" — `scope_uss[].order` already computes the critical path; `exit_condition.all_of` already defines done. Without `/goal`, this file is consulted ad-hoc by hand-grepping or by other skills' internal logic. `/goal` exposes it as a callable surface so the user (and skills like `kickoff`, `resume-handover`) can ask "what's next?" and get a deterministic answer from a known source rather than re-deriving order from BACKLOG.

In a stamped session that matches the goal, `/goal` is also the **execution trigger** — it removes the last user prompt between "stamp set" and "actually working."
