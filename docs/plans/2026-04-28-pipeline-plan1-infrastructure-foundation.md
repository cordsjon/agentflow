# Pipeline Plan 1: Infrastructure Foundation Implementation Plan

> **For agentic workers:** REQUIRED: Use `/sh:execute` to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deploy OpenSandbox locally on the Mac Mini, expose Paperclip webhook publicly via the existing VPS, and stand up a `/pipeline/health` endpoint that all later plans depend on.

**Architecture:** OpenSandbox runs in Docker on the Mac Mini (single-tenant, runc backend). Public reachability for the Paperclip webhook reuses the existing autossh tunnel pattern from Hermes — Mac Mini port forwards to VPS `72.61.159.117`, nginx reverse-proxies `getaccess.cloud:9090` to the local webhook listener. A FastAPI `/pipeline/health` endpoint on the VPS aggregates component liveness.

**Tech Stack:** Docker Compose, OpenSandbox (alibaba/OpenSandbox `opensandbox/server:v0.1.12`), TOML config, nginx, autossh, FastAPI, systemd, launchd, pytest, curl.

**Prerequisites this plan does NOT install:** Docker (assumed installed on Mac Mini), Python 3.11+ (assumed), nginx (assumed running on VPS), autossh (assumed installed on Mac Mini).

**Source spec:** `projects/20_agentflow/docs/specs/2026-04-28-opensandbox-pipeline-design.md`

**Upstream interface (verified 2026-04-28 against `alibaba/OpenSandbox` main branch):**
- Lifecycle API base URL: `http://localhost:8080/v1` (port configurable via TOML `[server].port`; `8080` is the OpenAPI default — used here)
- Auth header: `OPEN-SANDBOX-API-KEY: <key>` (set in TOML `[server].api_key`); without it the server requires `OPENSANDBOX_INSECURE_SERVER=YES` or interactive `YES` confirmation at startup
- Public unauthed routes: `/health`, `/docs`, `/redoc`
- Server config: TOML at `~/.sandbox.toml` (default) or `SANDBOX_CONFIG_PATH` env override; **server has no `SANDBOX_DEFAULT_TTL`/`SANDBOX_RESOURCE_*` env knobs** — TTL and resources are per-create-request fields
- Required `[runtime]` keys: `type = "docker"` and `execd_image` (e.g. `opensandbox/execd:v1.0.14`); `[egress].image` only required if any client uses `networkPolicy` on create
- CreateSandbox payload: `{"image": {"uri": "<ref>"}, "timeout": <seconds ≥60 or null>, "resourceLimits": {"cpu": "500m", "memory": "512Mi"}, "entrypoint": ["..."]}` — `entrypoint` is required when `image` is provided
- Pinned tag: `opensandbox/server:v0.1.12` (latest release on Docker Hub as of 2026-04-27); avoid `:latest` for reproducibility

---

## File Structure

