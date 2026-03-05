# Research Tool Selection

## Web Search
- **Broad search (70+ engines)**: `searxng_web_search` - aggregates Google, Bing, DuckDuckGo, etc.
- **Fallback**: Built-in `WebSearch` - always works, no setup required

## URL Content Fetching
| Use Case | Tool | Output |
|----------|------|--------|
| Quick summary | `WebFetch` | LLM-compressed (~1-2k chars) |
| Full content for analysis | `crawl4ai_md` with `f=fit` | Clean markdown (~40-50k chars) |
| Raw unprocessed | `crawl4ai_md` with `f=raw` | Full HTML-to-markdown |

## Avoid
- `searxng_web_url_read` - includes navigation cruft, noisier than alternatives
- `duckduckgo_*` - aggressive rate limiting makes it unusable

## Browser Automation
- **Playwright MCP**: For JavaScript-heavy sites, form filling, screenshots
- **BrowserMCP**: Alternative browser automation

## Decision Flow
```
Need search results? → searxng_web_search
Need URL content?
  ├─ Just need gist → WebFetch
  ├─ Need full text → crawl4ai_md (f=fit)
  └─ Need to interact → playwright
```
