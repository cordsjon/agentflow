---
name: sh:select-tool
description: "Recommend the best MCP tool for a given task from available servers"
---

# MCP Tool Selection

Given a task description, recommend the optimal MCP tool from available servers.
Useful when multiple tools could work and you want the best fit.

## When to Use

- Unsure which MCP tool handles a task
- Multiple MCP servers available with overlapping capabilities
- Want to understand tool trade-offs before committing
- Need to route a subtask to the right tool

## Process

### 1. Understand the Task

Classify the operation:
- **Search/Read**: Finding information in code, docs, or web
- **Modify**: Editing files, creating content, making changes
- **Execute**: Running commands, tests, builds
- **Navigate**: Browser interaction, UI testing
- **Communicate**: GitHub, Linear, Notion, external services
- **Generate**: Images, diagrams, documents

### 2. Match Against Available Tools

Check available MCP servers and their capabilities:

| Category | Tools | Best For |
|----------|-------|----------|
| **Code intelligence** | vexp, LSP | Symbol search, impact analysis, call graphs |
| **Web browsing** | playwright, iwdp-mcp | Page interaction, testing, scraping |
| **Web search** | WebSearch, WebFetch | Information retrieval, research |
| **GitHub** | github MCP, gh CLI | Issues, PRs, code search, repo management |
| **Project mgmt** | Linear, Notion | Tasks, docs, team coordination |
| **Design** | Figma, Canva, Miro | Visual assets, diagrams, boards |
| **Media** | ComfyUI, alphabanana | Image generation, AI workflows |
| **Firebase** | firebase MCP | Backend services, hosting, auth |
| **Documentation** | Context7 | Library docs, API references |

### 3. Evaluate Fit

Score each candidate on:
- **Capability match**: Does it actually do what's needed?
- **Precision**: Native support vs. workaround?
- **Efficiency**: Token cost, round-trips, latency
- **Reliability**: Known limitations or failure modes?

### 4. Recommend

```
## Recommendation: [Task Description]

### Best tool: [tool name]
- Why: [1-2 sentences]
- Usage: [example invocation]

### Alternatives
- [tool 2]: [when you'd prefer this instead]
- [tool 3]: [when you'd prefer this instead]

### Avoid
- [tool X]: [why it's a poor fit despite seeming relevant]
```

## Decision Rules

- **Code search**: vexp `run_pipeline` over Grep/Glob when vexp is indexed
- **File editing**: Edit tool for targeted changes, Write for new files
- **Browser testing**: playwright for automation, iwdp-mcp for Safari/iOS
- **GitHub ops**: github MCP for structured operations, gh CLI for scripting
- **Research**: WebSearch for discovery, WebFetch for specific page content

## Boundaries

**Will**: Analyze task, match to available tools, explain trade-offs, recommend best option.
**Will not**: Execute the task itself, install new MCP servers, or modify tool configurations.

## Next Step

Use the recommended tool to execute the task.
