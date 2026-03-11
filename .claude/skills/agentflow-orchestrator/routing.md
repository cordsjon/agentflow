# Routing Reference

## Scoring Formula

```
score = sum(keyword_match(task_keywords, agent.strengths))
      + context_bonus(task_files, agent.context_access)    (+2)
      - constraint_penalty(task_requirements, agent.constraints)  (-10)
```

### keyword_match
Each task keyword that appears in an agent's `strengths` list scores +1.

Example:
- Task: "implement frontend dark mode toggle"
- Agent strengths: ["frontend", "css", "javascript", "implement"]
- Match: "implement" (+1), "frontend" (+1) = +2

### context_bonus
+2 if the agent has direct access to the files mentioned in the task Context line.

### constraint_penalty
-10 if the agent cannot satisfy a hard requirement.
Example: task requires repo write access, but agent is read-only.

## Confidence Thresholds

| Range | Action |
|-------|--------|
| > 0.7 | Auto-route to best-scoring agent |
| 0.3 - 0.7 | Suggest agent, request human confirmation |
| < 0.3 | Tag as `@unrouted`, skip to next routable item |

## Stall Detection Details

### Time Thresholds
- Default: 10 minutes of inactivity
- Requirements/design sessions: 30 minutes (longer thinking expected)

### Error Loop Detection
Scan last 100 lines of console output for repeating error patterns.
If same error signature appears 3+ times, increment stall counter.

### Escalation Example

```
stall:0 -> Task assigned, execution begins
stall:1 -> 10min no activity. Warning logged. Counter incremented.
stall:2 -> Another 10min. "STALL WARNING: US-DM-01 -- 2 cycles"
stall:3 -> Another 10min. Autopilot paused. Human notified.
```

## Context Preloading

The orchestrator assembles context from:

1. **Task description** -> extract file paths mentioned
2. **Spec document** -> if linked, include key sections
3. **DONE-Today archives** -> find related completed items
4. **BACKLOG#Risks** -> surface any matching risk entries
5. **Tether threads** -> if task originated from a message

## Single-Agent Mode (default)

When only one agent is registered (e.g., `@claude`):
- Routing always assigns `@claude` with confidence 1.0
- Value comes from stall detection, dependency cascade, and context preloading
- No multi-agent coordination overhead

## Multi-Agent Mode (future)

When multiple agents are active:
- Scoring selects best agent per task
- Assignments posted via message bus
- Completion reported back to orchestrator
- Re-routing on stall possible
