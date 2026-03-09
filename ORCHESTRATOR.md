# Orchestrator — Lightweight Routing Layer

> **Purpose:** Remove the human as the routing bottleneck between triage and execution.
> The orchestrator is a **phase**, not a daemon. It runs at defined trigger points
> inside the existing autopilot loop.

---

## Position in the Loop

```
INBOX ──/triage──> BACKLOG ──/workflow──> TODO-Today ──/autopilot──> DONE-Today
                                              │
                                         ┌────┴────┐
                                         │  ROUTE  │  ← orchestrator phase
                                         └────┬────┘
                                              │
                                         agent executes
```

The ROUTE phase inserts between queue population and execution.
It does NOT replace `/workflow` — it augments the autopilot's task pickup.

---

## When It Runs

The orchestrator fires at exactly two trigger points:

### 1. Autopilot Cycle Start (outer loop head)

After reading the next `- [ ]` item from TODO-Today.md, before DOR check:

1. **Stall check** — Is the current/last item stuck? (see §Stall Detection)
2. **Assignment check** — Does the item have an `@agent` tag? If not, route it.
3. **Unblock scan** — Did a recently completed item satisfy any `needs:` dependency in BACKLOG.md? If yes, surface it for queuing.
4. **Context preload** — Assemble file refs, risk flags, and prior art into `_Context:_` line.

### 2. Task Completion (inner loop tail)

After `queue done` moves an item to DONE-Today.md:

1. **Dependency cascade** — Check BACKLOG.md for items with `needs: <completed_item>`. If found and Ready, auto-suggest queuing with routing assignment.
2. **Stall reset** — Clear `stall:N` counter on the completed item's slot.
3. **Planning trigger** — If queue has <= 1 unchecked item, suggest a planning round (per §8.5).

---

## Routing Logic

### Input

The orchestrator reads:
- The task description (bold text after checkbox)
- The `/sc:` command hint (line 2 of queue format)
- The `_Context:_` line (line 3, optional)

### Scoring

For each registered agent in `AGENT_CAPABILITIES.md`:

```
score = sum(keyword_match(task_keywords, agent.strengths))
      + context_bonus(task_files, agent.context_access)
      - constraint_penalty(task_requirements, agent.constraints)
```

- `keyword_match`: Each task keyword that appears in an agent's `strengths` list scores +1.
- `context_bonus`: +2 if the agent has direct access to the files mentioned in Context.
- `constraint_penalty`: -10 if the agent cannot satisfy a hard requirement (e.g., no repo write access for an implementation task).

### Output

The orchestrator annotates the TODO-Today item:

```markdown
- [ ] **implement** FE-32 font preview refresh `@claude` `stall:0`
  `/sc:implement "font preview refresh" --focus frontend`
  _Context: font_detail.html, fonts.js — confidence:0.9_
```

New fields (appended to line 1 or line 3):
- `@agent` — routed assignment (from capability scoring)
- `stall:N` — stall counter (starts at 0, incremented by supervisor)
- `confidence:X.X` — routing confidence score (0.0–1.0), informational

### Fallback

If no agent scores above 0.3 confidence, or if multiple agents tie:
- Tag as `@unrouted`
- Write to `.claude-action`: `"ROUTE: unrouted task — manual assignment needed"`
- Autopilot continues with next routable item (does not block)

---

## Stall Detection

A task is considered stalled when:

1. **Time-based:** `.claude-action` and `.claude-activity` both unchanged for > N minutes (threshold from supervisor config, default: 10min, 30min for requirements sessions)
2. **Error-loop:** Same error pattern appears 3+ times in `.console-log` tail (100 lines)
3. **Explicit:** Agent writes `STALLED: <reason>` to `.claude-action`

### Stall Response (escalation ladder)

| Stall Level | Trigger | Action |
|-------------|---------|--------|
| `stall:1` | First detection | Log warning, increment counter |
| `stall:2` | Second consecutive check | Write to `.claude-action`: `"STALL WARNING: <task> — 2 cycles"` |
| `stall:3` | Third consecutive check | Pause autopilot, toast notification, escalate to human |

When a stall is detected on a multi-agent setup:
- If another agent has capability for the task, suggest re-routing
- Otherwise, escalate to human

### Stall Reset

Counter resets to 0 when:
- `.claude-action` content changes (agent made progress)
- `.claude-activity` mtime advances
- Task is completed or manually re-assigned

