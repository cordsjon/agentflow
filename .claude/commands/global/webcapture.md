---
name: webcapture
description: "Token-efficient web page capture for LLM analysis. Escalation ladder: curl → WebFetch → curl+convert → Playwright (last resort). Use when you need page content, API data, or web verification."
---

# /webcapture — Token-Efficient Web Capture

**Playwright is the last resort, not the default.** Its 21-tool schema costs ~2K tokens just to load.

## Escalation Ladder (cheapest first)

### 1. `curl` + pipe — ~20 tokens overhead
Raw HTML. Best for spot-checks and API endpoints.

```bash
# Check if a string exists on a page
curl -s "https://example.com" | grep -o "deploy-status"

# JSON API — skip HTML entirely
curl -s "https://api.example.com/data" | jq '.results[]'

# Health check
curl -sf "http://localhost:9001/healthz" && echo "UP" || echo "DOWN"

# Status code only
curl -s -o /dev/null -w "%{http_code}" "https://example.com"
```

### 2. `WebFetch` tool — ~50-100 tokens overhead ⭐ DEFAULT
Built into Claude Code. Returns **clean markdown** optimized for LLM consumption.

- Strips navigation/chrome/ads
- Returns readable text structure
- Works on localhost URLs
- No browser process, no schema bloat
- 5-10x smaller than raw HTML of same page

**Use for:** Full page content analysis, reading articles, extracting structured data from web pages, comparing page versions, analyzing competitor sites.

```
WebFetch(url="https://example.com")
```

### 3. `curl` + HTML-to-text — ~30 tokens overhead
When you need text but WebFetch isn't available or you want shell-pipeline control.

```bash
# Using python (always available)
curl -s "https://example.com" | python3 -c "
import sys, html.parser, io
class S(html.parser.HTMLParser):
    def __init__(s): super().__init__(); s.t=[]; s.skip={'script','style','head'}; s.d=0
    def handle_starttag(s,t,a): s.d += t in s.skip
    def handle_endtag(s,t): s.d -= t in s.skip
    def handle_data(s,d):
        if not s.d: s.t.append(d.strip())
p=S(); p.feed(sys.stdin.read()); print('\n'.join(l for l in p.t if l))
"

# Using lynx (if installed)
curl -s "https://example.com" | lynx -stdin -dump -nolist

# Using pandoc (if installed)
curl -s "https://example.com" | pandoc -f html -t plain
```

### 4. `curl` + specific extraction — ~25 tokens overhead
When you know exactly what you need from the HTML.

```bash
# Extract all links
curl -s "https://example.com" | grep -oP 'href="\K[^"]+'

# Extract title
curl -s "https://example.com" | grep -oP '<title>\K[^<]+'

# Extract meta description
curl -s "https://example.com" | grep -oP 'name="description" content="\K[^"]+'

# Extract JSON-LD structured data
curl -s "https://example.com" | grep -oP '<script type="application/ld\+json">\K[^<]+' | python3 -m json.tool
```

### 5. Playwright — LAST RESORT (~2K+ tokens schema load)
Only when you **must** click, fill forms, or verify visual layout.

**Legitimate Playwright uses:**
- OAuth flows that require clicking buttons
- SPAs where content is JS-rendered and not in raw HTML
- Visual regression testing (screenshots)
- Form submission requiring interaction
- Cookie extraction from authenticated sessions

**Never use Playwright for:**
- Reading page content (use WebFetch)
- Checking if a page loads (use curl)
- Extracting text from a URL (use WebFetch)
- API calls (use curl)
- Health checks (use curl)

## Decision Matrix

| Need | Tool | Cost |
|------|------|------|
| "Does this URL return 200?" | `curl -s -o /dev/null -w "%{http_code}"` | ~20 tok |
| "What's on this page?" | `WebFetch` | ~50-100 tok |
| "Does this page contain X?" | `curl -s url \| grep X` | ~20 tok |
| "Get JSON from API" | `curl -s url \| jq` | ~20 tok |
| "Read this article for analysis" | `WebFetch` | ~50-100 tok |
| "Click a button / fill a form" | Playwright | ~2K+ tok |
| "Screenshot for visual check" | Playwright | ~2K+ tok |
| "Extract text, no WebFetch" | `curl \| python3 strip` | ~30 tok |

## Token Math

| Format | Typical page | Tokens |
|--------|-------------|--------|
| Raw HTML | Full page | 20-50K |
| WebFetch markdown | Same page | 2-8K |
| curl + grep match | One line | 10-50 |
| curl status code | 3 digits | ~20 |

**WebFetch's markdown conversion = 5-10x free compression.**

## Arguments

If invoked with a URL argument, immediately fetch it with WebFetch:
```
/webcapture https://example.com
```

If invoked with `--curl` flag, use curl instead:
```
/webcapture --curl https://example.com
```

ARGUMENTS: $ARGUMENTS
