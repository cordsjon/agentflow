---
name: careful
description: "Use before production work, deployments, or any session where destructive commands must be blocked — toggles on/off"
---

# /careful — On-Demand Destructive Command Guard

Toggle careful mode on or off. When active, a PreToolUse hook blocks:
- `rm -rf`, `rm -fr`
- `git push --force`, `git push -f`, `git reset --hard`, `git clean -f`, `git checkout -- .`
- `DROP TABLE`, `DROP DATABASE`, `DELETE FROM` (without WHERE), `TRUNCATE TABLE`
- `docker rm -f`, `docker system prune`
- `kill -9`, `killall`, `pkill`

## Behavior

1. Check if `~/.claude/guards/careful.active` exists
2. If it exists: **remove it** (deactivate) and confirm
3. If it doesn't exist: **create it** (activate) and confirm

## Implementation

```bash
if [ -f ~/.claude/guards/careful.active ]; then
    rm ~/.claude/guards/careful.active
    # Report: careful mode OFF
else
    touch ~/.claude/guards/careful.active
    # Report: careful mode ON
fi
```

Report the new state clearly. No other action needed.
