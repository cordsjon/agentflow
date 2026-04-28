---
name: analyze-debt
description: "Use when automation debt entries exist in pending.jsonl, after a pipeline or process fails standalone, or when /reflect identified gaps that need root-cause analysis and governance-grade user stories — not just lightweight ticket stubs."
---

# /analyze-debt — Root-Cause Debt Analysis → User Stories

Turns `/reflect` output into governance-grade user stories. `/reflect` is the sensor (what broke), this skill is the actuator (why it broke, what to build, where it goes in the backlog).

## When to Use

- After `/reflect` identified 3+ debt entries worth investigating together
- After a pipeline or CLI process fails to run standalone
- When `/lightsout` Step 2b would create ticket stubs but the debt needs root-cause analysis
- When assigned a Paperclip `[automation-debt]` issue (Rudi Schlosser / AutoEng agent)

## Input

One of:
- `~/.local/state/automation-debt/pending.jsonl` — accumulated `/reflect` entries
- A failed CLI run in the current session (errors in conversation context)
- A Paperclip issue body with debt entries
- Explicit user request: "analyze why X doesn't work standalone"

## Protocol

### 1. Reproduce (mandatory)

Run the failing process. Capture every error, fallback path, and silent failure. If the failure already happened in this session, reference the exact error messages — don't re-run.

```
Goal: a table of symptoms, not guesses.
```

### 2. Root-Cause (mandatory)

For each failure, trace to file:line. Dispatch a sonnet Explore agent scoped to the project directory:

```
Agent(model: "sonnet", subagent_type: "Explore", prompt: "In /path/to/project, trace why [symptom]. Find the exact file:line where [behavior] originates. Check [specific files]. Report: file, line, what the code does, why it fails. Under 200 words.")
```

Distinguish symptoms from causes:
- Symptom: `401 Unauthorized` from Claude API
- Cause: `config.py` passes literal `${ANTHROPIC_API_KEY}` — no `os.environ` expansion

### 3. Dependency Map (mandatory)

Draw the fix chain. Ask: "If I fix A, does B become possible?"

```
Independent fixes: can run in parallel (use ‖ separator)
Dependent fixes: must sequence (use → separator)

Example:
  US-X-01 (Config) → US-X-02 (Backend A) + US-X-03 (Backend B)
                       ‖
  US-X-04 (CLI flag) + US-X-05 (Guard)
```

### 4. Existing Backlog Check (mandatory)

Before writing stories, search for overlap via QMD (default first-read method for markdown discovery):

```
mcp__qmd__query searches=[
  {"type": "lex", "query": "<keywords from story title>"},
  {"type": "vec", "query": "<natural language description of the gap>"}
] collections=["governance"] limit=10
```

If QMD is unavailable, fall back to `grep -i "<keywords>" ~/projects/00_Governance/BACKLOG.md`.

If existing stories cover the gap, update them instead of creating duplicates.

### 5. Write User Stories

For each gap, write to the project's Ideation section in BACKLOG.md:

```markdown
### US-XXX-NN: Title

> Origin: Automation debt analysis (YYYY-MM-DD) — [one-line trigger]
> Depends on: US-XXX-MM (if applicable)

**As a** [role],
**I want** [capability],
**so that** [outcome — specifically: what currently broken process works standalone].

**Acceptance Criteria:**
- [ ] [Specific, testable criteria]
- [ ] Test: [what test proves this works]

**Size:** S/M/L · **Tags:** `[tag1]` `[tag2]`
```

Rules:
- Every story needs AC with at least one test criterion
- Size estimates: S = <2h, M = 2-8h, L = 8h+
- Tags for discoverability — include the sub-package and gap type
- Origin line cites this analysis date
- Dependency lines reference other US-XXX stories

### 6. Critical Path Chain

If stories have dependencies, add a chain to the project's Critical Path section:

```markdown
**[Name] chain:** **US-X-01 (desc)** → US-X-02 (desc) + US-X-03 (desc) ‖ US-X-04 (desc)
```

### 7. Extract Patterns (mandatory)

Every root cause that could recur across projects → KP entry in KNOWN_PATTERNS.md:

```markdown
### KP-N: Short descriptive title

**Category:** [section] | **Action:** Fix/Investigate/Plan/Decide | **Origin:** [context] (YYYY-MM-DD)

[Anti-pattern prose — what goes wrong and why]

**Correct pattern:** [What to do instead]
```

