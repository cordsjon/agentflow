---
name: sh-index-repo
description: "Generate compressed project map for token-efficient codebase understanding"
---

# Repository Indexing

Generate a compressed project index that captures structure, entry points, and key modules.
Dramatically reduces tokens needed to understand a codebase in future sessions.

## Why

- Full codebase read: ~50-100K tokens per session
- Project index read: ~2-5K tokens per session
- Break-even: 1 session

## When to Use

- Starting work on an unfamiliar repo
- Onboarding to a new project
- Creating a reference for future sessions
- After significant structural changes

## Process

### 1. Analyze Structure

Parallel file discovery across categories:

- **Code**: `src/**/*.{py,ts,js,go,rs}`, `lib/**/*`, `app/**/*`
- **Config**: `*.toml`, `*.yaml`, `*.json` (exclude lockfiles, node_modules)
- **Tests**: `tests/**/*`, `**/*.test.*`, `**/*.spec.*`
- **Scripts**: `scripts/**/*`, `bin/**/*`, `Makefile`, `*.sh`, `*.ps1`
- **Docs**: `*.md`, `docs/**/*`

### 2. Extract Key Metadata

For each category:
- Entry points (main, cli, index, app)
- Public API surface (exported functions/classes)
- Core modules and their single-line purpose
- Key dependencies and their role

### 3. Generate Index

Output `PROJECT_INDEX.md`:

```markdown
# Project Index: {name}
Generated: {date}

## Structure
{tree view, 2-3 levels deep}

## Entry Points
- {path}: {what it does}

## Core Modules
### {module}
- Path: {path}
- Purpose: {one line}
- Key exports: {list}

## Configuration
- {file}: {purpose}

## Test Coverage
- {count} test files across {categories}

## Dependencies
- {key dep}: {why it's used}

## Quick Start
1. {setup}
2. {run}
3. {test}
```

### 4. Validate

- Index under 5KB?
- All entry points identified?
- Core modules documented?
- Quick start accurate?

## Modes

| Mode | Scope |
|------|-------|
| **full** | Complete index with all categories |
| **quick** | Structure + entry points only (skip tests/docs) |
| **update** | Refresh existing index with changes since last generation |

## Boundaries

**Will**: Analyze repo structure, generate compressed index, identify key components.
**Will not**: Modify code, restructure directories, or create documentation beyond the index.

## Next Step

Read `PROJECT_INDEX.md` at session start instead of scanning the full codebase.
