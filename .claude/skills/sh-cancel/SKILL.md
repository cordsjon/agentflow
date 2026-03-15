---
name: sh:cancel
description: "Cancel active Ralph loop and report iteration count"
---

# /sh:cancel — Cancel Ralph Loop

## Usage

```
/sh:cancel
```

## Behavioral Flow

1. **Check**: Test if `.claude/ralph-loop.local.md` exists
   ```bash
   test -f .claude/ralph-loop.local.md && echo "EXISTS" || echo "NOT_FOUND"
   ```

2. **If NOT_FOUND**: Report "No active Ralph loop found." and stop.

3. **If EXISTS**:
   - Read `.claude/ralph-loop.local.md` to get the current iteration number from the `iteration:` field
   - Remove the file:
     ```bash
     rm .claude/ralph-loop.local.md
     ```
   - Report: "Cancelled Ralph loop (was at iteration N)" where N is the iteration value
