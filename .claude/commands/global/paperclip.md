---
name: paperclip
description: "Interact with Paperclip agent orchestrator — create issues, list status, assign agents, check runs. No auth fumbling."
---

# /paperclip — Agent Orchestrator

All commands run via `~/.claude/scripts/paperclip.sh` (curl + saved cookie). Zero Playwright overhead.

## Quick Reference

```bash
# List all issues
bash ~/.claude/scripts/paperclip.sh list

# Filter by status / project / agent
bash ~/.claude/scripts/paperclip.sh list todo
bash ~/.claude/scripts/paperclip.sh list con
bash ~/.claude/scripts/paperclip.sh list researcher

# Show issue details
bash ~/.claude/scripts/paperclip.sh show GET-35

# Create issue: title project agent [status] [priority]
bash ~/.claude/scripts/paperclip.sh create "Title here" con researcher todo high

# Change status
bash ~/.claude/scripts/paperclip.sh status GET-35 in_progress

# Reassign
bash ~/.claude/scripts/paperclip.sh assign GET-35 eng
```

## Creating Issues with Descriptions

For issues that need a description body (most do), use curl directly:

```bash
curl -sf -b "$(cat /tmp/paperclip_session.txt)" \
  "https://paperclip.getaccess.cloud/api/companies/5d0398eb-f390-4c0c-a147-661212903eee/issues" \
  -X POST -H "Content-Type: application/json" -H "Accept: application/json" \
  -H "Origin: https://paperclip.getaccess.cloud" \
  -d "$(python3 -c "
import json
print(json.dumps({
    'title': 'Issue title',
    'description': '''Multi-line description with AC here.''',
    'projectId': '087c1d0c-68fd-49cd-81a9-c7a14bed2abf',
    'assigneeAgentId': '627ea38e-3371-47ce-a05b-7f11be1ec7c3',
    'status': 'todo',
    'priority': 'high'
}))
")"
```

## Shorthand Resolution

**Do NOT rely on a hardcoded shorthand table.** Fetch the live list from the API:

```bash
# List all projects with IDs
bash ~/.claude/scripts/paperclip.sh list-projects 2>/dev/null || \
  curl -sf -b "$(cat /tmp/paperclip_session.txt)" \
  "https://paperclip.getaccess.cloud/api/companies/5d0398eb-f390-4c0c-a147-661212903eee/projects" \
  -H "Accept: application/json" | python3 -m json.tool

# List all agents with IDs
bash ~/.claude/scripts/paperclip.sh list-agents 2>/dev/null || \
  curl -sf -b "$(cat /tmp/paperclip_session.txt)" \
  "https://paperclip.getaccess.cloud/api/companies/5d0398eb-f390-4c0c-a147-661212903eee/agents" \
  -H "Accept: application/json" | python3 -m json.tool
```

There is **no static shorthand table**. `paperclip.sh` resolves any input case-insensitively against live agent/project fields (`id`, `name`, `persona`, `role`, `short`, `slug`, `key`, `displayName`, `shortName`). If a name like `cto` or `researcher` doesn't resolve, it isn't in the roster — run `list-agents` / `list-projects` to see what is.

## API Routes

| Action | Method | Endpoint |
|--------|--------|----------|
| List issues | GET | `/api/companies/{CID}/issues` |
| Create issue | POST | `/api/companies/{CID}/issues` |
| Update issue | PATCH | `/api/issues/{issueId}` (no company prefix!) |
| List agents | GET | `/api/companies/{CID}/agents` |
| List projects | GET | `/api/companies/{CID}/projects` |

All requests need `Origin: https://paperclip.getaccess.cloud` header for mutations.

## Auth

Cookie at `/tmp/paperclip_session.txt`. If 401 or missing:
1. `browser_navigate https://paperclip.getaccess.cloud` (skip if already on a paperclip page)
2. `browser_run_code`:
   ```js
   async (page) => {
     const c = await page.context().cookies('https://paperclip.getaccess.cloud');
     return c.map(x => `${x.name}=${x.value}`).join('; ');
   }
   ```
3. `Write` the returned string to `/tmp/paperclip_session.txt`.

**Do NOT use `browser_evaluate` + `document.cookie`** — the session cookie is `__Secure-better-auth.session_token` and is HttpOnly, so `document.cookie` returns empty. `context.cookies()` bypasses HttpOnly. The Cookie header is also redacted from `browser_network_requests`, so don't try that path either.

Only use Playwright for auth refresh — never for API calls.

## VPS Path Mapping

`~/projects/` → `/workspace/` (in Paperclip container)
