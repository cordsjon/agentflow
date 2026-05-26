---
name: sh-document
description: "Targeted documentation for components, functions, and APIs"
---

# Targeted Documentation

Generate focused documentation for specific components, functions, or APIs.
Not full project docs -- surgical, useful documentation for the thing you point at.

## When to Use

- Documenting a function, class, or module
- Generating API endpoint reference
- Adding inline docstrings/JSDoc
- Creating usage examples for a component

## Process

### 1. Analyze Target

- Read the component/function/API to document
- Identify: purpose, parameters, return values, side effects, error cases
- Find existing callers/consumers to understand usage patterns
- Check for existing docs that need updating vs. creating new

### 2. Choose Format

| Type | When | Output |
|------|------|--------|
| **inline** | Functions/classes | Docstrings, JSDoc, type annotations |
| **api** | HTTP endpoints | Method, path, params, request/response, errors |
| **component** | Modules/services | Purpose, interface, usage examples, dependencies |
| **guide** | How-to for a feature | Step-by-step with code examples |

### 3. Generate

Follow language/project conventions for doc format. Include:

- **What**: One-sentence purpose
- **Parameters**: Name, type, required/optional, description
- **Returns**: Type, description, edge cases
- **Errors**: What can go wrong, how errors surface
- **Example**: Minimal working usage

### 4. Validate

- All parameters documented?
- Return type accurate?
- Error cases covered?
- Example actually works?
- Consistent with existing project doc style?

## Output Examples

**Inline (Python)**:
```python
def process_batch(items: list[Item], limit: int = 500) -> BatchResult:
    """Process a batch of items with size validation.

    Args:
        items: Items to process. Must not be empty.
        limit: Maximum batch size. Exceeding raises BatchLimitError.

    Returns:
        BatchResult with processed count and any failures.

    Raises:
        BatchLimitError: If len(items) > limit.
        ValueError: If items is empty.
    """
```

**API endpoint**:
```
## POST /api/v1/items/batch

Process items in batch.

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| items | Item[] | yes | Items to process (max 500) |
| dry_run | bool | no | Validate without persisting |

**Success (200)**: `{ "processed": 42, "failures": [] }`
**Error (422)**: `{ "detail": "Batch exceeds 500 limit" }`
```

## Boundaries

**Will**: Generate documentation for specific targets, follow project conventions.
**Will not**: Create full project documentation, READMEs, or architecture docs unprompted.

## Next Step

Review generated docs for accuracy. Integrate into codebase.
