# Plan 2 — Webhook Listener — Design Spec

**Date:** 2026-04-28
**Status:** Draft v1 — design approved, awaiting spec-review and `/sh:plan`
**Owner:** Jonas Cords
**Parent spec:** `2026-04-28-opensandbox-pipeline-design.md` (§Completion Signal Contract, §Infrastructure)
**Predecessor:** Plan 1 — Infrastructure Foundation (SHIPPED 2026-04-28)

---

## Summary

Public webhook listener for the OpenSandbox pipeline. FastAPI app on Mac Mini `127.0.0.1:9090`, exposed publicly via `https://webhook.getaccess.cloud` (NPM proxy host on the VPS) over the existing autossh `-R VPS:9090 → Mac:9090` tunnel. Receives completion / failure / heartbeat signals from sandbox-resident jobs, validates per-job HMAC auth, deduplicates retries via Idempotency-Key, and updates job state plus pipeline-health observability surfaces.

Plan 2 ships the webhook *contract and ingress* against a flat-file Paperclip stub. Real Paperclip state-machine integration and a real sandbox client land in later plans.

---

## Scope

**In scope (Plan 2):**
- New subdomain `webhook.getaccess.cloud` with NPM proxy host + Let's Encrypt cert.
- Edge-level static bearer-token filter at NPM (`advanced_config`).
- FastAPI app `pipeline-webhook` with three endpoints: `/jobs/{id}/complete`, `/jobs/{id}/failed`, `/jobs/{id}/heartbeat`, plus public `GET /healthz`.
- Per-job HMAC-SHA256 signature verification with ±5min timestamp-skew window.
- SQLite-backed `Idempotency-Key` dedup (24h TTL) and hourly counter buckets.
- Append-only structured events to `~/projects/00_portmgr/job-log.jsonl`.
- Extension of `/pipeline/health` (Plan 1) with `webhook: up|down`, `webhook_received_24h`, `webhook_last_seen`.
- launchd plist for the FastAPI process, mirroring Plan 1's `pipeline-health` pattern.
- Smoke script (`infra/scripts/smoke-webhook.sh`) that doubles as executable contract reference.
- Idempotent NPM deploy script (`infra/scripts/deploy-webhook-npm.sh`) following the Plan 1 NPM-REST-API pattern.

**Out of scope (deferred, listed for traceability):**
- Real Paperclip async state machine (flat-file `jobs.json` stub only — concurrent jobs not supported).
- Sandbox-side webhook *client* implementation (lands with `sandbox-lifecycle` skill).
- In-app rate-limiting middleware (contract documented; enforcement deferred to multi-tenant phase).
- Apex `getaccess.cloud` TLS fix (pre-existing, tracked separately).
- Heartbeat-driven "stuck sandbox" detection logic (hooks for it land in Plan 2; consumer logic later).

---

## Architecture

```
Sandbox container (Mac Mini, per-job)
  └─ POST https://webhook.getaccess.cloud/jobs/{id}/{complete|failed|heartbeat}
        │   Authorization: Bearer <static_ingress_token>
        │   X-Webhook-Signature: sha256=<hmac_hex>          # key = per-job secret
        │   X-Webhook-Timestamp: <unix>                     # ±300s skew window
        │   Idempotency-Key: <uuid>                         # fresh per HTTP attempt
        │   Content-Type: application/json
        ▼
NPM proxy host  webhook.getaccess.cloud  (VPS, container "npm")
  ├─ Force-SSL + HSTS, Let's Encrypt cert
  ├─ advanced_config: 401 on bearer mismatch (drops noise at edge)
  └─ proxy_pass http://127.0.0.1:9090
        │
        ▼  (existing autossh -R VPS:9090 → Mac:9090, launched by
            com.gtxs.pipeline-webhook-tunnel — already running per Plan 1 handover)
        ▼
FastAPI app  pipeline-webhook  (Mac Mini, 127.0.0.1:9090, --workers 1)
  ├─ auth.verify_signature()      → 403 on bad HMAC
  ├─ auth.check_timestamp()       → 410 on skew > 300s
  ├─ store.dedup_or_record()      → 200 + already_recorded on replayed key
  ├─ paperclip_client.transition()→ 409 on terminal-state-already-set
  ├─ append → ~/projects/00_portmgr/job-log.jsonl
  └─ store.bump_counters()        → feeds /pipeline/health
```

---

## Endpoints

