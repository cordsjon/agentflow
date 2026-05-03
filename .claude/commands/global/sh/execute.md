---
name: sh-execute
description: "Use when you have a written implementation plan (output of /plan) and are ready to begin coding — do not use without a plan artifact"
---

# Executing Plans

## Overview

Load plan, review critically, execute all tasks, report when complete.

**Announce at start:** "I'm using the sh:execute skill to implement this plan."

## Pre-flight: Working Tree Check

**As the very first action**, before loading the plan, run:

```
git status --porcelain
```

- "not a git repository" → proceed normally (no false positive).
- Output is **empty** → clean tree, proceed.
- Output is **non-empty** and `--allow-dirty` was **not** passed → **refuse**:
  > "Working tree is dirty. Commit or stash your changes before executing a plan, or pass `--allow-dirty` to override."
  Then stop — do not load or execute the plan.
- `--allow-dirty` passed → skip the check, include in run header:
  > "[AUDIT] --allow-dirty flag set: dirty-tree check suppressed."

---

## The Process

### Step 1: Load and Review Plan
1. Read plan file
2. Review critically - identify any questions or concerns about the plan
3. If concerns: Raise them with your human partner before starting
4. If no concerns: Proceed

### Step 2: Execute Tasks

For each task:
1. Mark as in_progress
2. Follow each step exactly (plan has bite-sized steps)
3. Run verifications as specified
4. Mark as completed

### Step 3: Complete Development

After all tasks complete and verified:
- Announce: "I'm using the sh:finish skill to complete this work."
- **REQUIRED:** Use `/sh:finish`
- Follow that skill to verify tests, present options, execute choice

## When to Stop and Ask for Help

**STOP executing immediately when:**
- Hit a blocker (missing dependency, test fails, instruction unclear)
- Plan has critical gaps preventing starting
- You don't understand an instruction
- Verification fails repeatedly

**Ask for clarification rather than guessing.**

## When to Revisit Earlier Steps

**Return to Review (Step 1) when:**
- Partner updates the plan based on your feedback
- Fundamental approach needs rethinking

**Don't force through blockers** - stop and ask.

## Remember
- Review plan critically first
- Follow plan steps exactly
- Don't skip verifications
- Reference Shepherd skills when plan says to
- Stop when blocked, don't guess
- Never start implementation on main/master branch without explicit user consent

## Integration

**Required workflow skills:**
- **`/sh:worktree`** - RECOMMENDED: Set up isolated workspace before starting
- **`/sh:plan`** - Creates the plan this skill executes
- **`/sh:finish`** - Complete development after all tasks
- **`/sh:verify`** - Evidence-based verification before claiming completion
