# Cursor Agent Appendix

Cursor Agent should consume the shared policy from `~/.config/agents/` plus this appendix.

Cursor-specific notes:
- Prefer repo-local `AGENTS.md` or Cursor rules when a project provides them.
- Keep Cursor IDE rule-generation or workspace-rule logic as a separate adapter layer.
- Do not duplicate the shared policy into multiple Cursor-specific files by hand.