This plan creates a new project root: `~/projects/30_OpenSandboxPipeline/` (slot 30 because it's a new infra-tier product, alongside SVG-PAINT).

```
30_OpenSandboxPipeline/
├── CLAUDE.md                          # Project rules
├── README.md                          # Quick start
├── infra/
│   ├── docker-compose.yml             # OpenSandbox + dependencies
│   ├── opensandbox.env.example        # Env template (tokens, ports)
│   ├── nginx-pipeline.conf            # VPS reverse proxy config
│   ├── webhook-tunnel.service         # systemd unit for autossh tunnel
│   └── health_endpoint.py             # FastAPI app for /pipeline/health
├── scripts/
│   ├── install-opensandbox.sh         # One-shot install on Mac Mini
│   ├── deploy-vps.sh                  # Push nginx + health to VPS
│   └── verify-foundation.sh           # End-to-end smoke test
└── tests/
    ├── test_health_endpoint.py        # Unit tests for FastAPI endpoint
    └── test_foundation_e2e.py         # Integration: sandbox ↔ webhook
```

**Files modified outside this project:**
- VPS: `/etc/nginx/conf.d/pipeline.conf` (new)
- VPS: `/etc/systemd/system/pipeline-health.service` (new)
- Mac Mini: `/etc/systemd/user/pipeline-webhook-tunnel.service` (new)

---

## Chunk 1: Project Scaffolding

### Task 1: Create project directory and CLAUDE.md

**Files:**
- Create: `~/projects/30_OpenSandboxPipeline/CLAUDE.md`
- Create: `~/projects/30_OpenSandboxPipeline/README.md`
- Create: `~/projects/30_OpenSandboxPipeline/.gitignore`

- [ ] **Step 1: Create project directory**

```bash
mkdir -p ~/projects/30_OpenSandboxPipeline/{infra,scripts,tests}
cd ~/projects/30_OpenSandboxPipeline
git init
```

- [ ] **Step 2: Write CLAUDE.md**

```markdown
# OpenSandbox Pipeline — Infrastructure Foundation

Plan reference: `~/projects/20_agentflow/docs/plans/2026-04-28-pipeline-plan1-infrastructure-foundation.md`
Spec reference: `~/projects/20_agentflow/docs/specs/2026-04-28-opensandbox-pipeline-design.md`

## Components
- OpenSandbox runs locally on Mac Mini via Docker (port 8080)
- Webhook listener on Mac Mini port 9090
- autossh tunnel forwards two ports: Mac Mini:9090 → VPS localhost:9090 (webhook ingress) AND Mac Mini:8080 → VPS localhost:8080 (OpenSandbox liveness probe — VPS-only, never exposed publicly)
- nginx reverse-proxies VPS public:9090 → localhost:9090
- FastAPI `/pipeline/health` runs on VPS and probes `localhost:8080/health` (OpenSandbox via tunnel) + the local webhook listener

## VPS
Host: `root@72.61.159.117` (paperclip.getaccess.cloud)
nginx config dir: `/etc/nginx/conf.d/`
Health endpoint port: 9091 (behind nginx at /pipeline/health)
```

- [ ] **Step 3: Write minimal README.md**

```markdown
# OpenSandbox Pipeline — Infrastructure Foundation

## Quick start
1. `bash scripts/install-opensandbox.sh` — install OpenSandbox locally
2. `bash scripts/deploy-vps.sh` — push nginx + health to VPS
3. `bash scripts/verify-foundation.sh` — smoke test
```

- [ ] **Step 4: Write .gitignore**

```
*.env
!*.env.example
__pycache__/
.pytest_cache/
*.log
```

- [ ] **Step 5: Initial commit**

```bash
git add CLAUDE.md README.md .gitignore
git commit -m "chore: scaffold OpenSandbox Pipeline project"
```

---

## Chunk 2: OpenSandbox Local Install

### Task 2: Write docker-compose.yml for OpenSandbox

**Files:**
- Create: `~/projects/30_OpenSandboxPipeline/infra/docker-compose.yml`
- Create: `~/projects/30_OpenSandboxPipeline/infra/opensandbox.env.example`

- [ ] **Step 1: Write docker-compose.yml**

```yaml
# OpenSandbox lifecycle server (single-tenant dev mode)
# Reference: https://github.com/alibaba/OpenSandbox/blob/main/server/docker-compose.example.yaml
# Server config is TOML-driven, injected via Compose `configs:` (the upstream pattern).
# Per-sandbox TTL and resource limits are passed in CreateSandbox payloads, not server-level env vars.
configs:
  opensandbox-config:
    content: |
      [server]
      host = "0.0.0.0"
      port = 8080
      api_key = "${OPEN_SANDBOX_API_KEY}"
      max_sandbox_timeout_seconds = 7200   # spec §Job Lifecycle hard cap

      [log]
      level = "INFO"

      [runtime]
      type = "docker"
      execd_image = "opensandbox/execd:v1.0.14"

      [docker]
      network_mode = "bridge"
      host_ip = "host.docker.internal"
      drop_capabilities = ["AUDIT_WRITE", "MKNOD", "NET_ADMIN", "NET_RAW", "SYS_ADMIN", "SYS_MODULE", "SYS_PTRACE", "SYS_TIME", "SYS_TTY_CONFIG"]
      no_new_privileges = true
      pids_limit = 4096

      [egress]
      image = "opensandbox/egress:v1.0.9"
      mode = "dns"

      [ingress]
      mode = "direct"

version: "3.9"
services:
  opensandbox-server:
    image: opensandbox/server:v0.1.12
    container_name: opensandbox-server
    ports:
      - "127.0.0.1:8080:8080"   # Lifecycle API — bind to localhost only; VPS reach is via autossh tunnel
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    configs:
      - source: opensandbox-config
        target: /etc/opensandbox/config.toml
    environment:
      - SANDBOX_CONFIG_PATH=/etc/opensandbox/config.toml
    env_file:
      - opensandbox.env
    restart: unless-stopped
```

- [ ] **Step 2: Write env template**

```bash
# opensandbox.env.example — copy to opensandbox.env and fill in
# This token is interpolated into config.toml [server].api_key by docker-compose's
# `${OPEN_SANDBOX_API_KEY}` substitution. Clients send it as the
# OPEN-SANDBOX-API-KEY HTTP header on every lifecycle call.
OPEN_SANDBOX_API_KEY=<generate-with-openssl-rand-hex-32>
```

- [ ] **Step 3: Commit**

```bash
git add infra/docker-compose.yml infra/opensandbox.env.example
git commit -m "feat(infra): add OpenSandbox docker-compose"
```

### Task 3: Write install-opensandbox.sh

**Files:**
- Create: `~/projects/30_OpenSandboxPipeline/scripts/install-opensandbox.sh`

- [ ] **Step 1: Write install script**

```bash
#!/usr/bin/env bash
# Installs OpenSandbox locally on the Mac Mini
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$SCRIPT_DIR/../infra"

cd "$INFRA_DIR"

# Generate env file if missing
if [[ ! -f opensandbox.env ]]; then
    cp opensandbox.env.example opensandbox.env
    TOKEN=$(openssl rand -hex 32)
    sed -i '' "s|<generate-with-openssl-rand-hex-32>|$TOKEN|" opensandbox.env
    echo "Generated opensandbox.env with new API key"
fi

# Pull and start (also pulls execd + egress runtime images on first sandbox create)
docker compose pull
docker compose up -d

# Wait for health (public route, no API key required)
echo "Waiting for OpenSandbox to start..."
for i in {1..30}; do
    if curl -sf http://127.0.0.1:8080/health > /dev/null 2>&1; then
        echo "OpenSandbox is up at http://127.0.0.1:8080"
        exit 0
    fi
    sleep 2
done

echo "ERROR: OpenSandbox did not start within 60s"
docker compose logs --tail=50 opensandbox-server
exit 1
```

- [ ] **Step 2: Make executable and run**

```bash
chmod +x scripts/install-opensandbox.sh
bash scripts/install-opensandbox.sh
```

Expected: "OpenSandbox is up at http://127.0.0.1:8000"

- [ ] **Step 3: Verify lifecycle API responds**

```bash
curl -sf http://127.0.0.1:8080/health
```

Expected: HTTP 200. `/health` is documented as a public unauthed route.

- [ ] **Step 4: Verify can create + destroy a sandbox**

```bash
KEY=$(grep '^OPEN_SANDBOX_API_KEY=' infra/opensandbox.env | cut -d= -f2)

# Create — payload shape per sandbox-lifecycle.yml CreateSandboxRequest
SBX_ID=$(curl -sf -X POST http://127.0.0.1:8080/v1/sandboxes \
  -H "OPEN-SANDBOX-API-KEY: $KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "image": {"uri": "alpine:latest"},
    "timeout": 60,
    "resourceLimits": {"cpu": "500m", "memory": "256Mi"},
    "entrypoint": ["sleep", "60"]
  }' | python3 -c "import json,sys; print(json.load(sys.stdin)['id'])")
echo "Created: $SBX_ID"

# Destroy
curl -sf -X DELETE "http://127.0.0.1:8080/v1/sandboxes/$SBX_ID" \
  -H "OPEN-SANDBOX-API-KEY: $KEY"
echo "Destroyed: $SBX_ID"
```

Expected: Create returns HTTP 200 with `id` (a UUID-like string). Delete returns 200 or 204.

> Field names confirmed against `specs/sandbox-lifecycle.yml` on `alibaba/OpenSandbox` main branch (read 2026-04-28). The response uses `id`; the URL path parameter is `{sandboxId}`. The `image` field is an **object** (`{"uri": "..."}`), not a plain string. `entrypoint` is **mandatory** when `image` is provided. `resourceLimits` is the only required field on the request.

- [ ] **Step 5: Commit**

```bash
git add scripts/install-opensandbox.sh
git commit -m "feat(infra): add OpenSandbox install script"
```

---

## Chunk 3: Webhook Tunnel (Mac Mini → VPS)

### Task 4: Write autossh tunnel systemd unit

**Files:**
- Create: `~/projects/30_OpenSandboxPipeline/infra/webhook-tunnel.service`

- [ ] **Step 1: Write systemd user unit**

```ini
# /etc/systemd/user/pipeline-webhook-tunnel.service
[Unit]
Description=Reverse SSH tunnel for Pipeline webhook (Mac Mini -> VPS)
After=network.target

[Service]
Environment="AUTOSSH_GATETIME=0"
ExecStart=/opt/homebrew/bin/autossh -M 0 -N \
    -o "ServerAliveInterval 30" \
    -o "ServerAliveCountMax 3" \
    -o "ExitOnForwardFailure yes" \
    -R 9090:127.0.0.1:9090 \
    -R 8080:127.0.0.1:8080 \
    root@72.61.159.117
Restart=always
RestartSec=10

[Install]
WantedBy=default.target
```

- [ ] **Step 2: Install and start**

```bash
mkdir -p ~/Library/LaunchAgents
cp infra/webhook-tunnel.service ~/.config/systemd/user/pipeline-webhook-tunnel.service \
    2>/dev/null || true
# macOS uses launchd, not systemd. Use launchctl alternative below.
```

> **macOS adaptation:** Mac Mini does not run systemd. Translate to a `launchd` plist instead. The Hermes project uses the same pattern — check `~/projects/80_HermesAndroid/scripts/` for the existing autossh launchd plist and clone it.

- [ ] **Step 3: Write launchd plist (macOS)**

Create: `~/Library/LaunchAgents/com.gtxs.pipeline-webhook-tunnel.plist`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.gtxs.pipeline-webhook-tunnel</string>
    <key>ProgramArguments</key>
    <array>
        <string>/opt/homebrew/bin/autossh</string>
        <string>-M</string><string>0</string>
        <string>-N</string>
        <string>-o</string><string>ServerAliveInterval=30</string>
        <string>-o</string><string>ServerAliveCountMax=3</string>
        <string>-o</string><string>ExitOnForwardFailure=yes</string>
        <string>-R</string><string>9090:127.0.0.1:9090</string>
        <string>-R</string><string>8080:127.0.0.1:8080</string>
        <string>root@72.61.159.117</string>
    </array>
    <key>EnvironmentVariables</key>
    <dict>
        <key>AUTOSSH_GATETIME</key><string>0</string>
    </dict>
    <key>RunAtLoad</key><true/>
    <key>KeepAlive</key><true/>
    <key>StandardOutPath</key><string>/tmp/pipeline-webhook-tunnel.out.log</string>
    <key>StandardErrorPath</key><string>/tmp/pipeline-webhook-tunnel.err.log</string>
</dict>
</plist>
```

- [ ] **Step 4: Load tunnel**

```bash
launchctl load ~/Library/LaunchAgents/com.gtxs.pipeline-webhook-tunnel.plist
launchctl list | grep pipeline-webhook-tunnel
```

Expected: Output shows the service with PID (not `-`).

- [ ] **Step 5: Verify tunnel works (test webhook listener stub)**

```bash
# Start a stub listener on Mac Mini port 9090
python3 -m http.server 9090 &
STUB_PID=$!

# From VPS, hit localhost:9090
ssh root@72.61.159.117 'curl -sf http://localhost:9090 | head -5'

# Cleanup stub
kill $STUB_PID
```

Expected: HTML directory listing returned. This proves Mac Mini:9090 is reachable from VPS.

- [ ] **Step 6: Commit**

```bash
git add infra/webhook-tunnel.service
git commit -m "feat(infra): add autossh webhook tunnel for Mac Mini -> VPS"
```

---

## Chunk 4: VPS nginx Reverse Proxy

### Task 5: Write nginx config for webhook + health

**Files:**
- Create: `~/projects/30_OpenSandboxPipeline/infra/nginx-pipeline.conf`

- [ ] **Step 1: Write nginx config**

```nginx
# nginx-pipeline.conf
# Deploy:
#   scp infra/nginx-pipeline.conf root@72.61.159.117:/etc/nginx/conf.d/pipeline.conf
#   ssh root@72.61.159.117 "nginx -t && systemctl reload nginx"

# Webhook endpoint (Paperclip POSTs from inside sandbox)
# Forwards public:9090 -> autossh tunnel -> Mac Mini:9090
server {
    listen 9090;
    server_name getaccess.cloud;

    location / {
        proxy_pass http://127.0.0.1:9090;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_read_timeout 60s;
    }
}

# Health endpoint (FastAPI on VPS, port 9091)
location /pipeline/health {
    proxy_pass http://127.0.0.1:9091/health;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
}
```

> **Note:** The `/pipeline/health` block must go inside the existing `getaccess.cloud` HTTPS server block. If unsure where, ask the existing nginx config maintainer (or read `/etc/nginx/conf.d/` on the VPS first).

- [ ] **Step 2: Commit**

```bash
git add infra/nginx-pipeline.conf
git commit -m "feat(infra): add nginx reverse proxy config for webhook + health"
```

---

## Chunk 5: Health Endpoint (FastAPI on VPS)

### Task 6: Write health endpoint with TDD

**Files:**
- Create: `~/projects/30_OpenSandboxPipeline/infra/health_endpoint.py`
- Create: `~/projects/30_OpenSandboxPipeline/tests/test_health_endpoint.py`

- [ ] **Step 1: Write the failing test**

```python
# tests/test_health_endpoint.py
import os
import sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "infra"))

