# Research Tool Selection

## Web Search
- **Preferred**: `searxncrawl_search` via tbox — SearXNG meta-search across 70+ engines. Activate `searxncrawl` first.
- **Fallback**: Built-in `WebSearch` — always available, no activation needed

## URL Content Fetching
| Use Case | Tool | Notes |
|----------|------|-------|
| Quick summary | `WebFetch` | Always available, LLM-compressed (~1-2k chars) |
| Full content for analysis | `searxncrawl_crawl` (activate `searxncrawl` first) | Clean markdown via crawl4ai (~40-50k chars) |

## Decision Flow
```
Need search results? → hub_activate("searxncrawl") → searxncrawl_search
Need URL content?
  ├─ Just need gist → WebFetch
  └─ Need full text → hub_activate("searxncrawl") → searxncrawl_crawl
```
