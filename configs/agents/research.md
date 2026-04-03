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
- **Preferred**: `searxncrawl_search` via tbox — SearXNG meta-search across 70+ engines. Activate `searxncrawl` first.
- **Fallback**: Built-in `WebSearch` — always available, no activation needed

## URL Content Fetching
| Use Case | Tool | Notes |
|----------|------|-------|
| Quick summary | `WebFetch` | Always available, LLM-compressed (~1-2k chars) |
| Full content for analysis | `searxncrawl_crawl` (activate `searxncrawl` first) | Clean markdown via crawl4ai (~40-50k chars) |

## Decision Flow
```
GitHub repo?          → gh CLI or git clone (never browser tools)
Need search results?  → hub_activate("searxncrawl") → searxncrawl_search
Need URL content?
  ├─ Just need gist   → WebFetch
  └─ Need full text   → hub_activate("searxncrawl") → searxncrawl_crawl
```
