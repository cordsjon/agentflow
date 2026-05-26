---
name: agentflow-autopilot
description: Start the autonomous autopilot execution loop. Reads tasks from TODO-Today queue, executes them with quality gates, and processes until queue is empty or paused. Use to begin autonomous task processing.
disable-model-invocation: true
---

# Autopilot — Autonomous Execution

Start the agentflow autopilot loop. Reads and executes tasks from TODO-Today.md autonomously.

## Prerequisites

- `.autopilot` file exists with content `run`
- TODO-Today.md has unchecked `[ ]` items in `## Queue`
- Project's test suite / greenlight command is known

## Execution Model

```
while .autopilot contains "run":
    task = first unchecked [ ] in TODO-Today.md
    if no task: write "Queue complete", STOP

    # Route (orchestrator phase)
    assign @agent, check stalls, preload context

    # DOR gate
    if task fails DOR: pause, STOP

    # Execute
    if US task: write failing test first (TDD)
    implement until tests pass

    # Verify
    confirm all acceptance criteria with evidence

    # Self-review
    review changed files for issues, fix any found

    # Cleanup sub-loop
    run greenlight
    if M+ task: run deep audit
    fix all Low findings
    if Medium+ findings: pause autopilot, STOP

    # Commit
    atomic conventional commit

    # Branch management
    if on feature branch: create PR

    # Move to done
    mark [x], move to DONE-Today with timestamp

    # Save context
    produce handoff document

    # Check retro
    if retro counter >= 10: run retro before next task

    # Loop
    re-read .autopilot semaphore
```

## Semaphore Control

| `.autopilot` content | Behavior |
|---------------------|----------|
| `run` | Continue processing |
| `pause` | Stop after current task completes |
| File missing | Stop immediately |

The autopilot can write `pause` itself when:
- Medium+ quality findings detected
- DOR check fails
- Stall level reaches 3

## Pausing

To pause autopilot mid-session:
- Write `pause` to `.autopilot` file
- Or delete the `.autopilot` file

## Quality Guarantees

- Every task passes greenlight before commit
- Every commit is atomic and conventional
- Medium+ findings always pause — never bypassed
- Context is saved at every session boundary
- Retros happen on schedule (every 10 US)