from fastapi.testclient import TestClient
from health_endpoint import app, _check_component


def test_health_returns_all_components():
    client = TestClient(app)
    r = client.get("/health")
    assert r.status_code == 200
    data = r.json()
    assert set(data.keys()) >= {"opensandbox", "hermes", "paperclip", "active_jobs"}


def test_check_component_up(monkeypatch):
    def fake_get(url, timeout):
        class R: status_code = 200
        return R()
    import requests
    monkeypatch.setattr(requests, "get", fake_get)
    assert _check_component("http://example.com/health") == "up"


def test_check_component_down(monkeypatch):
    def fake_get(url, timeout):
        raise Exception("connection refused")
    import requests
    monkeypatch.setattr(requests, "get", fake_get)
    assert _check_component("http://example.com/health") == "down"
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd ~/projects/30_OpenSandboxPipeline
pip install fastapi requests pytest httpx
pytest tests/test_health_endpoint.py -v
```

Expected: FAIL with `ModuleNotFoundError: No module named 'health_endpoint'`

- [ ] **Step 3: Write minimal implementation**

```python
# infra/health_endpoint.py
"""Pipeline health endpoint — aggregates liveness of OpenSandbox, Hermes, Paperclip."""
import os
import requests
from fastapi import FastAPI

app = FastAPI()

