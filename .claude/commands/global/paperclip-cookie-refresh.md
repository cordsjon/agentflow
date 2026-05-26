---
name: paperclip-cookie-refresh
description: "Test and (if needed) refresh /tmp/paperclip_session.txt during an active CC session. Designed for /loop — read-only when cookie is valid, autonomous Playwright refresh when not."
---

# /paperclip-cookie-refresh

This is the **session-bound** counterpart to the Dagu `paperclip-cookie-watchdog` DAG.
The Dagu version can only *detect* staleness and ntfy you. This one can *refresh* — because Playwright MCP is available inside an active CC session.

## Intended usage

```
/loop 1800s /paperclip-cookie-refresh
```

That fires every 30 minutes during a CC session. On 5 of 6 ticks it's a 1-second curl test that prints `COOKIE_OK` and exits. On the rare expired-cookie tick, it logs in via Playwright and writes a fresh cookie.

Manual invocation also fine — just `/paperclip-cookie-refresh`.

## Execution steps (follow exactly)

**Step 1 — Probe cookie**

```bash
if [ ! -f /tmp/paperclip_session.txt ]; then
  echo "STATUS=MISSING"
elif [ "$(curl -s -b "$(cat /tmp/paperclip_session.txt)" \
    'https://paperclip.getaccess.cloud/api/companies/5d0398eb-f390-4c0c-a147-661212903eee/issues?limit=1' \
    -H 'Accept: application/json' -o /dev/null -w '%{http_code}')" = "200" ]; then
  echo "STATUS=OK"
else
  echo "STATUS=EXPIRED"
fi
```

**Step 2 — If STATUS=OK, stop here.** Print `COOKIE_OK (cookie age: $(stat -f %SB /tmp/paperclip_session.txt))` and end the turn. Do NOT touch Playwright. Most invocations land here.

**Step 3 — If STATUS=MISSING or EXPIRED, refresh:**

  a. Read the service-account password from Keychain:
     ```bash
     security find-generic-password -s 'paperclip-getaccess-cloud' -w
     ```
     (Email is `dagu-automation@paperclip.local` — created 2026-05-18 as a dedicated automation user.)

  b. Drive Playwright (use the MCP tools, never inline JS via Bash):
     - `browser_navigate` → `https://paperclip.getaccess.cloud/auth`
     - `browser_run_code_unsafe` with:
       ```js
       async (page) => {
         const pw = "INSERT_PASSWORD_FROM_KEYCHAIN_HERE";
         await page.fill('input[name="email"]', 'dagu-automation@paperclip.local');
         await page.fill('input[name="password"]', pw);
         await page.click('button:has-text("Sign In")');
         await page.waitForTimeout(2500);
         const cookies = await page.context().cookies('https://paperclip.getaccess.cloud');
         return cookies.map(c => `${c.name}=${c.value}`).join('; ');
       }
       ```
     - `browser_close`

  c. Atomic write the returned cookie string to `/tmp/paperclip_session.txt`:
     ```bash
     umask 077 && echo -n "<COOKIE>" > /tmp/paperclip_session.txt.new \
       && mv /tmp/paperclip_session.txt.new /tmp/paperclip_session.txt
     ```

  d. Re-run Step 1 to verify `STATUS=OK`. If still not OK, the service account itself may need re-bootstrapping — see [reference_paperclip.md](/Users/jcords-macmini/.claude/projects/-Users-jcords-macmini-projects/memory/reference_paperclip.md) "Re-bootstrap recipe".

## What this command is NOT

- Not for refreshing the container-side Claude OAuth (that's the `paperclip-token-watchdog.yaml` Dagu DAG — different layer entirely).
- Not for read/write of Paperclip issues — use `/paperclip` for that.
- Not a substitute for the Dagu `paperclip-cookie-watchdog.yaml`, which keeps detecting between sessions when CC is closed.

## When NOT to /loop this

- During short sessions (<30min) — probably no value, single manual check is enough.
- When you're not actually working with Paperclip — wastes a model invocation per cycle.
- After 22:00 local time — the cookie lasts ~7 days, you don't need 30-min polling overnight.
