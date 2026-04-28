---
name: freeze
description: "Use when edits must be restricted to a single directory — blocks Edit/Write outside that path. Toggle on with a path argument, off with no argument"
argument-hint: "[directory-path]"
---

# /freeze — On-Demand Directory Lock

Restrict all Edit/Write operations to a single directory tree. When active, any file modification outside the frozen directory is blocked by a PreToolUse hook.

## Behavior

**With argument** (e.g., `/freeze src/app`):
1. Write the resolved absolute path to `~/.claude/guards/freeze.active`
2. Confirm: freeze mode ON, only `<path>` is writable

**Without argument** (`/freeze`):
1. If `~/.claude/guards/freeze.active` exists: **remove it** (deactivate) and confirm
2. If it doesn't exist: report that freeze mode is already off

## Implementation

```bash
if [ -n "$ARGUMENTS" ]; then
    # Resolve to absolute path
    RESOLVED=$(python3 -c "import os; print(os.path.realpath('$ARGUMENTS'))")
    echo "$RESOLVED" > ~/.claude/guards/freeze.active
    # Report: freeze mode ON, edits restricted to $RESOLVED
elif [ -f ~/.claude/guards/freeze.active ]; then
    CURRENT=$(cat ~/.claude/guards/freeze.active)
    rm ~/.claude/guards/freeze.active
    # Report: freeze mode OFF, was locked to $CURRENT
else
    # Report: freeze mode already off
fi
```

Report the new state clearly. No other action needed.
