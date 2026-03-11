---
name: agentflow-orchestrator
description: Route tasks to agents using capability scoring, detect stalls, and manage dependency cascades. Use when assigning work to agents, investigating stalled tasks, or managing multi-agent coordination.
user-invocable: false
---

# Orchestrator — Lightweight Routing Layer

Removes the human as the routing bottleneck between triage and execution.
The orchestrator is a **phase**, not a daemon — it runs at defined trigger points inside the autopilot loop.

## When It Runs

### 1. Autopilot Cycle Start

After reading next `[ ]` item, before DOR check:
1. **Stall check** — is the current/last item stuck?
2. **Assignment check** — does item have `@agent`? If not, route it
3. **Unblock scan** — did a recently completed item satisfy any `needs:` dependency?
4. **Context preload** — assemble file refs, risk flags, prior art into `_Context:_` line

### 2. Task Completion

After moving item to DONE-Today:
1. **Dependency cascade** — check BACKLOG for items with `needs: <completed_item>`. If found and Ready, suggest queuing
2. **Stall reset** — clear `stall:N` counter
3. **Planning trigger** — if queue has <= 1 unchecked item, suggest planning round

## Routing Scoring

For each registered agent:
```
score = sum(keyword_match(task_keywords, agent.strengths))
      + context_bonus(task_files, agent.context_access)    (+2)
      - constraint_penalty(task_requirements, agent.constraints)  (-10)
```

### Confidence Thresholds
- `> 0.7` — auto-route to best agent
- `0.3 - 0.7` — suggest agent, human confirms
- `< 0.3` — tag as `@unrouted`, skip to next routable item

## Stall Detection

A task is stalled when:
1. **Time-based:** no activity file changes for > 10min (30min for requirements sessions)
2. **Error-loop:** same error pattern 3+ times in console tail
3. **Explicit:** agent writes `STALLED: <reason>`

### Escalation Ladder

| Level | Trigger | Action |
|-------|---------|--------|
| `stall:1` | First detection | Log warning, increment counter |
| `stall:2` | Second consecutive check | Write stall warning |
| `stall:3` | Third consecutive check | Pause autopilot, escalate to human |

On multi-agent setup: if another agent has capability, suggest re-routing.

## Context Preloading

The orchestrator assembles:
1. **File references** — files mentioned in task description or spec
2. **Related threads** — if task originated from a message, include thread
3. **Prior art** — related completed items from DONE-Today or archives
4. **Risk flags** — if task touches a known risk, surface the risk entry

## Result Validation

After execution, before commit:
1. **Greenlight** — project test suite must pass
2. **Known patterns scan** — check diff against anti-patterns
3. **Constraint check** — verify no project constraint violations

See [routing.md](routing.md) for detailed scoring examples.