All endpoints under `https://webhook.getaccess.cloud`. JSON bodies, UTF-8.

### `POST /jobs/{job_id}/complete` — terminal success
```json
{
  "job_id": "job-042",
  "status": "complete",
  "artifact": "/workspace/artifacts/build.apk",
  "duration_s": 847,
  "retry_count": 0,
  "gap_count": 0,
  "logs_tail": ["…", "…"],
  "hermes_result": {"passed": true, "endpoints_green": 12, "endpoints_total": 12}
}
```

### `POST /jobs/{job_id}/failed` — terminal failure
```json
{
  "job_id": "job-042",
  "status": "failed",
  "duration_s": 412,
  "retry_count": 0,
  "gap_count": 1,
  "error": {"phase": "hermes", "code": "screenshot_black", "message": "…"},
  "logs_tail": ["…", "…"]
}
```

### `POST /jobs/{job_id}/heartbeat` — liveness ping
```json
{"job_id": "job-042", "phase": "running", "elapsed_s": 312}
```
Sandbox emits every 5 minutes during RUNNING/VERIFYING. No body fields beyond the three shown.

### `GET /healthz` — public, unauthenticated
```json
{"webhook": "up"}
```
Used by the deploy smoke check and by Plan 1's `/pipeline/health` to fill its `webhook` field.

### Required headers

| Header | Required on | Purpose |
|---|---|---|
| `Authorization: Bearer <static_ingress_token>` | all auth'd endpoints | Edge filter at NPM; rotated quarterly. Token in `~/projects/30_OpenSandboxPipeline/infra/.env` as `WEBHOOK_BEARER`. |
| `X-Webhook-Signature: sha256=<hex>` | all auth'd endpoints | HMAC-SHA256 over raw request body, key = per-job secret looked up by `job_id`. |
| `X-Webhook-Timestamp: <unix>` | all auth'd endpoints | Epoch seconds. Rejected if abs(skew) > 300. |
| `Idempotency-Key: <uuid>` | all auth'd endpoints | Fresh UUID per HTTP attempt (not per job). Stored 24h. |
| `Content-Type: application/json` | POST endpoints | Strictly enforced. |

### Response status codes

| Code | Meaning |
|---|---|
| 200 | Accepted (first time) |
| 200 with `{"status":"already_recorded"}` | Duplicate `Idempotency-Key` replay; original response replayed |
| 400 | Malformed body, missing required fields, schema violation |
| 401 | Missing/invalid bearer (rejected at NPM edge, never reaches app) |
| 403 | HMAC signature invalid |
| 409 | Terminal state already set; logged as `late_terminal`, no transition |
| 410 | Timestamp skew > 300s |
| 429 | Per-`job_id` rate limit (60/min heartbeat, 10/min terminal) — *contract documented; enforcement deferred* |

---

## Auth model

**Per-job HMAC-SHA256.** Paperclip generates a fresh `job_secret` (32 random bytes, hex-encoded) when it creates the sandbox. The secret is:

1. Stored in the Paperclip job record (flat-file `jobs.json` for Plan 2; real DB later).
2. Injected into the sandbox container as env var `WEBHOOK_HMAC_SECRET` at startup.
3. Looked up by the webhook handler via `paperclip_client.get_job_secret(job_id)` on every request.

The webhook is **stateless w.r.t. secrets** — it never persists them, only queries Paperclip. Secret rotation is a Paperclip concern; webhook code does not change.

**Static bearer at edge.** A second, coarser secret (`WEBHOOK_BEARER`) lives in NPM's `advanced_config` and is shared across all jobs. Rotated quarterly. Purpose: drop random internet noise at the edge so the FastAPI app's logs and rate budget reflect plausible traffic only. This is defense-in-depth, not the primary auth.

**Threat model coverage:**
- Replay across job boundaries — blocked by per-job HMAC (different secret per job).
- Replay within a job — blocked by `Idempotency-Key` dedup (24h window).
- Old-message replay (captured signed request, sent later) — blocked by ±300s timestamp window.
- Random internet scanning — blocked at NPM by bearer check.
- Compromised sandbox secret — blast radius limited to that one job.

---

## Idempotency & state-machine semantics

**Dedup key:** `Idempotency-Key` header (UUID per HTTP attempt). Stored in SQLite `idempotency_keys` table with 24h TTL. On replay: return cached response status and `{"status":"already_recorded"}` body.

