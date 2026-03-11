---
name: agentflow-retro
description: Run a retrospective after every 10 completed User Stories. Use when the retro counter reaches 10, when the team wants to reflect on recent work, or when continuous improvement analysis is needed.
disable-model-invocation: true
---

# Retrospective — Continuous Improvement

Triggered every **10 completed User Stories** (tracked in project memory).

## When to Run

- Retro counter reaches 10 completed User Stories
- Either party requests: "Let's do a retro"
- After a significant incident or quality issue

Counter tracks US completions only — spikes, bugs, and tooling tasks don't count.

## Retro Template

```markdown
## Retro -- [date] -- after story N

### What worked well
-

### Friction / slowdowns
-

### Bugfix quality (were root causes documented?)
-

### Memory + tooling gaps
-

### Inner loop robustness
-

### Quality gate effectiveness
-

### Actionable items
- [ ] (add to BACKLOG#Ideation or update project rules)
```

## Process

1. **Gather data** — review DONE-Today and archives since last retro
2. **Walk each section** — be specific, reference actual tasks/commits
3. **Identify patterns** — what keeps recurring?
4. **Generate actionable items** — each must be concrete and assignable:
   - Process improvements -> update project CLAUDE.md rules
   - Tool gaps -> add to BACKLOG#Ideation
   - Anti-patterns -> add to KNOWN_PATTERNS.md
5. **Reset counter** — set `retro_stories_since_last: 0` in project memory

## Scope

The retro covers:
- Workflow friction and cycle time
- Bugfixing approach quality (were root causes documented?)
- Memory file usefulness
- Inner/outer loop robustness
- Tooling gaps
- Quality gate effectiveness

## Output

- Actionable items added to BACKLOG#Ideation
- Rule updates applied to project CLAUDE.md
- New anti-patterns added to KNOWN_PATTERNS.md
- Counter reset in project memory
