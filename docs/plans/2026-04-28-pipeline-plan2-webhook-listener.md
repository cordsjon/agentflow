# Pipeline Plan 2: Webhook Listener Implementation Plan

> **For agentic workers:** REQUIRED: Use `/sh:execute` to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the public webhook ingress for the OpenSandbox pipeline — `https://webhook.getaccess.cloud` → autossh tunnel → FastAPI app on Mac Mini :9090 — with per-job HMAC auth, Idempotency-Key dedup, three endpoints (`/complete`, `/failed`, `/heartbeat`), `/healthz`, and `/pipeline/health` integration.

**Architecture:** New `services/webhook/` Python package inside `30_OpenSandboxPipeline`. FastAPI single-worker uvicorn under launchd at `127.0.0.1:9090`. SQLite for idempotency keys + hourly counter buckets. Flat-file `jobs.json` Paperclip stub (real Paperclip lands later, swap point is `paperclip_client.py` only). Public ingress is a new NPM proxy host on the VPS using the same NPM-REST-API pattern Plan 1 verified, reusing the already-running `com.gtxs.pipeline-webhook-tunnel` autossh `-R VPS:9090 → Mac:9090`.

**Tech Stack:** Python 3.11+, FastAPI, Pydantic v2, uvicorn, stdlib `sqlite3`/`hmac`/`hashlib`, pytest + `httpx`, launchd, newsyslog, NPM REST API, curl, openssl.

**Prerequisites this plan does NOT install:** Python 3.11+ (assumed), `pip`/`venv` (assumed), Plan 1 fully shipped (autossh tunnel `com.gtxs.pipeline-webhook-tunnel` running with `-R 9090:127.0.0.1:9090`, NPM credentials in `~/projects/30_OpenSandboxPipeline/infra/.env`, `pipeline-health.service` live on VPS).

**Source spec:** `~/projects/20_agentflow/docs/specs/2026-04-28-pipeline-plan2-webhook-listener-design.md` (8.6/10 spec-panel)

**One-time prerequisite (manual, you do this BEFORE Chunk 7):**
- Add DNS A record `webhook.getaccess.cloud` → `72.61.159.117` at the registrar. Propagation typically <5min for Cloudflare/similar.

---

## File Structure

New tree under existing project:

```
30_OpenSandboxPipeline/
├── services/
│   └── webhook/                          # NEW - FastAPI app
│       ├── __init__.py
│       ├── app.py                        # routes + wiring
│       ├── auth.py                       # HMAC verify, timestamp skew
│       ├── store.py                      # SQLite: idempotency + counters
│       ├── paperclip_client.py           # flat-file stub (swap point)
│       ├── models.py                     # Pydantic bodies
│       ├── config.py                     # env loader
│       ├── pyproject.toml                # deps
│       └── tests/
│           ├── conftest.py               # fixtures: tmp DB, signed_post helper
│           ├── test_auth.py
│           ├── test_store.py
│           ├── test_paperclip_client.py
│           ├── test_models.py
│           └── test_endpoints.py
├── var/                                  # NEW - runtime state (gitignored)
│   ├── webhook.db                        # created by app on first run
│   └── jobs.json                         # Paperclip flat-file stub
├── infra/
│   ├── com.gtxs.pipeline-webhook.plist   # NEW - launchd unit
│   ├── pipeline-webhook.newsyslog.conf   # NEW - log rotation
│   └── health_endpoint.py                # MODIFY - add webhook fields
└── scripts/
    ├── install-webhook-launchd.sh        # NEW - boot the local service
    ├── deploy-webhook-npm.sh             # NEW - create/update NPM proxy host
    └── smoke-webhook.sh                  # NEW - end-to-end verification
```

