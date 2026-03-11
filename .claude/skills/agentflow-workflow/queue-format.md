# Queue Format Reference

## Task Entry Format (3 lines)

```markdown
- [ ] **Phase: Task description** `@agent` `stall:0`
  `/command "args" --attribute`
  _Context: brief notes, file refs, links -- confidence:0.85_
```

### Line 1: Task Header
- Checkbox: `[ ]` unchecked, `[x]` done
- **Bold phase label:** implement, test, refactor, spike, docs, analyze, cleanup, commit, deploy
- Task description: what to do
- `@agent` (optional): routing assignment from orchestrator
- `stall:N` (optional): stall counter

### Line 2: Command
- Indented, backtick-wrapped command
- Directly pasteable into the agent
- Should be self-contained with arguments

### Line 3: Context (optional)
- Indented, italic `_Context:_`
- File paths, spec links, related items
- `confidence:X.X` (optional): routing confidence score

## Queue Markers

- `> **>>> NEXT**` — blockquote marker above the queue list
- First unchecked `[ ]` = next task for autopilot
- Queue order = optimal execution sequence

## Phase Labels

| Phase | Meaning |
|-------|---------|
| `implement` | Write new code |
| `test` | Write or update tests |
| `refactor` | Restructure without behavior change |
| `spike` | Time-boxed research/exploration |
| `docs` | Documentation update |
| `analyze` | Quality analysis scan |
| `audit` | Deep security/perf/arch review |
| `cleanup` | Fix findings, enforce standards |
| `commit` | Create atomic commit |
| `deploy` | Run deployment |
| `migrate` | Database migration |

## Example Queue

```markdown
> **>>> NEXT**

## Queue

- [ ] **implement: US-DM-01 CSS custom property theme tokens**
  `/test-driven-development`
  _Context: shell.css, requirements/SPEC_DARK_MODE.md_
- [ ] **implement: US-DM-02 Theme toggle component**
  `/test-driven-development`
  _Context: templates/shell.html, static/js/theme.js_
- [ ] **analyze: Quality scan of changed files**
  `/sc:analyze "shell.css theme.js" --focus quality`
- [ ] **cleanup: Fix findings and enforce standards**
  `/sc:cleanup --type all`
- [ ] **commit: Atomic conventional commit**
  `/commit-smart`
```