**First-terminal-wins.** The first `complete` or `failed` call for a `job_id` transitions state. Any subsequent terminal call (e.g., late `failed` arriving after `complete`):
- Returns `409 Conflict`.
- Logs a `late_terminal` event to `job-log.jsonl` with both payloads.
- Does *not* re-transition state.

Heartbeats arriving after a terminal state also return `409` and are logged as `late_heartbeat`.

**Concurrency posture (Plan 2):**
- Uvicorn single-worker (`--workers 1`) provides serialization within the process.
- `Idempotency-Key` dedup is the primary correctness mechanism (works under any worker count, future-proofing).
- Flat-file `jobs.json` (the Paperclip stub) is **not** safe under concurrent jobs — Plan 2 explicitly assumes sequential job execution. Documented as a known limit; lifted when real Paperclip lands.

---

## Retry semantics (sandbox client side, contract only)

Sandbox webhook client behavior — Plan 2 specifies the contract; the implementation lands with `sandbox-lifecycle`:

- **5 attempts**, exponential backoff: 1s, 2s, 4s, 8s, 16s (~31s total budget).
- Treats 2xx and 409 as terminal-success-of-the-call (no further retries).
- Treats 4xx other than 408/429 as permanent failure (no retries; falls back to `/workspace/.done` file marker per parent spec §Completion Signal Contract).
- Treats 5xx, 408, 429, and connection errors as transient (retried).
- Same `Idempotency-Key` reused across retries of the same logical event (UUID generated once per attempt sequence, not per HTTP call).

After 5 failed attempts the sandbox falls through to the `.done` file marker (already specified in parent spec; no Plan 2 change needed). 30s polling fallback wins on any webhook outage longer than the retry budget.

---

## App structure

**Repo path:** `~/projects/30_OpenSandboxPipeline/services/webhook/` (new; sibling to `infra/`, `scripts/`, `tests/`).

```
services/webhook/
├── app.py              # FastAPI app, route handlers
├── auth.py             # HMAC verify, timestamp check, bearer is enforced at NPM
├── store.py            # SQLite: idempotency_keys, webhook_counters
├── paperclip_client.py # get_job_secret(job_id), transition(job_id, new_state, payload)
├── models.py           # Pydantic: CompleteBody, FailedBody, HeartbeatBody
├── config.py           # env loader: PAPERCLIP_DB_PATH, WEBHOOK_DB_PATH, JOB_LOG_PATH
└── tests/
    ├── conftest.py     # FastAPI TestClient, in-memory SQLite, tmp job-log.jsonl
    ├── test_auth.py
    ├── test_idempotency.py
    └── test_endpoints.py
```

### SQLite schema (`~/projects/30_OpenSandboxPipeline/var/webhook.db`)

```sql
CREATE TABLE idempotency_keys (
  key             TEXT    PRIMARY KEY,
  job_id          TEXT    NOT NULL,
  endpoint        TEXT    NOT NULL,         -- 'complete' | 'failed' | 'heartbeat'
  response_status INTEGER NOT NULL,
  response_body   TEXT    NOT NULL,         -- cached JSON for replay
  received_at     INTEGER NOT NULL          -- unix; rows >24h purged on write
);
CREATE INDEX idx_idem_received_at ON idempotency_keys(received_at);

CREATE TABLE webhook_counters (
  bucket_hour     INTEGER PRIMARY KEY,      -- floor(unix / 3600)
  received        INTEGER NOT NULL DEFAULT 0,
  rejected_auth   INTEGER NOT NULL DEFAULT 0,
  rejected_replay INTEGER NOT NULL DEFAULT 0
);
```

`webhook_received_24h` = `SELECT SUM(received) FROM webhook_counters WHERE bucket_hour >= floor(now/3600) - 24`. Old rows can be left in place (365 rows/year is negligible) or pruned by a daily cron.

### Paperclip client stub

For Plan 2, `paperclip_client.py` reads/writes a flat file at `~/projects/30_OpenSandboxPipeline/var/jobs.json`:

```json
{
  "jobs": {
    "job-042": {
      "secret": "<hex>",
      "state": "RUNNING",
      "created_at": 1735776000
    }
  }
}
```

Functions exposed:
- `get_job_secret(job_id) -> str | None`
- `get_job_state(job_id) -> str | None`
- `transition(job_id, new_state, payload) -> tuple[bool, str]` — returns `(transitioned, current_state)`. Returns `(False, current_state)` on terminal-state guard hits, never raises.

