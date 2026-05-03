---
name: hermes-status
description: "Show hermes-adapter stack health: provider, local fallback, 24h cost. One curl to :9109/status, rendered as a table."
---

# /hermes-status — Hermes stack health

Hits `GET http://localhost:9109/status` on the local `hermes-adapter` and renders the result as a markdown table.

## Run

```bash
curl -s --max-time 5 http://localhost:9109/status \
  | jq -r '
      "| Field | Value |",
      "|---|---|",
      "| adapter | \(.adapter // "?") |",
      "| provider | \(.provider // "?") |",
      "| local_fallback.available | \(.local_fallback.available // "?") |",
      "| local_fallback.model | \(.local_fallback.model // "?") |",
      "| local_fallback.in_flight | \(.local_fallback.in_flight // "?") |",
      "| cost_24h_usd | \(.cost_24h_usd // "n/a") |"
    '
```

## When the adapter is down

If curl returns nothing or non-JSON, do not retry, do not stack-trace. Print one line:

```
hermes-adapter unreachable on :9109. Check with: curl -s :9109/health
```

If `/health` also fails, the launchd service is probably down. Restart hint:

```bash
launchctl unload ~/Library/LaunchAgents/ai.hermes.adapter.plist
launchctl load   ~/Library/LaunchAgents/ai.hermes.adapter.plist
```

## What this is not

For Paperclip task operations (list / create / assign), use `/paperclip` — same backend, richer ergonomics. This command is only for stack health.