Find the highest existing KP-N, increment. Match to existing category sections.

### 8. Risk Entry (if applicable)

If the gap has production impact or blocks other work, add to the Risks table:

```markdown
| R-XXX-N | [description] | L | I |
```

### 9. CLI Registration (mandatory when fix is a CLI)

If any story in this analysis produces a CLI (a script or command invoked from the terminal to replace a manual step), register it before closing the analysis. This closes the rediscovery loop — future sessions must find the CLI, not repeat the manual step.

**Three required writes, in order:**

**a) Reference memory** — create `~/.claude/projects/-Users-jcords-macmini-projects/memory/reference_<name>_cli.md`:

```markdown
---
name: <Name> CLI
description: <one-line: what this CLI does and what manual step it replaces>
type: reference
---

**Path:** `<absolute path to the CLI entry point>`
**Invocation:** `<command with key flags>`
**Replaces:** <description of the manual process this automates>
**Project:** <project name>
```

Add a pointer line to `MEMORY.md`:
```
- [reference_<name>_cli.md](reference_<name>_cli.md) — <one-line hook>
```

**b) Feedback memory** — create `~/.claude/projects/-Users-jcords-macmini-projects/memory/feedback_use_<name>_cli.md`:

```markdown
---
name: Use <name> CLI for <action>
description: When doing <manual step>, use <cli> — never do it manually
type: feedback
---

When <triggering context>, use `<path>/<cli> <args>` — never perform the manual equivalent.

**Why:** Manual step was identified as automation debt (YYYY-MM-DD). CLI created in US-XXX-NN.
**How to apply:** Any time <triggering context description> arises, invoke the CLI directly.
```

Add a pointer line to `MEMORY.md`:
```
- [feedback_use_<name>_cli.md](feedback_use_<name>_cli.md) — When <X>, use CLI — never manual
```

**c) Project CLAUDE.md update** — add one line under `## Tool Preferences` (or `## Workstyle` if no Tool Preferences section exists):

```
- **<Trigger action>:** use `<relative path>/<cli> <args>` — never manual
```

**Required AC on the User Story:**
Every story whose fix is a CLI must include:
```
- [ ] Reference memory written: `reference_<name>_cli.md` in memory/ + MEMORY.md pointer
- [ ] Feedback memory written: `feedback_use_<name>_cli.md` in memory/ + MEMORY.md pointer
- [ ] Project CLAUDE.md updated with CLI invocation rule
```

### 10. Paperclip Issue (optional)

If an AutoEng agent exists, create a Paperclip issue for validation:

```bash
bash ~/.claude/scripts/paperclip.sh create "Title" <project> autoeng in_review high
```

## Output Format

Emit a structured report:

```
## Automation Debt Analysis — [Pipeline/Process Name]

### Root Cause Map
| Gap | Severity | Symptom | Root Cause (file:line) |
|-----|----------|---------|----------------------|

### Dependency Graph
[chain notation]

### Stories Created (N)
| Story | Size | Fix |
|-------|------|-----|

### Patterns Extracted (N)
| KP-N | Title |

### Artifacts Updated
- BACKLOG.md — N stories, critical path chain, risk entry
- KNOWN_PATTERNS.md — N KP entries
- memory/ — N reference + N feedback memories, MEMORY.md pointers (one pair per CLI fix)
- Project CLAUDE.md — N invocation rules added (one per CLI fix)
- Paperclip — GET-N (if created)
```

## Rules

- **Root cause is mandatory** — never write a story from a symptom alone
- **No duplicate stories** — always check existing backlog first
- **Dependency chains before stories** — understand the graph before writing individual nodes
- **Patterns are mandatory** — every analysis produces at least one KP entry. If you found nothing reusable, you didn't look hard enough.
- **Scope to one project** — if debt spans projects, run separate analyses
- **Sonnet for investigation, Opus for writing** — use `model: "sonnet"` for Explore agents
- **pending.jsonl is input, not output** — this skill reads debt entries, it does not append to them. `/reflect` is the sensor; this skill is the actuator.
- **CLI fixes must close the rediscovery loop** — every story whose fix is a CLI requires: reference memory + feedback memory (both with MEMORY.md pointers) + project CLAUDE.md rule. A CLI that isn't registered will be rediscovered as debt in the next session.
