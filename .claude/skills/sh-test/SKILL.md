---
name: sh:test
description: "Test execution with coverage analysis and gap identification"
---

# Test Execution

Run project test suites, analyze results, report coverage, and identify gaps.

## When to Use

- Running tests after code changes
- Checking test coverage for a module or feature
- Investigating test failures
- Identifying untested code paths

## Process

### 1. Discover

- Detect test framework from project config (pytest, jest, vitest, go test, etc.)
- Identify test files matching project conventions
- Determine available test commands from package.json, Makefile, pyproject.toml, etc.

### 2. Execute

Run tests using the project's configured runner:

```bash
# Use whatever the project defines -- examples:
pytest --tb=short -q
npm test
python -m app.cli.main greenlight --all
```

Options:
- **Targeted**: Run tests for specific file/module only
- **Full suite**: Run all tests
- **Coverage**: Add coverage flags if supported (--cov, --coverage)

### 3. Analyze Results

Parse test output for:
- Total tests: passed / failed / skipped / errors
- Failure details: file, test name, assertion, stack trace
- Coverage: line %, branch %, uncovered files

### 4. Report

```
## Test Results

### Summary
- Passed: X | Failed: Y | Skipped: Z | Errors: W
- Duration: Xs
- Coverage: XX% (lines) / XX% (branches)

### Failures (if any)
| Test | File | Error |
|------|------|-------|
| test_name | path/to/test.py:42 | AssertionError: expected X got Y |

### Coverage Gaps
- [file] — 0% covered, [reason it matters]
- [file:function] — untested branch at line N

### Recommendations
- [Priority fixes or missing test cases]
```

### 5. Failure Triage

For failures, provide quick triage:
- **Flaky**: Passes on retry, timing-dependent
- **Regression**: Was passing, now broken (check git blame)
- **New**: Test for new code that hasn't been fixed yet
- **Environment**: Works locally, fails in CI (or vice versa)

## Boundaries

**Will**: Run existing tests, report results, analyze coverage, identify gaps.
**Will not**: Write new tests, modify test framework config, or fix failing code (use `/sh:debug` for that).

## Next Step

For failures, use `/sh:debug` to investigate root cause. For gaps, create test tasks.