OPENSANDBOX_URL = os.getenv("OPENSANDBOX_HEALTH", "http://127.0.0.1:8080/health")  # via autossh tunnel from VPS
HERMES_URL = os.getenv("HERMES_HEALTH", "https://getaccess.cloud/hermes/health")
PAPERCLIP_URL = os.getenv("PAPERCLIP_HEALTH", "https://paperclip.getaccess.cloud/api/health")


def _check_component(url: str) -> str:
    try:
        r = requests.get(url, timeout=3)
        return "up" if r.status_code == 200 else "down"
    except Exception:
        return "down"


@app.get("/health")
def health():
    return {
        "opensandbox": _check_component(OPENSANDBOX_URL),
        "hermes": _check_component(HERMES_URL),
        "paperclip": _check_component(PAPERCLIP_URL),
        "active_jobs": 0,  # Wired in Plan 2
    }
```

- [ ] **Step 4: Run test to verify it passes**

```bash
pytest tests/test_health_endpoint.py -v
```

Expected: 3 passed.

- [ ] **Step 5: Commit**

```bash
git add infra/health_endpoint.py tests/test_health_endpoint.py
git commit -m "feat(infra): add /pipeline/health FastAPI endpoint with tests"
```

### Task 7: Write systemd unit for health endpoint on VPS

**Files:**
- Create: `~/projects/30_OpenSandboxPipeline/infra/pipeline-health.service`

- [ ] **Step 1: Write systemd unit**

```ini
# /etc/systemd/system/pipeline-health.service
[Unit]
Description=Pipeline Health Endpoint
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/pipeline
ExecStart=/usr/bin/uvicorn health_endpoint:app --host 127.0.0.1 --port 9091
Restart=always
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
```

- [ ] **Step 2: Commit**

```bash
git add infra/pipeline-health.service
git commit -m "feat(infra): add systemd unit for health endpoint"
```

---

## Chunk 6: VPS Deploy Script

### Task 8: Write deploy-vps.sh

**Files:**
- Create: `~/projects/30_OpenSandboxPipeline/scripts/deploy-vps.sh`

- [ ] **Step 1: Write deploy script**

```bash
#!/usr/bin/env bash
# Deploys nginx config + health endpoint to VPS
set -euo pipefail

