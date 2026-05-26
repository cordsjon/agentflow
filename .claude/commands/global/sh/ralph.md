---
name: sh-ralph
description: "Start persistent Ralph loop for iterative task completion"
allowed-tools: ["Bash(scripts/setup-ralph-loop.sh:*)"]
disable-model-invocation: true
---

# /sh:ralph — Start Ralph Loop

## Usage

```
/sh:ralph PROMPT [--max-iterations N] [--completion-promise TEXT]
```

## Behavioral Flow

1. **Execute Setup**: Run the setup script to initialize the Ralph loop:
   ```!
   scripts/setup-ralph-loop.sh $ARGUMENTS
   ```
2. **Work on Task**: Begin working on the task described in PROMPT
3. **Loop**: When you try to exit, the Ralph loop feeds the SAME PROMPT back for the next iteration. Previous work is visible in files and git history, allowing iterative improvement
4. **Exit Condition**: The loop continues until the completion promise is genuinely fulfilled, or `/sh:cancel` is invoked

## Related Commands

- `/sh:autopilot` — starts inside the Ralph loop for autonomous task execution
- `/sh:handoff` — saves context before exiting the loop (cross-session persistence)
- `/sh:kickoff` — restores context on re-entry to continue where you left off

## Completion Promise Rules

**CRITICAL**: If a completion promise is set, you may ONLY output it when the statement is completely and unequivocally TRUE.

- Do NOT output false promises to escape the loop
- Do NOT claim completion if you think you are stuck or should exit for other reasons
- Do NOT downgrade quality standards to meet the promise faster
- The loop is designed to continue until genuine completion
- If truly stuck, explain what is blocking progress — do not fabricate success

## Honesty Requirements

- Each iteration must make measurable progress toward the goal
- If no progress is possible, explain why honestly rather than producing busywork
- Previous iteration output is visible — do not repeat work already done
- Acknowledge when the task is beyond current capabilities rather than looping endlessly
