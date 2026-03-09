# Known Patterns — Cross-Project Lessons Learned

> Anti-patterns identified across all governed projects.
> Claude MUST consult this before writing new code in any project.
> Project-specific patterns stay in project repos; patterns that recur across projects graduate here.

---

## 1. Configuration & Environment

| # | Anti-Pattern | Correct Pattern | Origin |
|---|-------------|-----------------|--------|
| 1 | **Evaluating settings at module import time** — value freezes, ignores runtime changes | Use `None` default + resolved method at call time | — |
| 2 | **Catching bare `Exception`** — hides system exits, OOM, permission errors | Catch specific exceptions: `OSError`, `ValueError`, `httpx.HTTPError` | — |
| 3 | **Import-time side effects** (creating semaphores, opening files at module level) | Defer to factory function, `__init__`, or startup handler | — |

## 2. Data & Sorting

| # | Anti-Pattern | Correct Pattern | Origin |
|---|-------------|-----------------|--------|
| 4 | **`dict.get(key, default)` when value can be `None`** — returns `None` not default | Use `dict.get(key) or default` to coerce `None` | — |
| 5 | **Loading all rows then checking count** against a limit — OOM at scale | Run `SELECT COUNT(*)` first, reject if over limit, then load | — |

## 3. Process & Infrastructure

| # | Anti-Pattern | Correct Pattern | Origin |
|---|-------------|-----------------|--------|
| 6 | **Bare `python` in scripts** — resolves to wrong venv on PATH | Use explicit venv path: `$ProjectRoot\.venv\Scripts\python.exe` | — |
| 7 | **ngrok free-tier URLs assumed stable** — tunnels expire when process stops | Either use static domain (paid) or document restart procedure | — |
| 8 | **Semaphore read once at session start** — misses mid-session pause signals | Re-read semaphore file before EVERY loop iteration | — |

## 4. Frontend & CSS

| # | Anti-Pattern | Correct Pattern | Origin |
|---|-------------|-----------------|--------|
| 9 | **Hardcoded hex colors** instead of CSS custom properties | Extract to `:root` tokens, reference with `var(--name)` | — |
| 10 | **Hardcoded magic numbers** in JS duplicating Python constants | Read from DOM `data-` attributes set by templates | — |

---

_Last updated: 2026-03-01. Add new patterns as they emerge from retros and quality audits._