VPS="root@72.61.159.117"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$SCRIPT_DIR/../infra"

echo "==> Copying nginx config"
scp "$INFRA_DIR/nginx-pipeline.conf" "$VPS:/etc/nginx/conf.d/pipeline.conf"

echo "==> Copying health endpoint"
ssh "$VPS" "mkdir -p /opt/pipeline"
scp "$INFRA_DIR/health_endpoint.py" "$VPS:/opt/pipeline/health_endpoint.py"
scp "$INFRA_DIR/pipeline-health.service" "$VPS:/etc/systemd/system/pipeline-health.service"

echo "==> Installing Python deps on VPS"
ssh "$VPS" "pip3 install --quiet fastapi uvicorn requests"

echo "==> Reloading nginx"
ssh "$VPS" "nginx -t && systemctl reload nginx"

echo "==> Enabling and starting health endpoint"
ssh "$VPS" "systemctl daemon-reload && systemctl enable --now pipeline-health"

echo "==> Done. Verify with:"
echo "    curl -sf https://getaccess.cloud/pipeline/health | python3 -m json.tool"
```

- [ ] **Step 2: Make executable and run**

```bash
chmod +x scripts/deploy-vps.sh
bash scripts/deploy-vps.sh
```

Expected: All steps complete. No errors.

- [ ] **Step 3: Verify endpoint live**

```bash
curl -sf https://getaccess.cloud/pipeline/health | python3 -m json.tool
```

Expected output:
```json
{
    "opensandbox": "up" | "down",
    "hermes": "up" | "down",
    "paperclip": "up" | "down",
    "active_jobs": 0
}
```

`opensandbox` may be `down` until tunnel is up — that's expected. `paperclip` should be `up` since it's already running.

- [ ] **Step 4: Commit**

```bash
git add scripts/deploy-vps.sh
git commit -m "feat(scripts): add VPS deploy script"
```

---

## Chunk 7: End-to-End Verification

### Task 9: Write verify-foundation.sh

**Files:**
- Create: `~/projects/30_OpenSandboxPipeline/scripts/verify-foundation.sh`
- Create: `~/projects/30_OpenSandboxPipeline/tests/test_foundation_e2e.py`

- [ ] **Step 1: Write E2E test**

```python
# tests/test_foundation_e2e.py
"""
End-to-end verification: OpenSandbox running locally, webhook reachable from public,
health endpoint returns all components up.
"""
import os
import requests
import subprocess


