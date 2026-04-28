---
name: sh-finish
description: "Use when implementation is done and all tests pass — before merging a branch, creating a PR, or declaring a feature complete"
---

# Finishing a Development Branch

## Overview

Guide completion of development work by presenting clear options and handling chosen workflow.

**Core principle:** Verify tests -> Present options -> Execute choice -> Clean up.

**Announce at start:** "I'm using the sh:finish skill to complete this work."

## No-Op Check

**If working on main/master directly:** This skill is a no-op. Report: "Working directly on main -- no branch finishing needed. Work is already committed." and stop.

## The Process

### Step 1: Verify Tests

**Before presenting options, verify tests pass:**

```bash
# Run project's test suite
pytest / npm test / cargo test / go test ./...
```

**If tests fail:**
```
Tests failing (<N> failures). Must fix before completing:

[Show failures]

Cannot proceed with merge/PR until tests pass.
```

Stop. Don't proceed to Step 2.

**If tests pass:** Continue to Step 1b.

### Step 1b: CLI Registration Check (mandatory)

Scan the branch diff for new CLI entry points:

```bash
BASE=$(git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null)
git diff --name-only --diff-filter=A "$BASE" HEAD | grep -E '\.(py|sh)$'
```

For each new `.py` file, check if it's a CLI entry point:
```bash
grep -l "if __name__\|argparse\|import click\|import typer" <file>
```

For each new `.sh` file, check if it's an invocable script (has `#!/` shebang and takes args or performs a standalone task).

**For each CLI file detected**, verify both registration files exist in `~/.claude/projects/-Users-jcords-macmini-projects/memory/`:

1. `reference_<name>_cli.md` — path, invocation, what manual step it replaces
2. `feedback_use_<name>_cli.md` — "when X, use CLI — never manual"
3. A line in the relevant project `CLAUDE.md` under Tool Preferences

**If any registration is missing:**

```
CLI Registration Required — cannot proceed

New CLI detected: <path>
Missing:
  [ ] reference_<name>_cli.md in memory/
  [ ] feedback_use_<name>_cli.md in memory/
  [ ] CLAUDE.md Tool Preferences entry

Create these now, then re-run sh:finish.
```

Stop. Do not proceed to Step 2 until all detected CLIs are registered.

**If no new CLI files detected, or all are registered:** Continue to Step 2.

### Step 2: Determine Base Branch

```bash
# Try common base branches
git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null
```

Or ask: "This branch split from main -- is that correct?"

### Step 3: Present Options

Present exactly these 4 options:

```
Implementation complete. What would you like to do?

1. Merge back to <base-branch> locally
2. Push and create a Pull Request
3. Keep the branch as-is (I'll handle it later)
4. Discard this work

Which option?
```

**Don't add explanation** - keep options concise.

### Step 4: Execute Choice

#### Option 1: Merge Locally

```bash
# Switch to base branch
git checkout <base-branch>

# Pull latest
git pull

# Merge feature branch
git merge <feature-branch>

# Verify tests on merged result
<test command>

# If tests pass
git branch -d <feature-branch>
```

Then: Cleanup worktree (Step 5)

#### Option 2: Push and Create PR

```bash
# Push branch
git push -u origin <feature-branch>

# Create PR
gh pr create --title "<title>" --body "$(cat <<'EOF'
## Summary
<2-3 bullets of what changed>

## Test Plan
- [ ] <verification steps>
EOF
)"
```

Then: Cleanup worktree (Step 5)

#### Option 3: Keep As-Is

Report: "Keeping branch <name>. Worktree preserved at <path>."

**Don't cleanup worktree.**

#### Option 4: Discard

**Confirm first:**
```
This will permanently delete:
- Branch <name>
- All commits: <commit-list>
- Worktree at <path>

Type 'discard' to confirm.
```

Wait for exact confirmation.

If confirmed:
```bash
git checkout <base-branch>
git branch -D <feature-branch>
```

Then: Cleanup worktree (Step 5)

### Step 5: Cleanup Worktree

**For Options 1, 2, 4:**

Check if in worktree:
```bash
git worktree list | grep $(git branch --show-current)
```

If yes:
```bash
git worktree remove <worktree-path>
```

**For Option 3:** Keep worktree.

## Quick Reference

| Option | Merge | Push | Keep Worktree | Cleanup Branch |
|--------|-------|------|---------------|----------------|
| 1. Merge locally | Y | - | - | Y |
| 2. Create PR | - | Y | Y | - |
| 3. Keep as-is | - | - | Y | - |
| 4. Discard | - | - | - | Y (force) |

## Red Flags

**Never:**
- Proceed with failing tests
- Merge without verifying tests on result
- Delete work without confirmation
- Force-push without explicit request

**Always:**
- Verify tests before offering options
- Present exactly 4 options
- Get typed confirmation for Option 4
- Clean up worktree for Options 1 & 4 only

## Integration

**Called by:**
- **`/sh:execute`** - After all tasks complete
- **`/sh:parallel`** - After all parallel work is integrated

**Pairs with:**
- **`/sh:worktree`** - Cleans up worktree created by that skill
- **`/sh:verify`** - Verification gate before presenting options