When real Paperclip lands, `paperclip_client.py` is the only file that changes; `app.py` and tests are unaffected.

### Process management

`launchctl` plist `com.gtxs.pipeline-webhook` at `~/Library/LaunchAgents/`:

```xml
<key>ProgramArguments</key>
<array>
  <string>/usr/bin/env</string>
  <string>uvicorn</string>
  <string>app:app</string>
  <string>--host</string>
  <string>127.0.0.1</string>
  <string>--port</string>
  <string>9090</string>
  <string>--workers</string>
  <string>1</string>
</array>
<key>WorkingDirectory</key>
<string>/Users/jcords-macmini/projects/30_OpenSandboxPipeline/services/webhook</string>
<key>KeepAlive</key><true/>
<key>ThrottleInterval</key><integer>10</integer>
```

Logs to `~/Library/Logs/pipeline-webhook.{out,err}.log`.

---

## Observability

### `/pipeline/health` extension (Plan 1 endpoint)

Existing response gains three fields:

```json
{
  "opensandbox": "up",
  "hermes": "down",
  "paperclip": "up",
  "active_jobs": 0,
  "webhook": "up",
  "webhook_received_24h": 12,
  "webhook_last_seen": "2026-04-28T22:14:08Z"
}
```

`webhook: up` ⇔ `GET http://127.0.0.1:9090/healthz` returns 200 within a 1s timeout. Counters served from `webhook_counters` table.

### Structured events

Webhook handler appends one line per event to the existing `~/projects/00_portmgr/job-log.jsonl`. New event names (additive — no change to Plan 1 events):

| Event | When |
|---|---|
| `WEBHOOK_RECEIVED` | First-time accepted POST (any endpoint) |
| `WEBHOOK_HEARTBEAT` | Heartbeat accepted (split out for ratelimit visibility) |
| `WEBHOOK_REPLAY` | Idempotency-Key already seen; replayed cached response |
| `WEBHOOK_REJECTED_AUTH` | HMAC signature invalid |
| `WEBHOOK_REJECTED_SKEW` | Timestamp skew > 300s |
| `WEBHOOK_LATE_TERMINAL` | Terminal state already set when terminal POST arrived |

Sample row:
```json
{"event":"WEBHOOK_RECEIVED","job_id":"job-042","endpoint":"complete","ts":"2026-04-28T22:14:08Z","duration_s":847,"retry_count":0,"idem":"…"}
```

---

## Deploy chain (idempotent, mirrors Plan 1)

1. **DNS** — manual, one-time: A record `webhook.getaccess.cloud` → VPS IP.
2. **NPM proxy host** — `infra/scripts/deploy-webhook-npm.sh` creates/updates host via NPM REST API on `127.0.0.1:81/api/`. Scheme `http`, forward `127.0.0.1:9090`, force-SSL on, HSTS on, websocket off, body size 10MB. `advanced_config` block includes the bearer check.
3. **launchd plist** — `infra/scripts/install-webhook-launchd.sh` writes the plist and `launchctl bootstrap`s it.
4. **autossh** — already running per Plan 1 (`com.gtxs.pipeline-webhook-tunnel` with `-R 9090:127.0.0.1:9090`). No change.
5. **Verification** — `infra/scripts/smoke-webhook.sh`:
   - `curl -sf https://webhook.getaccess.cloud/healthz` → `{"webhook":"up"}`
   - signed POST to `/jobs/test-job/complete` with a fixture secret → 200
   - replay same `Idempotency-Key` → 200 + `already_recorded`
   - `curl -sf https://paperclip.getaccess.cloud/pipeline/health | jq .webhook` → `"up"`

All scripts re-runnable with no side effects on success — Plan 1 idempotency contract.

---

## Test strategy

| Layer | What | Tool | Pass criteria |
|---|---|---|---|
| Unit | `auth.verify_signature`, `auth.check_timestamp`, `store.dedup_or_record`, body validation | pytest + `httpx.AsyncClient` against `TestClient` | All branches; ≥90% line coverage on `auth.py`, `store.py` |
| Integration | POST → SQLite write → counter increment → `job-log.jsonl` append | pytest + tmp_path SQLite + tmp `job-log.jsonl` | Each endpoint produces correct DB rows + log lines |
| Contract | Replay → 200/`already_recorded`; bad HMAC → 403; skew → 410; late terminal → 409 + `late_terminal`; bad bearer simulated → 401 path | pytest scenarios | Each path returns documented status and event |
| Smoke (post-deploy) | `infra/scripts/smoke-webhook.sh` against the public URL with a fixture secret | bash + curl + openssl | All 4 assertions in §Deploy chain step 5 pass |