SANDBOX_API = "http://127.0.0.1:8080"
HEALTH_URL = "https://getaccess.cloud/pipeline/health"


def _api_key():
    env_path = os.path.expanduser("~/projects/30_OpenSandboxPipeline/infra/opensandbox.env")
    for line in open(env_path):
        if line.startswith("OPEN_SANDBOX_API_KEY="):
            return line.split("=", 1)[1].strip()
    raise RuntimeError("OPEN_SANDBOX_API_KEY missing from opensandbox.env")


def test_opensandbox_local_up():
    r = requests.get(f"{SANDBOX_API}/health", timeout=5)
    assert r.status_code == 200


def test_can_create_and_destroy_sandbox():
    headers = {"OPEN-SANDBOX-API-KEY": _api_key(), "Content-Type": "application/json"}
    r = requests.post(
        f"{SANDBOX_API}/v1/sandboxes",
        headers=headers,
        json={
            "image": {"uri": "alpine:latest"},
            "timeout": 60,
            "resourceLimits": {"cpu": "500m", "memory": "256Mi"},
            "entrypoint": ["sleep", "60"],
        },
        timeout=30,  # first run pulls execd image
    )
    assert r.status_code == 200, r.text
    sbx_id = r.json()["id"]
    r2 = requests.delete(f"{SANDBOX_API}/v1/sandboxes/{sbx_id}", headers=headers, timeout=10)
    assert r2.status_code in (200, 204)