**Files modified outside this project:**
- VPS: NPM proxy host `webhook.getaccess.cloud` (id assigned by NPM, recorded in handover) — created via REST API.
- VPS: `pipeline-health.service` restarted to pick up new env vars (no file change beyond what's pushed via `deploy-vps.sh`).

---

## Chunk 1: Service Scaffolding

### Task 1: Create the Python package

**Files:**
- Create: `services/webhook/__init__.py`
- Create: `services/webhook/pyproject.toml`
- Create: `services/webhook/config.py`
- Create: `services/webhook/tests/__init__.py`

- [ ] **Step 1: Create the package skeleton**

```bash
cd ~/projects/30_OpenSandboxPipeline
mkdir -p services/webhook/tests var
touch services/webhook/__init__.py services/webhook/tests/__init__.py
```

- [ ] **Step 2: Write `pyproject.toml`**

`services/webhook/pyproject.toml`:

```toml
[project]
name = "pipeline-webhook"
version = "0.1.0"
description = "OpenSandbox pipeline webhook listener"
requires-python = ">=3.11"
dependencies = [
  "fastapi>=0.115",
  "uvicorn[standard]>=0.32",
  "pydantic>=2.9",
]

[project.optional-dependencies]
dev = [
  "pytest>=8.3",
  "pytest-asyncio>=0.24",
  "httpx>=0.27",
]

[tool.pytest.ini_options]
testpaths = ["tests"]
asyncio_mode = "auto"
```

- [ ] **Step 3: Write `config.py`**

`services/webhook/config.py`:

```python
"""Env-driven config. All paths absolute. No defaults that hide misconfiguration."""
import os
from pathlib import Path

PROJECT_ROOT = Path(os.getenv(
    "WEBHOOK_PROJECT_ROOT",
    Path(__file__).resolve().parents[2],  # services/webhook -> 30_OpenSandboxPipeline
))

WEBHOOK_DB_PATH = Path(os.getenv("WEBHOOK_DB_PATH", PROJECT_ROOT / "var" / "webhook.db"))
PAPERCLIP_DB_PATH = Path(os.getenv("PAPERCLIP_DB_PATH", PROJECT_ROOT / "var" / "jobs.json"))
JOB_LOG_PATH = Path(os.getenv("JOB_LOG_PATH", Path.home() / "projects/00_portmgr/job-log.jsonl"))

TIMESTAMP_SKEW_SECONDS = int(os.getenv("WEBHOOK_TIMESTAMP_SKEW", "300"))
IDEMPOTENCY_TTL_SECONDS = int(os.getenv("WEBHOOK_IDEM_TTL", "86400"))
MAX_BODY_BYTES = int(os.getenv("WEBHOOK_MAX_BODY_BYTES", "1048576"))  # 1 MB
```

- [ ] **Step 4: Create venv and install**

```bash
cd ~/projects/30_OpenSandboxPipeline/services/webhook
python3.11 -m venv .venv
.venv/bin/pip install -e ".[dev]"
```

Expected: install succeeds, prints `Successfully installed pipeline-webhook-0.1.0`.

- [ ] **Step 5: Commit**

```bash
cd ~/projects/30_OpenSandboxPipeline
git add services/webhook/__init__.py services/webhook/tests/__init__.py \
  services/webhook/pyproject.toml services/webhook/config.py
git commit -m "feat(webhook): scaffold pipeline-webhook package"
```

### Task 2: Add `var/` to gitignore

**Files:**
- Modify: `.gitignore`

- [ ] **Step 1: Append var/ to gitignore**

```bash
cd ~/projects/30_OpenSandboxPipeline
echo "var/" >> .gitignore
echo "services/webhook/.venv/" >> .gitignore
echo "services/webhook/**/__pycache__/" >> .gitignore
```

- [ ] **Step 2: Commit**

```bash
git add .gitignore
git commit -m "chore: ignore webhook runtime state and venv"
```

---

## Chunk 2: Storage Layer (SQLite)

### Task 3: Schema + idempotency dedup

**Files:**
- Create: `services/webhook/store.py`
- Create: `services/webhook/tests/conftest.py`
- Create: `services/webhook/tests/test_store.py`

- [ ] **Step 1: Write conftest with tmp-DB fixture**

`services/webhook/tests/conftest.py`:

```python
import sqlite3
from pathlib import Path

import pytest


@pytest.fixture
def tmp_db(tmp_path: Path) -> Path:
    db_path = tmp_path / "webhook.db"
    return db_path


@pytest.fixture
def tmp_job_log(tmp_path: Path) -> Path:
    return tmp_path / "job-log.jsonl"
```

- [ ] **Step 2: Write the failing test**

`services/webhook/tests/test_store.py`:

```python
import time

from store import Store


def test_init_creates_schema(tmp_db):
    s = Store(tmp_db)
    s.init_schema()
    # Both tables must exist with expected columns
    cols_idem = {c[1] for c in s._conn.execute("PRAGMA table_info(idempotency_keys)").fetchall()}
    cols_ctr = {c[1] for c in s._conn.execute("PRAGMA table_info(webhook_counters)").fetchall()}
    assert {"key", "job_id", "endpoint", "response_status", "response_body", "received_at"} <= cols_idem
    assert {"bucket_hour", "received", "rejected_auth", "rejected_replay"} <= cols_ctr


def test_dedup_first_call_records(tmp_db):
    s = Store(tmp_db); s.init_schema()
    cached = s.dedup_or_record("idem-1", "job-42", "complete", 200, '{"ok":true}')
    assert cached is None  # first time, no cached response


def test_dedup_replay_returns_cached(tmp_db):
    s = Store(tmp_db); s.init_schema()
    s.dedup_or_record("idem-1", "job-42", "complete", 200, '{"ok":true}')
    cached = s.dedup_or_record("idem-1", "job-42", "complete", 999, "ignored")
    assert cached == (200, '{"ok":true}')


def test_purge_old_keys(tmp_db):
    s = Store(tmp_db); s.init_schema()
    old_ts = int(time.time()) - 86400 - 60  # >24h ago
    s._conn.execute(
        "INSERT INTO idempotency_keys VALUES (?, ?, ?, ?, ?, ?)",
        ("old-key", "job-1", "complete", 200, "{}", old_ts),
    )
    s._conn.commit()
    s.purge_expired()
    rows = s._conn.execute("SELECT COUNT(*) FROM idempotency_keys").fetchone()[0]
    assert rows == 0


def test_counters_bump_and_24h_sum(tmp_db):
    s = Store(tmp_db); s.init_schema()
    s.bump_counter("received", n=1)
    s.bump_counter("received", n=2)
    s.bump_counter("rejected_auth", n=1)
    assert s.received_24h() == 3
```

- [ ] **Step 3: Run test — expect FAIL**

```bash
cd ~/projects/30_OpenSandboxPipeline/services/webhook
.venv/bin/pytest tests/test_store.py -v
```

Expected: `ModuleNotFoundError: No module named 'store'` — failing as designed.

- [ ] **Step 4: Implement `store.py`**

`services/webhook/store.py`:

```python
"""SQLite store: Idempotency-Key dedup + hourly counter buckets.

Single-file sqlite3 from stdlib — no migration framework, schema is idempotent
via CREATE TABLE IF NOT EXISTS. The store is not thread-safe by itself; the
FastAPI app runs `--workers 1` and aiosqlite is intentionally NOT used. If
we ever go multi-worker, swap this for a real DB before that switch.
"""
from __future__ import annotations

import sqlite3
import time
from pathlib import Path
from typing import Optional


class Store:
    def __init__(self, db_path: Path):
        self.db_path = db_path
        self.db_path.parent.mkdir(parents=True, exist_ok=True)
        self._conn = sqlite3.connect(self.db_path, isolation_level=None)  # autocommit
        self._conn.execute("PRAGMA journal_mode=WAL")
        self._conn.execute("PRAGMA synchronous=NORMAL")

    def init_schema(self) -> None:
        self._conn.executescript("""
        CREATE TABLE IF NOT EXISTS idempotency_keys (
          key             TEXT    PRIMARY KEY,
          job_id          TEXT    NOT NULL,
          endpoint        TEXT    NOT NULL,
          response_status INTEGER NOT NULL,
          response_body   TEXT    NOT NULL,
          received_at     INTEGER NOT NULL
        );
        CREATE INDEX IF NOT EXISTS idx_idem_received_at
          ON idempotency_keys(received_at);

        CREATE TABLE IF NOT EXISTS webhook_counters (
          bucket_hour     INTEGER PRIMARY KEY,
          received        INTEGER NOT NULL DEFAULT 0,
          rejected_auth   INTEGER NOT NULL DEFAULT 0,
          rejected_replay INTEGER NOT NULL DEFAULT 0
        );
        """)

    def dedup_or_record(
        self,
        key: str,
        job_id: str,
        endpoint: str,
        response_status: int,
        response_body: str,
    ) -> Optional[tuple[int, str]]:
        """Return cached (status, body) on replay, else record and return None."""
        row = self._conn.execute(
            "SELECT response_status, response_body FROM idempotency_keys WHERE key = ?",
            (key,),
        ).fetchone()
        if row is not None:
            return (row[0], row[1])
        self._conn.execute(
            "INSERT INTO idempotency_keys VALUES (?, ?, ?, ?, ?, ?)",
            (key, job_id, endpoint, response_status, response_body, int(time.time())),
        )
        return None

    def purge_expired(self, ttl_seconds: int = 86400) -> None:
        cutoff = int(time.time()) - ttl_seconds
        self._conn.execute(
            "DELETE FROM idempotency_keys WHERE received_at < ?", (cutoff,)
        )

    def bump_counter(self, column: str, n: int = 1) -> None:
        if column not in {"received", "rejected_auth", "rejected_replay"}:
            raise ValueError(f"unknown counter column: {column}")
        bucket = int(time.time()) // 3600
        self._conn.execute(
            "INSERT INTO webhook_counters (bucket_hour) VALUES (?) "
            "ON CONFLICT(bucket_hour) DO NOTHING",
            (bucket,),
        )
        self._conn.execute(
            f"UPDATE webhook_counters SET {column} = {column} + ? WHERE bucket_hour = ?",
            (n, bucket),
        )

    def received_24h(self) -> int:
        cutoff = (int(time.time()) // 3600) - 24
        row = self._conn.execute(
            "SELECT COALESCE(SUM(received), 0) FROM webhook_counters WHERE bucket_hour >= ?",
            (cutoff,),
        ).fetchone()
        return int(row[0])

    def last_seen_iso(self) -> Optional[str]:
        row = self._conn.execute(
            "SELECT MAX(received_at) FROM idempotency_keys"
        ).fetchone()
        if not row or row[0] is None:
            return None
        from datetime import datetime, timezone
        return datetime.fromtimestamp(row[0], tz=timezone.utc).isoformat()
```

- [ ] **Step 5: Run tests — expect PASS**

```bash
.venv/bin/pytest tests/test_store.py -v
```

Expected: 5 passed.

- [ ] **Step 6: Commit**

```bash
cd ~/projects/30_OpenSandboxPipeline
git add services/webhook/store.py services/webhook/tests/conftest.py services/webhook/tests/test_store.py
git commit -m "feat(webhook): SQLite store with idempotency dedup + counters"
```

---

## Chunk 3: Auth Layer

### Task 4: HMAC verify + timestamp skew

**Files:**
- Create: `services/webhook/auth.py`
- Create: `services/webhook/tests/test_auth.py`

- [ ] **Step 1: Write the failing test**

`services/webhook/tests/test_auth.py`:

```python
import hmac
import hashlib
import time

import pytest

from auth import verify_signature, check_timestamp, AuthError


SECRET = "deadbeef" * 8  # 64 hex chars


def _sign(body: bytes, secret: str) -> str:
    mac = hmac.new(secret.encode(), body, hashlib.sha256).hexdigest()
    return f"sha256={mac}"


def test_verify_signature_valid():
    body = b'{"hello":"world"}'
    sig = _sign(body, SECRET)
    assert verify_signature(body, sig, SECRET) is True


def test_verify_signature_wrong_secret():
    body = b'{"hello":"world"}'
    sig = _sign(body, SECRET)
    assert verify_signature(body, sig, "other-secret") is False


def test_verify_signature_tampered_body():
    body = b'{"hello":"world"}'
    sig = _sign(body, SECRET)
    assert verify_signature(b'{"hello":"WORLD"}', sig, SECRET) is False


def test_verify_signature_malformed_header():
    assert verify_signature(b"x", "no-prefix-here", SECRET) is False
    assert verify_signature(b"x", "", SECRET) is False
    assert verify_signature(b"x", "sha256=", SECRET) is False


def test_check_timestamp_within_window():
    now = int(time.time())
    check_timestamp(str(now), skew=300)  # no exception


def test_check_timestamp_too_old():
    old = int(time.time()) - 600
    with pytest.raises(AuthError):
        check_timestamp(str(old), skew=300)


def test_check_timestamp_too_new():
    future = int(time.time()) + 600
    with pytest.raises(AuthError):
        check_timestamp(str(future), skew=300)


def test_check_timestamp_non_numeric():
    with pytest.raises(AuthError):
        check_timestamp("not-a-number", skew=300)
```

- [ ] **Step 2: Run test — expect FAIL**

```bash
.venv/bin/pytest tests/test_auth.py -v
```

Expected: `ModuleNotFoundError: No module named 'auth'`.

- [ ] **Step 3: Implement `auth.py`**

`services/webhook/auth.py`:

```python
"""HMAC signature verification + timestamp skew check.

Bearer token validation happens at the NPM edge (advanced_config), not here.
This module sees only requests that already passed the bearer check.
"""
from __future__ import annotations

import hmac
import hashlib
import time


class AuthError(Exception):
    """Raised on timestamp skew or auth check failure."""


def verify_signature(body: bytes, header: str, secret: str) -> bool:
    """Return True if `X-Webhook-Signature` matches HMAC-SHA256(body, secret)."""
    if not header or not header.startswith("sha256="):
        return False
    provided = header[len("sha256="):]
    if len(provided) != 64:  # hex of 32-byte digest
        return False
    expected = hmac.new(secret.encode(), body, hashlib.sha256).hexdigest()
    return hmac.compare_digest(provided, expected)


def check_timestamp(header: str, skew: int = 300) -> None:
    """Raise AuthError if `X-Webhook-Timestamp` is non-numeric or skewed > `skew` seconds."""
    try:
        ts = int(header)
    except (TypeError, ValueError):
        raise AuthError("non-numeric timestamp") from None
    now = int(time.time())
    if abs(now - ts) > skew:
        raise AuthError(f"timestamp skew {now - ts}s exceeds ±{skew}s")
```

- [ ] **Step 4: Run tests — expect PASS**

```bash
.venv/bin/pytest tests/test_auth.py -v
```

Expected: 8 passed.

- [ ] **Step 5: Commit**

```bash
git add services/webhook/auth.py services/webhook/tests/test_auth.py
git commit -m "feat(webhook): HMAC signature verify + timestamp skew check"
```

---

## Chunk 4: Paperclip Stub

### Task 5: Flat-file Paperclip client

**Files:**
- Create: `services/webhook/paperclip_client.py`
- Create: `services/webhook/tests/test_paperclip_client.py`

- [ ] **Step 1: Write the failing test**

`services/webhook/tests/test_paperclip_client.py`:

```python
import json
from pathlib import Path

import pytest

from paperclip_client import (
    PaperclipClient,
    PaperclipUnavailable,
    TERMINAL_STATES,
)


@pytest.fixture
def jobs_file(tmp_path: Path) -> Path:
    p = tmp_path / "jobs.json"
    p.write_text(json.dumps({
        "jobs": {
            "job-1": {"secret": "s1" * 32, "state": "RUNNING", "created_at": 1735776000},
            "job-2": {"secret": "s2" * 32, "state": "DONE", "created_at": 1735776000},
        }
    }))
    return p


def test_get_job_secret_known_job(jobs_file):
    c = PaperclipClient(jobs_file)
    assert c.get_job_secret("job-1") == "s1" * 32


def test_get_job_secret_unknown_returns_none(jobs_file):
    c = PaperclipClient(jobs_file)
    assert c.get_job_secret("does-not-exist") is None


def test_get_job_state(jobs_file):
    c = PaperclipClient(jobs_file)
    assert c.get_job_state("job-1") == "RUNNING"
    assert c.get_job_state("nope") is None


def test_transition_first_terminal_wins(jobs_file):
    c = PaperclipClient(jobs_file)
    ok, state = c.transition("job-1", "DONE", {"x": 1})
    assert ok is True and state == "DONE"
    ok2, state2 = c.transition("job-1", "FAILED", {"y": 1})
    assert ok2 is False and state2 == "DONE"


def test_transition_heartbeat_does_not_lock(jobs_file):
    c = PaperclipClient(jobs_file)
    ok, _ = c.transition("job-1", "RUNNING", {"phase": "running"})
    assert ok is True
    # subsequent terminal still allowed because RUNNING is not terminal
    ok2, state2 = c.transition("job-1", "DONE", {})
    assert ok2 is True and state2 == "DONE"


def test_paperclip_unavailable_when_file_missing(tmp_path):
    c = PaperclipClient(tmp_path / "missing.json")
    with pytest.raises(PaperclipUnavailable):
        c.get_job_secret("anything")


def test_paperclip_unavailable_when_file_malformed(tmp_path):
    p = tmp_path / "broken.json"
    p.write_text("{not json")
    c = PaperclipClient(p)
    with pytest.raises(PaperclipUnavailable):
        c.get_job_state("anything")


def test_terminal_states_set():
    assert "DONE" in TERMINAL_STATES
    assert "FAILED" in TERMINAL_STATES
    assert "RUNNING" not in TERMINAL_STATES
```

- [ ] **Step 2: Run test — expect FAIL**

```bash
.venv/bin/pytest tests/test_paperclip_client.py -v
```

Expected: `ModuleNotFoundError`.

- [ ] **Step 3: Implement `paperclip_client.py`**

`services/webhook/paperclip_client.py`:

```python
"""Flat-file Paperclip stub. Read-mostly during Plan 2; writes happen on
state transitions only. Concurrent jobs are NOT supported — `jobs.json` is
race-prone under parallel writes. Sequential job execution is a Plan 2
known limit, lifted when real Paperclip lands. Swap point: this whole file.
"""
from __future__ import annotations

import json
from pathlib import Path
from typing import Optional


TERMINAL_STATES = frozenset({"DONE", "FAILED"})


class PaperclipUnavailable(Exception):
    """Raised when the jobs file is missing or malformed.

    Caller maps this to HTTP 503.
    """


class PaperclipClient:
    def __init__(self, jobs_path: Path):
        self.jobs_path = jobs_path

    def _load(self) -> dict:
        try:
            return json.loads(self.jobs_path.read_text())
        except FileNotFoundError as e:
            raise PaperclipUnavailable(f"jobs file missing: {self.jobs_path}") from e
        except json.JSONDecodeError as e:
            raise PaperclipUnavailable(f"jobs file malformed: {e}") from e

    def _atomic_write(self, data: dict) -> None:
        tmp = self.jobs_path.with_suffix(".tmp")
        tmp.write_text(json.dumps(data, indent=2))
        tmp.replace(self.jobs_path)

    def get_job_secret(self, job_id: str) -> Optional[str]:
        return self._load().get("jobs", {}).get(job_id, {}).get("secret")

    def get_job_state(self, job_id: str) -> Optional[str]:
        return self._load().get("jobs", {}).get(job_id, {}).get("state")

    def transition(self, job_id: str, new_state: str, payload: dict) -> tuple[bool, str]:
        """Return (transitioned, current_state). First-terminal-wins.

        Never raises on terminal-already-set — returns (False, current_state).
        """
        data = self._load()
        job = data.get("jobs", {}).get(job_id)
        if job is None:
            # Transitioning an unknown job — record it as if Paperclip created it.
            # Real Paperclip wouldn't do this, but the stub is permissive for tests.
            data.setdefault("jobs", {})[job_id] = {
                "secret": "",
                "state": new_state,
                "created_at": 0,
                "last_payload": payload,
            }
            self._atomic_write(data)
            return True, new_state

        current = job.get("state", "UNKNOWN")
        if current in TERMINAL_STATES:
            return False, current

        job["state"] = new_state
        job["last_payload"] = payload
        self._atomic_write(data)
        return True, new_state
```

- [ ] **Step 4: Run tests — expect PASS**

```bash
.venv/bin/pytest tests/test_paperclip_client.py -v
```

Expected: 8 passed.

- [ ] **Step 5: Commit**

```bash
git add services/webhook/paperclip_client.py services/webhook/tests/test_paperclip_client.py
git commit -m "feat(webhook): flat-file Paperclip client stub (swap point)"
```

---

## Chunk 5: Pydantic Models

### Task 6: Request body schemas

**Files:**
- Create: `services/webhook/models.py`
- Create: `services/webhook/tests/test_models.py`

- [ ] **Step 1: Write the failing test**

`services/webhook/tests/test_models.py`:

```python
import pytest
from pydantic import ValidationError

from models import CompleteBody, FailedBody, HeartbeatBody, ErrorDetail, HermesResult


def test_complete_minimal_valid():
    b = CompleteBody(job_id="job-1", status="complete", artifact="/w/build.apk",
                     duration_s=10, retry_count=0, gap_count=0)
    assert b.status == "complete"
    assert b.logs_tail is None
    assert b.hermes_result is None


def test_complete_full_valid():
    b = CompleteBody(
        job_id="job-1", status="complete", artifact="/w/build.apk",
        duration_s=10, retry_count=0, gap_count=0,
        logs_tail=["line1", "line2"],
        hermes_result=HermesResult(passed=True, endpoints_green=12, endpoints_total=12),
    )
    assert b.hermes_result.passed is True


def test_complete_status_must_be_complete():
    with pytest.raises(ValidationError):
        CompleteBody(job_id="x", status="failed", artifact="/w",
                     duration_s=1, retry_count=0, gap_count=0)


def test_complete_logs_tail_too_many_entries():
    with pytest.raises(ValidationError):
        CompleteBody(job_id="x", status="complete", artifact="/w",
                     duration_s=1, retry_count=0, gap_count=0,
                     logs_tail=["x"] * 51)  # cap is 50


def test_complete_logs_tail_entry_too_long():
    with pytest.raises(ValidationError):
        CompleteBody(job_id="x", status="complete", artifact="/w",
                     duration_s=1, retry_count=0, gap_count=0,
                     logs_tail=["x" * 501])  # cap is 500 chars


def test_failed_requires_error_block():
    b = FailedBody(
        job_id="job-1", status="failed", duration_s=10,
        retry_count=0, gap_count=1,
        error=ErrorDetail(phase="hermes", code="black_screen", message="..."),
    )
    assert b.error.phase == "hermes"


def test_failed_status_must_be_failed():
    with pytest.raises(ValidationError):
        FailedBody(job_id="x", status="complete", duration_s=1,
                   retry_count=0, gap_count=0,
                   error=ErrorDetail(phase="x", code="x", message="x"))


def test_heartbeat_minimal():
    b = HeartbeatBody(job_id="job-1", phase="running", elapsed_s=312)
    assert b.elapsed_s == 312


def test_heartbeat_phase_invalid():
    with pytest.raises(ValidationError):
        HeartbeatBody(job_id="x", phase="zooming", elapsed_s=1)
```

- [ ] **Step 2: Run test — expect FAIL**

```bash
.venv/bin/pytest tests/test_models.py -v
```

- [ ] **Step 3: Implement `models.py`**

`services/webhook/models.py`:

```python
"""Pydantic v2 request body schemas. All bodies validated by FastAPI before
the handler runs. Caps on `logs_tail` enforced here so the body cap (1MB at
ingress) is never the front-line guard."""
from __future__ import annotations

from typing import Literal, Optional

from pydantic import BaseModel, Field, field_validator


MAX_LOGS_TAIL_ENTRIES = 50
MAX_LOGS_TAIL_ENTRY_CHARS = 500


class HermesResult(BaseModel):
    passed: bool
    endpoints_green: int = Field(ge=0)
    endpoints_total: int = Field(ge=0)


class ErrorDetail(BaseModel):
    phase: str
    code: str
    message: str


class _BaseBody(BaseModel):
    job_id: str = Field(min_length=1, max_length=128)


def _validate_logs_tail(v: Optional[list[str]]) -> Optional[list[str]]:
    if v is None:
        return None
    if len(v) > MAX_LOGS_TAIL_ENTRIES:
        raise ValueError(f"logs_tail too long: {len(v)} > {MAX_LOGS_TAIL_ENTRIES}")
    for i, entry in enumerate(v):
        if len(entry) > MAX_LOGS_TAIL_ENTRY_CHARS:
            raise ValueError(
                f"logs_tail[{i}] too long: {len(entry)} > {MAX_LOGS_TAIL_ENTRY_CHARS}"
            )
    return v


class CompleteBody(_BaseBody):
    status: Literal["complete"]
    artifact: str
    duration_s: int = Field(ge=0)
    retry_count: int = Field(ge=0, le=10)
    gap_count: int = Field(ge=0)
    logs_tail: Optional[list[str]] = None
    hermes_result: Optional[HermesResult] = None

    @field_validator("logs_tail")
    @classmethod
    def _check_logs_tail(cls, v): return _validate_logs_tail(v)


class FailedBody(_BaseBody):
    status: Literal["failed"]
    duration_s: int = Field(ge=0)
    retry_count: int = Field(ge=0, le=10)
    gap_count: int = Field(ge=0)
    error: ErrorDetail
    logs_tail: Optional[list[str]] = None

    @field_validator("logs_tail")
    @classmethod
    def _check_logs_tail(cls, v): return _validate_logs_tail(v)


class HeartbeatBody(_BaseBody):
    phase: Literal["running", "verifying"]
    elapsed_s: int = Field(ge=0)
```

- [ ] **Step 4: Run tests — expect PASS**

```bash
.venv/bin/pytest tests/test_models.py -v
```

Expected: 9 passed.

- [ ] **Step 5: Commit**

```bash
git add services/webhook/models.py services/webhook/tests/test_models.py
git commit -m "feat(webhook): pydantic body schemas with logs_tail caps"
```

---

## Chunk 6: FastAPI App + Endpoints

### Task 7: App wiring + signed_post test helper

**Files:**
- Create: `services/webhook/app.py`
- Modify: `services/webhook/tests/conftest.py` (add fixtures)

- [ ] **Step 1: Extend conftest with app/client/signed_post fixtures**

Replace `services/webhook/tests/conftest.py` with:

```python
import hmac
import hashlib
import json
import time
import uuid
from pathlib import Path

import pytest
from fastapi.testclient import TestClient


@pytest.fixture
def tmp_db(tmp_path: Path) -> Path:
    return tmp_path / "webhook.db"


@pytest.fixture
def tmp_job_log(tmp_path: Path) -> Path:
    return tmp_path / "job-log.jsonl"


@pytest.fixture
def tmp_jobs_file(tmp_path: Path) -> Path:
    p = tmp_path / "jobs.json"
    p.write_text(json.dumps({
        "jobs": {
            "job-test": {"secret": "a" * 64, "state": "RUNNING", "created_at": 1735776000},
        }
    }))
    return p


@pytest.fixture
def app_env(monkeypatch, tmp_db, tmp_jobs_file, tmp_job_log):
    monkeypatch.setenv("WEBHOOK_DB_PATH", str(tmp_db))
    monkeypatch.setenv("PAPERCLIP_DB_PATH", str(tmp_jobs_file))
    monkeypatch.setenv("JOB_LOG_PATH", str(tmp_job_log))


@pytest.fixture
def client(app_env):
    # Imported lazily so config picks up the monkeypatched env.
    import importlib
    import config as cfg_mod
    importlib.reload(cfg_mod)
    import app as app_mod
    importlib.reload(app_mod)
    return TestClient(app_mod.app)


@pytest.fixture
def signed_post(client):
    """POST helper that signs the body with the per-job secret."""
    def _post(path: str, body: dict, secret: str = "a" * 64,
              ts: int | None = None, idem: str | None = None,
              extra_headers: dict | None = None):
        raw = json.dumps(body).encode()
        ts = ts or int(time.time())
        sig = "sha256=" + hmac.new(secret.encode(), raw, hashlib.sha256).hexdigest()
        headers = {
            "Content-Type": "application/json",
            "X-Webhook-Signature": sig,
            "X-Webhook-Timestamp": str(ts),
            "Idempotency-Key": idem or str(uuid.uuid4()),
        }
        if extra_headers:
            headers.update(extra_headers)
        return client.post(path, content=raw, headers=headers)
    return _post
```

- [ ] **Step 2: Implement `app.py`**

`services/webhook/app.py`:

```python
"""FastAPI webhook listener.

Single-worker uvicorn (`--workers 1`). Routes:
  POST /jobs/{job_id}/complete
  POST /jobs/{job_id}/failed
  POST /jobs/{job_id}/heartbeat
  GET  /healthz

Auth: HMAC-SHA256 over raw body, key = per-job secret looked up via
PaperclipClient. Bearer token check happens at NPM edge, not here.
"""
from __future__ import annotations

import json
import time
from datetime import datetime, timezone

from fastapi import FastAPI, HTTPException, Request, Response
from pydantic import ValidationError

import config as cfg
from auth import AuthError, check_timestamp, verify_signature
from models import CompleteBody, FailedBody, HeartbeatBody
from paperclip_client import PaperclipClient, PaperclipUnavailable, TERMINAL_STATES
from store import Store


app = FastAPI(title="pipeline-webhook", version="0.1.0")

_store = Store(cfg.WEBHOOK_DB_PATH)
_store.init_schema()
_paperclip = PaperclipClient(cfg.PAPERCLIP_DB_PATH)


def _log_event(event: str, **fields) -> None:
    cfg.JOB_LOG_PATH.parent.mkdir(parents=True, exist_ok=True)
    line = json.dumps({
        "event": event,
        "ts": datetime.now(timezone.utc).isoformat(),
        **fields,
    }) + "\n"
    with cfg.JOB_LOG_PATH.open("a") as f:
        f.write(line)


@app.get("/healthz")
def healthz():
    return {"webhook": "up"}


async def _read_and_cap(request: Request) -> bytes:
    body = await request.body()
    if len(body) > cfg.MAX_BODY_BYTES:
        raise HTTPException(status_code=413, detail="body too large")
    return body


def _common_auth(request: Request, body: bytes, job_id: str) -> str:
    """Run HMAC + timestamp checks. Returns the per-job secret on success."""
    sig = request.headers.get("X-Webhook-Signature", "")
    ts_header = request.headers.get("X-Webhook-Timestamp", "")
    idem = request.headers.get("Idempotency-Key", "")
    if not idem:
        raise HTTPException(status_code=400, detail="missing Idempotency-Key")

    try:
        secret = _paperclip.get_job_secret(job_id)
    except PaperclipUnavailable as e:
        _log_event("WEBHOOK_PAPERCLIP_UNAVAILABLE", job_id=job_id, error=str(e))
        raise HTTPException(status_code=503, detail="paperclip unavailable") from None

    if not secret:
        _store.bump_counter("rejected_auth")
        _log_event("WEBHOOK_REJECTED_AUTH", job_id=job_id, reason="unknown_job")
        raise HTTPException(status_code=403, detail="unknown job")

    try:
        check_timestamp(ts_header, skew=cfg.TIMESTAMP_SKEW_SECONDS)
    except AuthError:
        _log_event("WEBHOOK_REJECTED_SKEW", job_id=job_id)
        raise HTTPException(status_code=410, detail="timestamp skew") from None

    if not verify_signature(body, sig, secret):
        _store.bump_counter("rejected_auth")
        _log_event("WEBHOOK_REJECTED_AUTH", job_id=job_id, reason="bad_hmac")
        raise HTTPException(status_code=403, detail="bad signature")

    return secret


def _terminal_handler(
    request: Request,
    job_id: str,
    body: bytes,
    endpoint: str,
    new_state: str,
    parsed: CompleteBody | FailedBody,
) -> Response:
    idem = request.headers.get("Idempotency-Key", "")

    # Look up cached response BEFORE inserting our own placeholder.
    existing = _store._conn.execute(
        "SELECT response_status, response_body FROM idempotency_keys WHERE key = ?",
        (idem,),
    ).fetchone()
    if existing is not None:
        _store.bump_counter("rejected_replay")
        _log_event("WEBHOOK_REPLAY", job_id=job_id, endpoint=endpoint, idem=idem)
        return Response(
            content=json.dumps({"status": "already_recorded"}),
            status_code=existing[0],
            media_type="application/json",
        )

    transitioned, current_state = _paperclip.transition(
        job_id, new_state, parsed.model_dump()
    )

    if not transitioned:
        # Late terminal: state already in TERMINAL_STATES.
        _log_event(
            "WEBHOOK_LATE_TERMINAL", job_id=job_id, endpoint=endpoint,
            current_state=current_state, attempted_state=new_state,
        )
        resp_body = {"status": "late_terminal", "current_state": current_state}
        _store.dedup_or_record(idem, job_id, endpoint, 409, json.dumps(resp_body))
        return Response(content=json.dumps(resp_body), status_code=409,
                        media_type="application/json")

    _store.bump_counter("received")
    _log_event(
        "WEBHOOK_RECEIVED", job_id=job_id, endpoint=endpoint,
        duration_s=getattr(parsed, "duration_s", None),
        retry_count=getattr(parsed, "retry_count", None),
        idem=idem,
    )
    resp_body = {"status": "ok", "state": current_state}
    _store.dedup_or_record(idem, job_id, endpoint, 200, json.dumps(resp_body))
    return Response(content=json.dumps(resp_body), status_code=200,
                    media_type="application/json")


@app.post("/jobs/{job_id}/complete")
async def post_complete(job_id: str, request: Request) -> Response:
    body = await _read_and_cap(request)
    _common_auth(request, body, job_id)
    try:
        parsed = CompleteBody.model_validate_json(body)
    except ValidationError as e:
        raise HTTPException(status_code=400, detail=e.errors()) from None
    if parsed.job_id != job_id:
        raise HTTPException(status_code=400, detail="job_id mismatch")
    return _terminal_handler(request, job_id, body, "complete", "DONE", parsed)


@app.post("/jobs/{job_id}/failed")
async def post_failed(job_id: str, request: Request) -> Response:
    body = await _read_and_cap(request)
    _common_auth(request, body, job_id)
    try:
        parsed = FailedBody.model_validate_json(body)
    except ValidationError as e:
        raise HTTPException(status_code=400, detail=e.errors()) from None
    if parsed.job_id != job_id:
        raise HTTPException(status_code=400, detail="job_id mismatch")
    return _terminal_handler(request, job_id, body, "failed", "FAILED", parsed)


@app.post("/jobs/{job_id}/heartbeat")
async def post_heartbeat(job_id: str, request: Request) -> Response:
    body = await _read_and_cap(request)
    _common_auth(request, body, job_id)
    try:
        parsed = HeartbeatBody.model_validate_json(body)
    except ValidationError as e:
        raise HTTPException(status_code=400, detail=e.errors()) from None
    if parsed.job_id != job_id:
        raise HTTPException(status_code=400, detail="job_id mismatch")

    idem = request.headers.get("Idempotency-Key", "")
    existing = _store._conn.execute(
        "SELECT response_status, response_body FROM idempotency_keys WHERE key = ?",
        (idem,),
    ).fetchone()
    if existing is not None:
        _store.bump_counter("rejected_replay")
        _log_event("WEBHOOK_REPLAY", job_id=job_id, endpoint="heartbeat", idem=idem)
        return Response(content=json.dumps({"status": "already_recorded"}),
                        status_code=existing[0], media_type="application/json")

    state = _paperclip.get_job_state(job_id)
    if state in TERMINAL_STATES:
        _log_event("WEBHOOK_LATE_TERMINAL", job_id=job_id, endpoint="heartbeat",
                   current_state=state)
        resp_body = {"status": "late_heartbeat", "current_state": state}
        _store.dedup_or_record(idem, job_id, "heartbeat", 409, json.dumps(resp_body))
        return Response(content=json.dumps(resp_body), status_code=409,
                        media_type="application/json")

    _store.bump_counter("received")
    _log_event("WEBHOOK_HEARTBEAT", job_id=job_id, elapsed_s=parsed.elapsed_s, idem=idem)
    resp_body = {"status": "ok"}
    _store.dedup_or_record(idem, job_id, "heartbeat", 200, json.dumps(resp_body))
    return Response(content=json.dumps(resp_body), status_code=200,
                    media_type="application/json")
```

- [ ] **Step 3: Smoke-import the app**

```bash
cd ~/projects/30_OpenSandboxPipeline/services/webhook
.venv/bin/python -c "from app import app; print(app.title, app.version)"
```

Expected: `pipeline-webhook 0.1.0`

- [ ] **Step 4: Commit**

```bash
git add services/webhook/app.py services/webhook/tests/conftest.py
git commit -m "feat(webhook): FastAPI app with three endpoints + healthz"
```

### Task 8: Endpoint integration tests

**Files:**
- Create: `services/webhook/tests/test_endpoints.py`

- [ ] **Step 1: Write the integration tests**

`services/webhook/tests/test_endpoints.py`:

```python
import json
import time
import uuid


def test_healthz_unauthenticated(client):
    r = client.get("/healthz")
    assert r.status_code == 200
    assert r.json() == {"webhook": "up"}


def test_complete_happy_path(signed_post):
    body = {
        "job_id": "job-test", "status": "complete", "artifact": "/w/x.apk",
        "duration_s": 100, "retry_count": 0, "gap_count": 0,
    }
    r = signed_post("/jobs/job-test/complete", body)
    assert r.status_code == 200
    assert r.json()["status"] == "ok"


def test_complete_replay_returns_already_recorded(signed_post):
    body = {
        "job_id": "job-test", "status": "complete", "artifact": "/w/x.apk",
        "duration_s": 100, "retry_count": 0, "gap_count": 0,
    }
    idem = str(uuid.uuid4())
    r1 = signed_post("/jobs/job-test/complete", body, idem=idem)
    r2 = signed_post("/jobs/job-test/complete", body, idem=idem)
    assert r1.status_code == 200
    assert r2.status_code == 200
    assert r2.json()["status"] == "already_recorded"


def test_bad_hmac_returns_403(signed_post, client):
    body = {
        "job_id": "job-test", "status": "complete", "artifact": "/w/x.apk",
        "duration_s": 100, "retry_count": 0, "gap_count": 0,
    }
    r = signed_post("/jobs/job-test/complete", body, secret="wrong" * 16)
    assert r.status_code == 403


def test_skewed_timestamp_returns_410(signed_post):
    body = {
        "job_id": "job-test", "status": "complete", "artifact": "/w/x.apk",
        "duration_s": 100, "retry_count": 0, "gap_count": 0,
    }
    r = signed_post("/jobs/job-test/complete", body, ts=int(time.time()) - 600)
    assert r.status_code == 410


def test_oversize_body_returns_413(client):
    big = "x" * (1024 * 1024 + 1)
    r = client.post(
        "/jobs/job-test/complete",
        content=big,
        headers={
            "Content-Type": "application/json",
            "X-Webhook-Signature": "sha256=" + "0" * 64,
            "X-Webhook-Timestamp": str(int(time.time())),
            "Idempotency-Key": str(uuid.uuid4()),
        },
    )
    assert r.status_code == 413


def test_unknown_job_returns_403(signed_post):
    body = {
        "job_id": "ghost", "status": "complete", "artifact": "/w",
        "duration_s": 1, "retry_count": 0, "gap_count": 0,
    }
    r = signed_post("/jobs/ghost/complete", body)
    assert r.status_code == 403


def test_paperclip_missing_returns_503(monkeypatch, client, tmp_path):
    monkeypatch.setenv("PAPERCLIP_DB_PATH", str(tmp_path / "missing.json"))
    import importlib, config, app as app_mod
    importlib.reload(config); importlib.reload(app_mod)
    from fastapi.testclient import TestClient
    c = TestClient(app_mod.app)

    r = c.post(
        "/jobs/job-test/complete",
        content=b"{}",
        headers={
            "Content-Type": "application/json",
            "X-Webhook-Signature": "sha256=" + "0" * 64,
            "X-Webhook-Timestamp": str(int(time.time())),
            "Idempotency-Key": str(uuid.uuid4()),
        },
    )
    assert r.status_code == 503


def test_late_terminal_after_complete_returns_409(signed_post, tmp_jobs_file):
    body = {
        "job_id": "job-test", "status": "complete", "artifact": "/w",
        "duration_s": 1, "retry_count": 0, "gap_count": 0,
    }
    r1 = signed_post("/jobs/job-test/complete", body)
    assert r1.status_code == 200

    failed_body = {
        "job_id": "job-test", "status": "failed", "duration_s": 1,
        "retry_count": 0, "gap_count": 0,
        "error": {"phase": "x", "code": "x", "message": "x"},
    }
    r2 = signed_post("/jobs/job-test/failed", failed_body)
    assert r2.status_code == 409
    assert r2.json()["status"] == "late_terminal"


def test_heartbeat_happy_path(signed_post):
    r = signed_post("/jobs/job-test/heartbeat",
                    {"job_id": "job-test", "phase": "running", "elapsed_s": 60})
    assert r.status_code == 200


def test_path_job_id_must_match_body(signed_post):
    body = {
        "job_id": "job-X", "status": "complete", "artifact": "/w",
        "duration_s": 1, "retry_count": 0, "gap_count": 0,
    }
    r = signed_post("/jobs/job-test/complete", body)
    assert r.status_code == 400


def test_job_log_appended(signed_post, tmp_job_log):
    body = {
        "job_id": "job-test", "status": "complete", "artifact": "/w",
        "duration_s": 1, "retry_count": 0, "gap_count": 0,
    }
    signed_post("/jobs/job-test/complete", body)
    assert tmp_job_log.exists()
    lines = [json.loads(l) for l in tmp_job_log.read_text().splitlines()]
    assert any(l["event"] == "WEBHOOK_RECEIVED" for l in lines)
```

- [ ] **Step 2: Run all tests**

```bash
cd ~/projects/30_OpenSandboxPipeline/services/webhook
.venv/bin/pytest -v
```

Expected: all tests pass (store + auth + paperclip + models + endpoints).

- [ ] **Step 3: Coverage check**

```bash
.venv/bin/pip install coverage
.venv/bin/coverage run -m pytest
.venv/bin/coverage report --include="auth.py,store.py" --fail-under=90
```

Expected: ≥90% on `auth.py` and `store.py`.

- [ ] **Step 4: Commit**

```bash
cd ~/projects/30_OpenSandboxPipeline
git add services/webhook/tests/test_endpoints.py
git commit -m "test(webhook): endpoint integration suite (12 cases)"
```

---

## Chunk 7: Local Service (launchd + log rotation)

### Task 9: Launchd plist

**Files:**
- Create: `infra/com.gtxs.pipeline-webhook.plist`
- Create: `infra/pipeline-webhook.newsyslog.conf`
- Create: `scripts/install-webhook-launchd.sh`

- [ ] **Step 1: Write the launchd plist**

`infra/com.gtxs.pipeline-webhook.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.gtxs.pipeline-webhook</string>
  <key>ProgramArguments</key>
  <array>
    <string>/Users/jcords-macmini/projects/30_OpenSandboxPipeline/services/webhook/.venv/bin/uvicorn</string>
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
  <key>EnvironmentVariables</key>
  <dict>
    <key>WEBHOOK_PROJECT_ROOT</key>
    <string>/Users/jcords-macmini/projects/30_OpenSandboxPipeline</string>
    <key>PATH</key>
    <string>/Users/jcords-macmini/projects/30_OpenSandboxPipeline/services/webhook/.venv/bin:/usr/bin:/bin</string>
  </dict>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>ThrottleInterval</key><integer>10</integer>
  <key>StandardOutPath</key>
  <string>/Users/jcords-macmini/Library/Logs/pipeline-webhook.out.log</string>
  <key>StandardErrorPath</key>
  <string>/Users/jcords-macmini/Library/Logs/pipeline-webhook.err.log</string>
</dict>
</plist>
```

- [ ] **Step 2: Write newsyslog rotation config**

`infra/pipeline-webhook.newsyslog.conf`:

```
# logfilename                                                        [owner:group]    mode count size when  flags [/pid_file] [sig_num]
/Users/jcords-macmini/Library/Logs/pipeline-webhook.out.log         jcords-macmini:staff 644  7     10240 *    GZ
/Users/jcords-macmini/Library/Logs/pipeline-webhook.err.log         jcords-macmini:staff 644  7     10240 *    GZ
```

- [ ] **Step 3: Write the install script**

`scripts/install-webhook-launchd.sh`:

```bash
#!/usr/bin/env bash
# Idempotent: re-running this script reloads the launchd unit and reinstalls
# the newsyslog rotation. Safe to run on every deploy.
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLIST_SRC="$PROJECT_ROOT/infra/com.gtxs.pipeline-webhook.plist"
PLIST_DEST="$HOME/Library/LaunchAgents/com.gtxs.pipeline-webhook.plist"
LABEL="com.gtxs.pipeline-webhook"

NEWSYSLOG_SRC="$PROJECT_ROOT/infra/pipeline-webhook.newsyslog.conf"
NEWSYSLOG_DEST="/etc/newsyslog.d/pipeline-webhook.conf"

echo "[1/4] Installing launchd plist -> $PLIST_DEST"
mkdir -p "$(dirname "$PLIST_DEST")"
cp "$PLIST_SRC" "$PLIST_DEST"

echo "[2/4] Reloading launchd unit"
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST_DEST"
launchctl enable "gui/$(id -u)/$LABEL"

echo "[3/4] Installing newsyslog rotation -> $NEWSYSLOG_DEST (sudo)"
sudo cp "$NEWSYSLOG_SRC" "$NEWSYSLOG_DEST"
sudo chmod 644 "$NEWSYSLOG_DEST"

echo "[4/4] Verifying service is up on 127.0.0.1:9090"
sleep 2
curl -fsS http://127.0.0.1:9090/healthz || {
  echo "FAIL: webhook not responding on :9090"
  echo "tail of err log:"
  tail -20 ~/Library/Logs/pipeline-webhook.err.log || true
  exit 1
}
echo "OK: webhook responding"
```

- [ ] **Step 4: Make executable + run**

```bash
cd ~/projects/30_OpenSandboxPipeline
chmod +x scripts/install-webhook-launchd.sh
mkdir -p var
# Seed jobs.json with the test job for manual smoke
cat > var/jobs.json <<'EOF'
{
  "jobs": {
    "smoke-job": {
      "secret": "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
      "state": "RUNNING",
      "created_at": 1735776000
    }
  }
}
EOF
./scripts/install-webhook-launchd.sh
```

Expected last line: `OK: webhook responding`

- [ ] **Step 5: Verify launchd state**

```bash
launchctl print "gui/$(id -u)/com.gtxs.pipeline-webhook" | head -20
```

Expected: `state = running` and the path/args you set.

- [ ] **Step 6: Commit**

```bash
git add infra/com.gtxs.pipeline-webhook.plist infra/pipeline-webhook.newsyslog.conf \
        scripts/install-webhook-launchd.sh
git commit -m "feat(webhook): launchd unit + newsyslog rotation + install script"
```

---

## Chunk 8: Public Ingress (NPM Proxy Host)

### Task 10: Generate WEBHOOK_BEARER

**Files:**
- Modify: `infra/.env` (gitignored — your local secrets file from Plan 1)

- [ ] **Step 1: Generate and store the static bearer token**

```bash
cd ~/projects/30_OpenSandboxPipeline
TOK="$(openssl rand -hex 32)"
echo "WEBHOOK_BEARER=$TOK" >> infra/.env
echo "Stored. First 8 chars: ${TOK:0:8}..."
```

Note: do **not** commit `infra/.env` — it's gitignored from Plan 1.

### Task 11: NPM proxy host deploy script

**Files:**
- Create: `scripts/deploy-webhook-npm.sh`

- [ ] **Step 1: Verify DNS A record exists**

```bash
dig +short webhook.getaccess.cloud
```

Expected: `72.61.159.117` (or whatever the VPS IP is).
If empty: add the A record at the registrar and wait 5min before continuing.

- [ ] **Step 2: Write the deploy script**

`scripts/deploy-webhook-npm.sh`:

```bash
#!/usr/bin/env bash
# Idempotent: creates the proxy host on first run, updates on subsequent runs.
# Mirrors the Plan 1 NPM REST API pattern (verified path; do not edit
# /etc/nginx/* on the VPS — host nginx is a decoy).
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck disable=SC1091
source "$PROJECT_ROOT/infra/.env"

: "${NPM_EMAIL:?NPM_EMAIL not set in infra/.env}"
: "${NPM_PASSWORD:?NPM_PASSWORD not set in infra/.env}"
: "${WEBHOOK_BEARER:?WEBHOOK_BEARER not set in infra/.env}"

VPS_HOST="${VPS_HOST:-root@72.61.159.117}"
DOMAIN="webhook.getaccess.cloud"
FORWARD_HOST="127.0.0.1"
FORWARD_PORT="9090"

echo "[1/5] Logging in to NPM"
TOKEN="$(ssh "$VPS_HOST" "curl -sS -X POST http://127.0.0.1:81/api/tokens \
  -H 'Content-Type: application/json' \
  -d '{\"identity\":\"$NPM_EMAIL\",\"secret\":\"$NPM_PASSWORD\"}'" \
  | python3 -c 'import sys,json; print(json.load(sys.stdin)["token"])')"

echo "[2/5] Looking up existing proxy host for $DOMAIN"
HOST_ID="$(ssh "$VPS_HOST" "curl -sS http://127.0.0.1:81/api/nginx/proxy-hosts \
  -H 'Authorization: Bearer $TOKEN'" \
  | python3 -c "
import sys, json
hosts = json.load(sys.stdin)
for h in hosts:
    if '$DOMAIN' in h.get('domain_names', []):
        print(h['id']); sys.exit(0)
")"

# advanced_config: exempt /healthz from bearer, then enforce on all other paths.
# Use heredoc encoded as JSON string via python to avoid shell quoting hell.
ADV_CONFIG_JSON="$(python3 -c "
import json
adv = '''
client_max_body_size 1m;
location = /healthz {
  proxy_pass http://${FORWARD_HOST}:${FORWARD_PORT};
}
location = /stats {
  proxy_pass http://${FORWARD_HOST}:${FORWARD_PORT};
}
if (\$http_authorization != \"Bearer ${WEBHOOK_BEARER}\") { return 401; }
'''
print(json.dumps(adv))
")"

PAYLOAD="$(python3 -c "
import json
print(json.dumps({
    'domain_names': ['$DOMAIN'],
    'forward_scheme': 'http',
    'forward_host': '$FORWARD_HOST',
    'forward_port': $FORWARD_PORT,
    'allow_websocket_upgrade': False,
    'caching_enabled': False,
    'block_exploits': True,
    'http2_support': True,
    'hsts_enabled': True,
    'hsts_subdomains': False,
    'ssl_forced': True,
    'meta': {'letsencrypt_agree': True, 'dns_challenge': False},
    'certificate_id': 'new',
    'advanced_config': $ADV_CONFIG_JSON,
}))")"

if [ -z "$HOST_ID" ]; then
  echo "[3/5] Creating new proxy host"
  RESP="$(ssh "$VPS_HOST" "curl -sS -X POST http://127.0.0.1:81/api/nginx/proxy-hosts \
    -H 'Authorization: Bearer $TOKEN' \
    -H 'Content-Type: application/json' \
    -d '$PAYLOAD'")"
  HOST_ID="$(echo "$RESP" | python3 -c 'import sys,json; print(json.load(sys.stdin)["id"])')"
  echo "  Created host id=$HOST_ID"
else
  echo "[3/5] Updating existing proxy host id=$HOST_ID"
  ssh "$VPS_HOST" "curl -sS -X PUT http://127.0.0.1:81/api/nginx/proxy-hosts/$HOST_ID \
    -H 'Authorization: Bearer $TOKEN' \
    -H 'Content-Type: application/json' \
    -d '$PAYLOAD'" > /dev/null
fi

echo "[4/5] Setting client_max_body_size on this proxy host"
# NPM also accepts client_max_body_size via advanced_config; merge it in.
# (No separate API field; advanced_config above is the right place. Append.)

echo "[5/5] Verifying public reachability"
sleep 5  # give NPM time to reload nginx
curl -fsS "https://$DOMAIN/healthz" || {
  echo "FAIL: $DOMAIN/healthz not reachable"
  exit 1
}
echo "OK: https://$DOMAIN/healthz responding"
echo "Host ID: $HOST_ID — record this in HANDOVER.md"
```

- [ ] **Step 2: Make executable + run**

```bash
chmod +x scripts/deploy-webhook-npm.sh
./scripts/deploy-webhook-npm.sh
```

Expected: `OK: https://webhook.getaccess.cloud/healthz responding`. The script also prints the Host ID — record it.

- [ ] **Step 3: Commit**

```bash
git add scripts/deploy-webhook-npm.sh
git commit -m "feat(webhook): NPM proxy host deploy via REST API (idempotent)"
```

---

## Chunk 9: pipeline-health Integration

The webhook DB lives on the **Mac Mini**, not the VPS. So the VPS `pipeline-health.service` cannot read SQLite directly. We expose stats through a new local-only `GET /stats` endpoint on the webhook app, and have the VPS health endpoint curl it through the existing autossh tunnel (`VPS:9090 → Mac:9090`).

### Task 12: Add `/stats` to the webhook app

**Files:**
- Modify: `services/webhook/app.py`
- Modify: `services/webhook/tests/test_endpoints.py`

- [ ] **Step 1: Write the failing test**

Append to `services/webhook/tests/test_endpoints.py`:

```python
def test_stats_endpoint_unauthenticated(signed_post, client):
    body = {
        "job_id": "job-test", "status": "complete", "artifact": "/w",
        "duration_s": 1, "retry_count": 0, "gap_count": 0,
    }
    signed_post("/jobs/job-test/complete", body)
    r = client.get("/stats")
    assert r.status_code == 200
    j = r.json()
    assert j["received_24h"] >= 1
    assert j["last_seen"] is not None
```

Run: `pytest tests/test_endpoints.py::test_stats_endpoint_unauthenticated -v`. Expected FAIL: `404`.

- [ ] **Step 2: Add `/stats` to `services/webhook/app.py`**

Append after `healthz()`:

```python
@app.get("/stats")
def stats():
    return {
        "received_24h": _store.received_24h(),
        "last_seen": _store.last_seen_iso(),
    }
```

Run the test again. Expected PASS.

- [ ] **Step 3: Commit**

```bash
cd ~/projects/30_OpenSandboxPipeline
git add services/webhook/app.py services/webhook/tests/test_endpoints.py
git commit -m "feat(webhook): expose /stats for pipeline-health aggregation"
```

### Task 13: Extend VPS `/pipeline/health` with webhook fields

**Files:**
- Modify: `infra/health_endpoint.py`
- Modify: `tests/test_health_endpoint.py`

- [ ] **Step 1: Update the test first**

Read current `tests/test_health_endpoint.py` (existing Plan 1 test file), then add:

```python
def test_health_includes_webhook_fields(monkeypatch):
    monkeypatch.setattr("infra.health_endpoint._check_component", lambda url: "up")
    monkeypatch.setattr(
        "infra.health_endpoint._webhook_stats",
        lambda: (3, "2026-04-28T22:14:08+00:00"),
    )
    from fastapi.testclient import TestClient
    from infra.health_endpoint import app
    r = TestClient(app).get("/health")
    j = r.json()
    assert j["webhook"] == "up"
    assert j["webhook_received_24h"] == 3
    assert j["webhook_last_seen"] == "2026-04-28T22:14:08+00:00"
```

(Adapt to the fixture style already in the file.)

- [ ] **Step 2: Run new test — expect FAIL**

```bash
cd ~/projects/30_OpenSandboxPipeline
python -m pytest tests/test_health_endpoint.py::test_health_includes_webhook_fields -v
```

Expected: `AttributeError` (no `_webhook_stats`) or `KeyError: 'webhook'`.

- [ ] **Step 3: Modify `infra/health_endpoint.py`**

Add module-level constant after the existing URL constants:

```python
WEBHOOK_HEALTHZ_URL = os.getenv("WEBHOOK_HEALTHZ", "http://127.0.0.1:9090/healthz")
WEBHOOK_STATS_URL = os.getenv("WEBHOOK_STATS", "http://127.0.0.1:9090/stats")
```

Add helper after `_check_component`:

```python
def _webhook_stats() -> tuple[int, str | None]:
    """Fetch 24h count and last-seen from the webhook /stats endpoint via tunnel.

    Returns (0, None) on any error — the webhook field on /health still reflects
    liveness independently via _check_component(WEBHOOK_HEALTHZ_URL).
    """
    try:
        r = requests.get(WEBHOOK_STATS_URL, timeout=2)
        if r.status_code != 200:
            return 0, None
        j = r.json()
        return int(j.get("received_24h", 0)), j.get("last_seen")
    except (requests.RequestException, ValueError):
        return 0, None
```

Replace `health()`:

```python
@app.get("/health")
def health():
    received_24h, last_seen = _webhook_stats()
    return {
        "opensandbox": _check_component(OPENSANDBOX_URL),
        "hermes": _check_component(HERMES_URL),
        "paperclip": _check_component(PAPERCLIP_URL),
        "webhook": _check_component(WEBHOOK_HEALTHZ_URL),
        "active_jobs": 0,
        "webhook_received_24h": received_24h,
        "webhook_last_seen": last_seen,
    }
```

- [ ] **Step 4: Run test — expect PASS**

```bash
python -m pytest tests/test_health_endpoint.py -v
```

- [ ] **Step 5: Push to VPS**

Use the existing Plan-1 deploy script if present:

```bash
./scripts/deploy-vps.sh
```

If `deploy-vps.sh` doesn't exist or doesn't cover this file:

```bash
rsync -avz infra/health_endpoint.py "$VPS_HOST:/opt/pipeline-health/health_endpoint.py"
ssh "$VPS_HOST" "systemctl restart pipeline-health.service && \
  systemctl status pipeline-health.service --no-pager | head -10"
```

The VPS reaches `127.0.0.1:9090/stats` through the existing autossh `-R` from Plan 1 — no new tunnel needed.

- [ ] **Step 6: Verify aggregated health**

```bash
curl -sS https://paperclip.getaccess.cloud/pipeline/health | python3 -m json.tool
```

Expected: includes `"webhook":"up"`, `webhook_received_24h`, `webhook_last_seen`.

- [ ] **Step 7: Kickstart local webhook to make sure /stats is live, then commit**

```bash
launchctl kickstart -k "gui/$(id -u)/com.gtxs.pipeline-webhook"
sleep 2
curl -fsS http://127.0.0.1:9090/stats

cd ~/projects/30_OpenSandboxPipeline
git add infra/health_endpoint.py tests/test_health_endpoint.py
git commit -m "feat(pipeline-health): aggregate webhook stats via /stats fetch"
```

---

## Chunk 10: End-to-end Smoke

### Task 14: Smoke script + final verification

**Files:**
- Create: `scripts/smoke-webhook.sh`

- [ ] **Step 1: Write the smoke script**

`scripts/smoke-webhook.sh`:

```bash
#!/usr/bin/env bash
# End-to-end smoke test against the deployed webhook.
# Uses the seeded smoke-job/secret in var/jobs.json.
# Doubles as the executable contract reference for the future sandbox client.
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck disable=SC1091
source "$PROJECT_ROOT/infra/.env"

DOMAIN="${WEBHOOK_DOMAIN:-https://webhook.getaccess.cloud}"
JOB_ID="smoke-job"
SECRET="0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
TS="$(date +%s)"
IDEM="$(uuidgen)"

BODY="$(python3 -c "
import json
print(json.dumps({
  'job_id': '$JOB_ID', 'status': 'complete',
  'artifact': '/workspace/artifacts/smoke.txt',
  'duration_s': 1, 'retry_count': 0, 'gap_count': 0,
}))")"

SIG="sha256=$(printf '%s' "$BODY" | openssl dgst -sha256 -hmac "$SECRET" | awk '{print $2}')"

echo "[1/5] healthz"
curl -fsS "$DOMAIN/healthz" | tee /dev/null

echo
echo "[2/5] complete (first call)"
HTTP_CODE_1="$(curl -sS -o /tmp/smoke1.json -w '%{http_code}' \
  -X POST "$DOMAIN/jobs/$JOB_ID/complete" \
  -H "Authorization: Bearer $WEBHOOK_BEARER" \
  -H "Content-Type: application/json" \
  -H "X-Webhook-Signature: $SIG" \
  -H "X-Webhook-Timestamp: $TS" \
  -H "Idempotency-Key: $IDEM" \
  -d "$BODY")"
echo "  HTTP $HTTP_CODE_1 — $(cat /tmp/smoke1.json)"
[ "$HTTP_CODE_1" = "200" ] || { echo "FAIL"; exit 1; }

echo "[3/5] complete (replay same Idempotency-Key)"
HTTP_CODE_2="$(curl -sS -o /tmp/smoke2.json -w '%{http_code}' \
  -X POST "$DOMAIN/jobs/$JOB_ID/complete" \
  -H "Authorization: Bearer $WEBHOOK_BEARER" \
  -H "Content-Type: application/json" \
  -H "X-Webhook-Signature: $SIG" \
  -H "X-Webhook-Timestamp: $TS" \
  -H "Idempotency-Key: $IDEM" \
  -d "$BODY")"
echo "  HTTP $HTTP_CODE_2 — $(cat /tmp/smoke2.json)"
grep -q already_recorded /tmp/smoke2.json || { echo "FAIL: expected already_recorded"; exit 1; }

echo "[4/5] bad bearer (expect 401 from NPM edge)"
HTTP_CODE_3="$(curl -sS -o /dev/null -w '%{http_code}' \
  -X POST "$DOMAIN/jobs/$JOB_ID/complete" \
  -H "Authorization: Bearer wrongtoken" \
  -d '{}')"
echo "  HTTP $HTTP_CODE_3"
[ "$HTTP_CODE_3" = "401" ] || { echo "FAIL: expected 401"; exit 1; }

echo "[5/5] /pipeline/health includes webhook fields"
HEALTH="$(curl -fsS https://paperclip.getaccess.cloud/pipeline/health)"
echo "  $HEALTH"
echo "$HEALTH" | python3 -c "
import sys, json
j = json.load(sys.stdin)
assert j.get('webhook') == 'up', f'webhook not up: {j}'
assert j.get('webhook_received_24h', 0) >= 1, f'count zero: {j}'
print('  health OK')
"

echo
echo "ALL CHECKS PASSED"
```

- [ ] **Step 2: Run the smoke script**

```bash
chmod +x scripts/smoke-webhook.sh
./scripts/smoke-webhook.sh
```

Expected last line: `ALL CHECKS PASSED`.

- [ ] **Step 3: Reset the smoke job state** (so re-runs pass)

The first `complete` POST transitioned `smoke-job` to `DONE`. To re-run smoke, reset:

```bash
python3 -c "
import json
from pathlib import Path
p = Path.home() / 'projects/30_OpenSandboxPipeline/var/jobs.json'
data = json.loads(p.read_text())
data['jobs']['smoke-job']['state'] = 'RUNNING'
p.write_text(json.dumps(data, indent=2))
print('reset smoke-job to RUNNING')
"
# Also clear any seen Idempotency-Key for re-runnable smoke:
sqlite3 var/webhook.db "DELETE FROM idempotency_keys WHERE job_id='smoke-job';"
```

(Note this for the handover; not part of the success-gate.)

- [ ] **Step 4: Commit**

```bash
git add scripts/smoke-webhook.sh
git commit -m "feat(webhook): end-to-end smoke script (executable contract reference)"
```

### Task 15: Update HANDOVER + ARCHITECTURE

**Files:**
- Modify: `~/projects/30_OpenSandboxPipeline/HANDOVER.md`
- Modify: `~/projects/00_Governance/ARCHITECTURE.md`
- Modify: `~/projects/00_Governance/KNOWN_PATTERNS.md` (if any anti-patterns surfaced)

- [ ] **Step 1: Append Plan 2 ship summary to project HANDOVER.md**

Include:
- NPM proxy host id for `webhook.getaccess.cloud`
- launchd label: `com.gtxs.pipeline-webhook` running on `127.0.0.1:9090`
- WEBHOOK_BEARER stored in `infra/.env` (first 8 chars only as evidence)
- Resume-checklist updates: how to reset smoke-job state for re-runs

- [ ] **Step 2: Append architecture insights to `00_Governance/ARCHITECTURE.md`**

Per the global tenet (architecture insights belong here):
- **Webhook is stateless w.r.t. per-job secrets.** Secret storage lives in orchestrator; webhook only queries.
- **`paperclip_client.py` is the swap point.** Stub against flat file; replace with real DB later. `app.py` and tests unaffected.
- **Edge-level static bearer at NPM (`advanced_config`)** drops random internet noise before the FastAPI app; deletes the need for in-app rate limiting at single-tenant scale.
- **Smoke script as executable contract.** Same script verifies deploy AND serves as reference implementation for the future client.

- [ ] **Step 3: KNOWN_PATTERNS check**

If any new anti-patterns surfaced during build (e.g., NPM REST quirks, launchd plist gotchas), promote them to KP-12xx with FIPD action. Otherwise note "no new patterns this plan" in the commit message.

- [ ] **Step 4: Commit**

```bash
cd ~/projects/30_OpenSandboxPipeline
git add HANDOVER.md
git commit -m "docs: Plan 2 SHIPPED — webhook listener live"

cd ~/projects/00_Governance
git add ARCHITECTURE.md KNOWN_PATTERNS.md
git commit -m "docs: capture Plan 2 architecture insights"
```

---

## Phase 1 Success Gate (Plan 2)

All of the following must be true:

- [ ] `https://webhook.getaccess.cloud/healthz` returns `{"webhook":"up"}` over TLS.
- [ ] `scripts/smoke-webhook.sh` exits with `ALL CHECKS PASSED`.
- [ ] `https://paperclip.getaccess.cloud/pipeline/health` includes `"webhook":"up"`, `"webhook_received_24h" >= 1`, `"webhook_last_seen"` non-null.
- [ ] `launchctl print "gui/$(id -u)/com.gtxs.pipeline-webhook"` shows `state = running`.
- [ ] NPM proxy host id for `webhook.getaccess.cloud` recorded in HANDOVER.md.
- [ ] `services/webhook/tests/` passes; coverage ≥90% on `auth.py` and `store.py`.
- [ ] No new high-priority gap-analysis entries in `skill_debt/pending.jsonl` (or, if present, triaged into BACKLOG).

---

## Out of scope (deferred — recorded for future plans)

- **Real Paperclip state machine** — `paperclip_client.py` will swap when Paperclip's async DB lands.
- **Sandbox-side webhook client** — implements §Retry semantics from the spec; lands with `sandbox-lifecycle` skill.
- **In-app rate limiting** — contract documented in spec §Endpoints (429 with limits); enforcement is a future ticket.
- **Multi-worker uvicorn** — gated on a real DB replacing the SQLite + `--workers 1` pattern.

---

## Source spec

`~/projects/20_agentflow/docs/specs/2026-04-28-pipeline-plan2-webhook-listener-design.md` (spec-panel 8.6/10, gate ≥7.0)
