# Research Tool Selection

## GitHub Repos
For researching GitHub repositories, **never use browser tools**. Clone or use `gh`.

- **Preferred**: `git clone` into `/tmp` — gives full repo locally for reading, grepping, exploring
- **Lightweight** (just need README or quick metadata): `gh repo view owner/repo`, `gh api`

| Use Case | Tool |
|----------|------|
| Any multi-file analysis | `git clone /tmp/<repo>` then read locally |
| Just the README | `gh repo view owner/repo` |
| Issues, PRs, releases | `gh issue list`, `gh pr list`, `gh release list` |
| Repo metadata | `gh api repos/owner/repo` |

## Web Search
- **Preferred**: use tbox first.
  1. `tbox_hub_activate(server_name="searxng")`
  2. `tbox_hub_describe(server_name="searxng")` to confirm the currently exposed tool names
  3. Use the exposed SearXNG search tool (currently `tbox_search_searxng_searxng_web_search`)
- **Fallback**: built-in `WebSearch` only if tbox is unavailable or the exposed tool is not callable in this session

## URL Content Fetching
| Use Case | Tool | Notes |
|----------|------|-------|
| Quick summary | `WebFetch` | Always available, LLM-compressed (~1-2k chars) |
| Full content for analysis | tbox `crawl4ai` server | Activate `crawl4ai`, inspect with `tbox_hub_describe`, then use the exposed crawl tool (currently `tbox_search_crawl4ai_crawl`) |

## tbox discovery flow
Use the user's tbox catalog before built-in web tools.

```
Need search results?
  → tbox_hub_activate(server_name="searxng")
  → tbox_hub_describe(server_name="searxng")
  → use exposed search tool

Need URL content?
  ├─ Just need gist
  │   → WebFetch
  └─ Need full text / markdown / extraction
      → tbox_hub_activate(server_name="crawl4ai")
      → tbox_hub_describe(server_name="crawl4ai")
      → use exposed crawl tool
```

## If tbox activation succeeded but tools still are not callable
This can happen when the MCP client has stale direct-tool state.

Try, in order:
1. `mcp({ connect: "tbox" })` to refresh the live tool inventory
2. Re-check available tools with `mcp({ server: "tbox" })` or `tbox_hub_describe(...)`
3. If the exposed tools still do not appear, restart pi and retry

Do not silently fall back to built-in tools when the user explicitly has a preferred tbox toolchain available.