**Test contract before test count:** unit/integration tests share a single `conftest.py` with fixtures for (a) in-memory SQLite, (b) tmp `job-log.jsonl`, (c) a mock `paperclip_client` with a known `test-job` + secret, (d) a `signed_post` helper that builds valid auth headers. No test mocks the webhook app itself — all tests run real `TestClient` requests through the real handler.

---

## Phase 1 success gate (Plan 2 specific)

Plan 2 is SHIPPED when all of the following hold:

1. `https://webhook.getaccess.cloud/healthz` returns `{"webhook":"up"}` (200, valid TLS).
2. Smoke script passes end-to-end against the deployed instance.
3. `https://paperclip.getaccess.cloud/pipeline/health` includes `webhook: up` and `webhook_received_24h ≥ 1` (smoke run counts).
4. launchd unit `com.gtxs.pipeline-webhook` is `loaded` + running.
5. NPM proxy host id for `webhook.getaccess.cloud` recorded in handover.
6. `services/webhook/tests/` passes locally with ≥90% coverage on `auth.py` and `store.py`.
7. KP-12xx entry added if any new anti-pattern surfaces during build.

No real sandbox traffic required for SHIP — Plan 2 establishes the *contract and ingress*. Real traffic arrives with `sandbox-lifecycle`.

---

## Resolved decisions (Plan 2 brainstorm, 2026-04-28)

1. **Subdomain:** dedicated `webhook.getaccess.cloud` (not subpath on `paperclip.*`, not generic `api.*`). Trade: minor DNS/cert sprawl for clean blast-radius isolation.
2. **Payload schema:** full envelope (status, artifact, duration_s, retry_count, gap_count, optional error, optional logs_tail, optional hermes_result), three split endpoints (`complete`, `failed`, `heartbeat`).
3. **Auth:** per-job HMAC-SHA256 + edge-level static bearer at NPM. Threat model favored isolation over simplicity.
4. **Retry semantics (sandbox client):** 5 attempts, exponential backoff 1/2/4/8/16s, fall through to `.done` file marker on exhaustion.
5. **Idempotency:** `Idempotency-Key` header, SQLite-backed seen-keys table with 24h TTL, response cached for replay. First-terminal-wins for state transitions.
6. **Observability:** extend `/pipeline/health` with `webhook` field + 24h count + last-seen ts; reuse existing `job-log.jsonl` with new `WEBHOOK_*` event names.
7. **Paperclip integration deferred:** Plan 2 ships against a flat-file `jobs.json` stub. Concurrent jobs not supported until real Paperclip lands.
8. **Process model:** uvicorn `--workers 1`, launchd-managed, mirrors Plan 1 `pipeline-health` pattern.

---

## Architecture insights captured

- **Webhook is stateless w.r.t. secrets.** Per-job HMAC means secret storage lives in Paperclip; the webhook only queries. Secret rotation never touches webhook code.
- **`paperclip_client.py` is the swap point.** Plan 2 stubs it against a flat file; the real Paperclip lands by replacing this module only. `app.py` and tests are unaffected.
- **Edge-level bearer is the [TENET: delete-first] play.** Pre-filtering at NPM lets the FastAPI app drop a layer of in-app rate limiting that would otherwise feel necessary.
- **Smoke script doubles as executable contract.** It's both deploy verification *and* the reference implementation a future sandbox client will mirror. Keep under 50 lines and well-commented.

These insights belong in `00_Governance/ARCHITECTURE.md` per the global tenet — to be added during plan execution.

---

## References

- Parent spec: `~/projects/20_agentflow/docs/specs/2026-04-28-opensandbox-pipeline-design.md`
- Plan 1 plan: `~/projects/20_agentflow/docs/plans/2026-04-28-pipeline-plan1-infrastructure-foundation.md`
- Plan 1 handover: `~/projects/00_Governance/HANDOVER-30_OpenSandboxPipeline-2026-04-28-2240.md`
- Project repo: `~/projects/30_OpenSandboxPipeline/`
- NPM REST API base: `127.0.0.1:81/api/` (VPS, container `npm`)
- Existing tunnel: `com.gtxs.pipeline-webhook-tunnel` (Mac Mini launchd, autossh `-R`)