def test_health_endpoint_public_reachable():
    r = requests.get(HEALTH_URL, timeout=5)
    assert r.status_code == 200
    data = r.json()
    assert set(data.keys()) >= {"opensandbox", "hermes", "paperclip"}


def test_webhook_tunnel_reachable_from_vps():
    # Start a stub on local 9090, check from VPS
    stub = subprocess.Popen(
        ["python3", "-c", "import http.server,socketserver;socketserver.TCPServer(('127.0.0.1',9090),http.server.SimpleHTTPRequestHandler).serve_forever()"]
    )
    try:
        import time
        time.sleep(2)
        result = subprocess.run(
            ["ssh", "root@72.61.159.117", "curl -sf -o /dev/null -w '%{http_code}' http://localhost:9090"],
            capture_output=True, text=True, timeout=10,
        )
        assert result.stdout.strip() == "200", f"Got {result.stdout!r}"
    finally:
        stub.terminate()
```

- [ ] **Step 2: Run E2E tests**

```bash
cd ~/projects/30_OpenSandboxPipeline
pytest tests/test_foundation_e2e.py -v
```

Expected: 4 passed.

- [ ] **Step 3: Write verify-foundation.sh wrapper**

```bash
#!/usr/bin/env bash
# End-to-end smoke test for Plan 1 deliverables
set -euo pipefail

echo "==> [1/4] Checking OpenSandbox local"
curl -sf http://127.0.0.1:8080/health > /dev/null && echo "  OK" || { echo "  FAIL"; exit 1; }

echo "==> [2/4] Checking autossh tunnel"
launchctl list | grep -q pipeline-webhook-tunnel && echo "  OK" || { echo "  FAIL"; exit 1; }

echo "==> [3/4] Checking health endpoint public"
curl -sf https://getaccess.cloud/pipeline/health > /dev/null && echo "  OK" || { echo "  FAIL"; exit 1; }

echo "==> [4/4] Running pytest E2E"
cd "$(dirname "${BASH_SOURCE[0]}")/.."
pytest tests/test_foundation_e2e.py -v

echo ""
echo "Foundation OK. Plan 2 (Paperclip state machine) is unblocked."
```

- [ ] **Step 4: Run wrapper**

```bash
chmod +x scripts/verify-foundation.sh
bash scripts/verify-foundation.sh
```

Expected: All 4 checks OK, pytest 4 passed, "Foundation OK" message.

- [ ] **Step 5: Commit**

```bash
git add scripts/verify-foundation.sh tests/test_foundation_e2e.py
git commit -m "test: add foundation E2E verification"
```

---

## Chunk 8: Documentation & Handoff

### Task 10: Update spec with concrete URLs

**Files:**
- Modify: `~/projects/20_agentflow/docs/specs/2026-04-28-opensandbox-pipeline-design.md`

- [ ] **Step 1: Replace placeholder URLs in Infrastructure section**

Find: `Paperclip webhook exposed at \`getaccess.cloud:9090\``
Replace with confirmed URL: `Paperclip webhook exposed at \`https://getaccess.cloud:9090\` via autossh tunnel + nginx (verified end-to-end in Plan 1)`

