---
name: sh:review
description: Request self-review of completed work and handle external code review feedback with technical rigor
---

# Code Review

This skill covers both sides of code review: requesting review of your own work and responding to review feedback from others.

---

## Part 1: Requesting Review

Dispatch a review to catch issues before they cascade. The reviewer gets precisely crafted context for evaluation -- never your session's history.

**Core principle:** Review early, review often.

### When to Request Review

**Mandatory:**
- After completing a major feature
- Before merge to main
- After each task in parallel agent workflows

**Optional but valuable:**
- When stuck (fresh perspective)
- Before refactoring (baseline check)
- After fixing complex bug

### How to Request

**1. Get git SHAs:**
```bash
BASE_SHA=$(git rev-parse HEAD~1)  # or origin/main
HEAD_SHA=$(git rev-parse HEAD)
```

**2. Prepare review context:**
- What was implemented
- What it should do (plan or requirements reference)
- Base and head commits
- Brief summary of changes

**3. Dispatch review subagent** (if available) or perform self-review by:
- Re-reading the diff with fresh eyes
- Checking each requirement against the implementation
- Running the full test suite
- Verifying edge cases

**4. Act on feedback:**
- Fix Critical issues immediately
- Fix Important issues before proceeding
- Note Minor issues for later
- Push back if feedback is wrong (with reasoning)

### Integration with Workflows

**Parallel agents (`/sh:parallel`):**
- Review after EACH task
- Catch issues before they compound
- Fix before moving to next task

**Executing plans (`/sh:execute`):**
- Review after each batch (3 tasks)
- Get feedback, apply, continue

**Ad-Hoc Development:**
- Review before merge
- Review when stuck

---

## Part 2: Receiving Review Feedback

Code review requires technical evaluation, not emotional performance.

**Core principle:** Verify before implementing. Ask before assuming. Technical correctness over social comfort.

### The Response Pattern

```
WHEN receiving code review feedback:

1. READ: Complete feedback without reacting
2. UNDERSTAND: Restate requirement in own words (or ask)
3. VERIFY: Check against codebase reality
4. EVALUATE: Technically sound for THIS codebase?
5. RESPOND: Technical acknowledgment or reasoned pushback
6. IMPLEMENT: One item at a time, test each
```

### Forbidden Responses

**NEVER:**
- "You're absolutely right!"
- "Great point!" / "Excellent feedback!"
- "Let me implement that now" (before verification)

**INSTEAD:**
- Restate the technical requirement
- Ask clarifying questions
- Push back with technical reasoning if wrong
- Just start working (actions > words)

### Handling Unclear Feedback

```
IF any item is unclear:
  STOP - do not implement anything yet
  ASK for clarification on unclear items

WHY: Items may be related. Partial understanding = wrong implementation.
```

### Source-Specific Handling

**From your human partner:**
- Trusted -- implement after understanding
- Still ask if scope unclear
- No performative agreement
- Skip to action or technical acknowledgment

**From external reviewers:**
```
BEFORE implementing:
  1. Check: Technically correct for THIS codebase?
  2. Check: Breaks existing functionality?
  3. Check: Reason for current implementation?
  4. Check: Works on all platforms/versions?
  5. Check: Does reviewer understand full context?

IF suggestion seems wrong:
  Push back with technical reasoning

IF conflicts with human partner's prior decisions:
  Stop and discuss with human partner first
```

### YAGNI Check for "Professional" Features

```
IF reviewer suggests "implementing properly":
  grep codebase for actual usage

  IF unused: "This endpoint isn't called. Remove it (YAGNI)?"
  IF used: Then implement properly
```

### Implementation Order

```
FOR multi-item feedback:
  1. Clarify anything unclear FIRST
  2. Then implement in this order:
     - Blocking issues (breaks, security)
     - Simple fixes (typos, imports)
     - Complex fixes (refactoring, logic)
  3. Test each fix individually
  4. Verify no regressions
```

### When To Push Back

Push back when:
- Suggestion breaks existing functionality
- Reviewer lacks full context
- Violates YAGNI (unused feature)
- Technically incorrect for this stack
- Legacy/compatibility reasons exist
- Conflicts with human partner's architectural decisions

**How to push back:**
- Use technical reasoning, not defensiveness
- Ask specific questions
- Reference working tests/code

### Acknowledging Correct Feedback

When feedback IS correct:
```
Good: "Fixed. [Brief description of what changed]"
Good: "Good catch - [specific issue]. Fixed in [location]."
Good: [Just fix it and show in the code]

Bad: "You're absolutely right!"
Bad: "Great point!"
Bad: ANY gratitude expression
```

Actions speak. Just fix it. The code itself shows you heard the feedback.

### Gracefully Correcting Your Pushback

If you pushed back and were wrong:
```
Good: "You were right - I checked [X] and it does [Y]. Implementing now."
Bad:  Long apology or defending why you pushed back
```

State the correction factually and move on.

---

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Performative agreement | State requirement or just act |
| Blind implementation | Verify against codebase first |
| Batch without testing | One at a time, test each |
| Assuming reviewer is right | Check if breaks things |
| Avoiding pushback | Technical correctness > comfort |
| Partial implementation | Clarify all items first |
| Skipping review because "it's simple" | Simple code breaks too |

## The Bottom Line

**Requesting:** Review early, review often. Precisely crafted context for the reviewer.

**Receiving:** External feedback = suggestions to evaluate, not orders to follow. Verify. Question. Then implement.

No performative agreement. Technical rigor always.
