---
name: sh:troubleshoot
description: "Issue resolution for builds, deploys, CI/CD, and system infrastructure"
---

# Troubleshooting

Diagnose and resolve operational issues: build failures, deployment problems, CI/CD pipeline errors,
dependency conflicts, and infrastructure configuration.

Broader than `/sh:debug` -- covers the full operational stack, not just code bugs.

## When to Use

- Build failures (compilation, bundling, linking)
- Deployment problems (containers, services, environments)
- CI/CD pipeline errors (actions, hooks, scripts)
- Dependency conflicts (version mismatches, missing packages)
- Environment/configuration issues (env vars, paths, permissions)

## Process

### 1. Classify Issue Type

| Type | Signals |
|------|---------|
| **Build** | Compilation errors, missing modules, config parse failures |
| **Deploy** | Service won't start, port conflicts, permission denied |
| **CI/CD** | Pipeline step fails, secret not found, artifact missing |
| **Dependency** | Version conflict, peer dep warning, lockfile mismatch |
| **Environment** | Works locally but not in CI, missing env var, wrong path |

### 2. Gather State

- Read error output/logs completely
- Check environment: OS, runtime versions, env vars
- Review recent changes: git log, config diffs, dependency updates
- Verify prerequisites: required services, ports, credentials

### 3. Isolate Layer

For multi-layer issues, test each boundary:
```
Source -> Build -> Artifact -> Deploy -> Runtime -> Network
         ^                     ^
    Which layer fails?    Which layer fails?
```

Add diagnostic output at each layer until you find where it breaks.

### 4. Diagnose

- Compare against known-working state (last green build, working branch)
- Check project-specific patterns (Makefile, docker-compose, CI config)
- Search error messages in project issues/docs

### 5. Resolve

- Apply targeted fix at the failing layer
- Verify the fix resolves the issue
- Confirm no regressions in adjacent layers

### 6. Report

```
## Diagnosis
- Issue: [what broke]
- Layer: [where it broke]
- Root cause: [why it broke]

## Resolution
- Fix applied: [what was changed]
- Verified by: [how confirmed]

## Prevention
- [Optional: how to prevent recurrence]
```

## Boundaries

**Will**: Diagnose operational issues, apply safe fixes, verify resolution.
**Will not**: Modify production systems without confirmation, make architectural changes, ignore root cause.

Default behavior is diagnosis-only. Fixes require explicit user approval.

## Next Step

After resolution, use `/sh:test` to run the test suite and confirm no regressions.