- [ ] **Step 2: Add "Implementation status" line under Infrastructure**

Add after the Observability section:
```markdown
**Implementation status (2026-04-28):** Plan 1 (Infrastructure foundation) complete. OpenSandbox `opensandbox/server:v0.1.12` running locally on Mac Mini:8080 (TOML-config-driven, `OPEN-SANDBOX-API-KEY` auth). Webhook reachable at `getaccess.cloud:9090`. Health endpoint live at `https://getaccess.cloud/pipeline/health` and probes OpenSandbox via reverse-tunnel to localhost:8080.
```

- [ ] **Step 3: Commit**

```bash
cd ~/projects/20_agentflow
git add docs/specs/2026-04-28-opensandbox-pipeline-design.md
git commit -m "docs(spec): mark Plan 1 infrastructure foundation complete"
```

---

## Definition of Done

Plan 1 is complete when **all** of the following are true:

- [ ] `bash scripts/verify-foundation.sh` exits 0
- [ ] `curl -sf https://getaccess.cloud/pipeline/health` returns JSON with `opensandbox: "up"` (proves the 8080 reverse tunnel is live and the health probe reaches it)
- [ ] A sandbox can be created and destroyed via the local OpenSandbox API
- [ ] The webhook tunnel survives a Mac Mini reboot (test by `launchctl bootout` and `bootstrap`)
- [ ] All tests in `tests/` pass
- [ ] Spec is updated with concrete URLs and implementation status

Plan 2 (Paperclip state machine) starts here: it builds on the webhook reachability and health endpoint established in this plan.

---

## Risks & Open Items

1. ~~**OpenSandbox API path drift**~~ — **Resolved 2026-04-28** by reading `specs/sandbox-lifecycle.yml` on `alibaba/OpenSandbox@main`. Path is `/v1/sandboxes`, auth header is `OPEN-SANDBOX-API-KEY`, image field is `{"uri": "..."}`, `entrypoint` and `resourceLimits` required. All curl/pytest payloads in this plan now match the verified schema.
2. **VPS nginx server block placement:** The `/pipeline/health` location block needs to live inside the existing HTTPS server block for `getaccess.cloud`. If the existing config uses an `include` pattern, adapt Task 5.
3. ~~**Mac Mini SSH key on VPS**~~ — **Verified 2026-04-28**: passwordless `ssh root@72.61.159.117` works.
4. ~~**OpenSandbox image availability**~~ — **Verified 2026-04-28**: `opensandbox/server:v0.1.12` is on Docker Hub (last published 2026-04-25). Plan pins this tag instead of `:latest` for reproducibility.
5. **Egress + execd runtime images:** `opensandbox/execd:v1.0.14` and `opensandbox/egress:v1.0.9` are pulled lazily on first sandbox create. First sandbox create may take 30-60s while these pull. The E2E test allows for this.
6. **Server insecure-mode guard:** OpenSandbox refuses to start without an `api_key` set in TOML unless `OPENSANDBOX_INSECURE_SERVER=YES` is passed. This plan sets `api_key` from `OPEN_SANDBOX_API_KEY` in `opensandbox.env`, so the guard is satisfied. If the env file is missing, the container will exit on startup — `install-opensandbox.sh` regenerates it on first run.
7. **Tunnel exposes OpenSandbox to VPS-localhost:** The second `-R 8080:127.0.0.1:8080` makes the lifecycle API reachable from anyone with shell access to the VPS. Acceptable for Phase 1 (only you have root there); revisit before Phase 2 (external customers) — bind to `127.0.0.1` on the VPS side via `GatewayPorts no` (already SSH default) and consider IP allowlisting in nginx.
