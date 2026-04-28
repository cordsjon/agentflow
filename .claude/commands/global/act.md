# /act — Execute from Act Queue

Pick up the pending command from `~/projects/00_Governance/act/`, brief yourself from it, and execute — zero re-briefing.

## Steps

### 1. Check the queue

```bash
ls ~/projects/00_Governance/act/*.md 2>/dev/null | grep -v "/done/"
```

- **Empty:** "Act queue empty." Stop.
- **One file:** proceed with it.
- **Multiple files:** list them (filename + story field from frontmatter), ask which to run.

### 2. Read the act file

Fields:
- `project` — canonical project name
- `story` — US-XX story ID
- `plan` — absolute path to plan file (or `NEEDS_PLAN`)
- `intent` — `execute` | `plan` | `deploy` | `panel`
- `context` — brief AC/scope summary

### 3. Execute by intent

| intent | action |
|--------|--------|
| `execute` | Read the plan file. Announce "Executing [story]: [context]". Run `/sh:execute`. |
| `plan` | Read the story from the project BACKLOG. Run `/sh:plan`. |
| `deploy` | Run the project's deploy script (`bash deploy.sh push` or equivalent). |
| `panel` | Run `/sh:spec-panel` on the story. |

If `plan` field is `NEEDS_PLAN`: switch intent to `plan` regardless of what the file says.

### 4. Archive

After execution completes (or if user abandons), move the act file:

```bash
mv ~/projects/00_Governance/act/<filename>.md ~/projects/00_Governance/act/done/
```

## What NOT to do

- Do not ask "are you sure?" — the act file is the confirmation.
- Do not summarise what you're about to do at length — one line announcement, then act.
- Do not leave the act file in place after execution — always archive.