---

## Context Preloading

When the orchestrator assigns a task, it assembles a context hint in the `_Context:_` line:

1. **File references** — Files mentioned in the task description or spec
2. **Related Tether threads** — If the task originated from a Tether message, include thread name
3. **Prior art** — If DONE-Today or archives contain related completed items, reference them
4. **Risk flags** — If the task touches an item in `BACKLOG.md ## Risks`, surface the risk entry

This is informational — the executing agent reads it as starting context, not as a binding constraint.

---

## Result Validation

After task execution, before commit (runs inside the Cleanup Sub-Loop):

1. **Greenlight** — Project's greenlight must pass (existing gate, unchanged)
2. **KNOWN_PATTERNS scan** — Check diff against `KNOWN_PATTERNS.md` for anti-pattern reintroduction
3. **Constraint check** — Verify no CLAUDE.md constraint violation in the diff

If validation fails, the orchestrator does NOT accept the result:
- Low findings: auto-fix loop (existing behavior)
- Medium+ findings: pause autopilot (existing behavior)

This gate already exists in CLAUDE-LOOP.md's Cleanup Sub-Loop. The orchestrator adds no new validation steps — it just names the existing gate as part of the routing lifecycle.

---

## TODO-Today.md Format Changes

Existing format (unchanged):
```markdown
- [ ] **Phase: Task description**
  `/sc:command "args" --attribute`
  _Context: brief notes, file refs, links_
```

Extended format (orchestrator adds):
```markdown
- [ ] **Phase: Task description** `@claude` `stall:0`
  `/sc:command "args" --attribute`
  _Context: brief notes, file refs, links — confidence:0.85_
```

New optional fields:
| Field | Location | Set by | Meaning |
|-------|----------|--------|---------|
| `@agent` | Line 1, after description | Orchestrator | Assigned agent |
| `stall:N` | Line 1, after @agent | Supervisor | Stall counter |
| `confidence:X.X` | Line 3, in Context | Orchestrator | Routing confidence |

All fields are optional. Items without `@agent` are treated as `@claude` (default agent). The autopilot executor ignores these tags — they are metadata for the orchestrator and supervisor.

---

## Integration with Existing Systems

### Supervisor (`autopilot-supervisor.ps1`)

The supervisor already monitors stall conditions via `.claude-action` mtime. The orchestrator formalizes this into the `stall:N` counter. No changes to supervisor needed — it continues to monitor files. The orchestrator reads supervisor output, not the reverse.

### Tether

When multiple agents are active:
- Orchestrator posts task assignments via `tether_send(to=agent, subject="task-assignment", ...)`
- Agent reports completion via `tether_send(to="orchestrator", subject="task-complete", ...)`
- For Claude-only mode (current): Tether is not used. Routing is local file annotation only.

### Planning Rounds (§8.5)

The orchestrator participates in planning rounds by providing:
- Routing statistics (how many tasks routed to each agent)
- Stall history (which tasks stalled, how resolved)
- Unblock cascade results (which dependencies were auto-resolved)

### Semaphore (`.autopilot`)

The orchestrator respects the semaphore exactly like the executor:
- `run` → proceed with routing
- `pause` → stop, do not route
- The orchestrator can write `pause` (on stall:3 escalation)

---

## What the Orchestrator Does NOT Do

- Does NOT replace `/workflow` — queue population is still human-driven or planning-round-driven
- Does NOT execute tasks — it routes and monitors, the executor runs
- Does NOT manage BACKLOG graduation — that stays with DOR/DOD gates
- Does NOT spawn parallel agents — single-threaded execution preserved
- Does NOT require Tether for Claude-only mode — pure file annotation
- Does NOT add new quality gates — reuses existing greenlight + cleanup sub-loop

---

## Implementation Notes

The orchestrator is implemented as part of the `/autopilot` skill, not as a separate skill or daemon.

**Phase 1 (current):** Claude-only routing. The orchestrator always assigns `@claude` with confidence 1.0. Value comes from stall detection, dependency cascade, and context preloading — not from multi-agent routing.

**Phase 2 (future):** When Gemini/ChatGPT are active via Tether, the scoring logic selects the best agent. Routing confidence < 1.0 triggers human confirmation before assignment.

**Phase 3 (future):** Orchestrator-as-agent via Tether. The orchestrator itself becomes an agent that other agents can query for priority and assignment information.
