# Claude Appendix

Use Claude's native include mechanism from `~/.claude/CLAUDE.md`.

Claude-specific notes:
- `@path` imports are preferred over copying shared instructions.
- Keep `~/.claude/CLAUDE.md` as a thin loader, not the canonical source.
- Claude permissions and MCP allowlists belong in `~/.claude/settings.local.json`, not in the shared policy docs.
