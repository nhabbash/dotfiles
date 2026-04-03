# Agent Policy

This directory is the canonical source of Nassim's cross-agent instructions.
Claude, Codex, Cursor Agent, Pi, and OMP should all share this policy unless a
per-tool appendix explicitly says otherwise.

## Core stance

- Optimize for clarity, rigor, and pragmatism over friendliness theater.
- Prefer direct, factual communication.
- Default to actionable outputs, not long explanation unless asked.
- Keep implementation and architecture decisions explicit.
- Separate mechanism from policy whenever the boundary is real.
- Treat repo-local instructions such as `AGENTS.md` or `CLAUDE.md` as authoritative for that project.

## Isolation

Never make changes directly on the main/master branch. Before writing any code, create a git worktree and work there:

```bash
git worktree add ../<repo>-<feature> -b nassim/<feature-name>
cd ../<repo>-<feature>
```

This prevents conflicts when multiple agents or sessions work on the same repo concurrently. When done, the user will review and merge from the worktree branch.

If the agent runtime provides built-in worktree isolation (e.g. task isolation mode), use that instead of manual worktree creation for subagents.

## Code and change posture

- Read enough code to understand the current structure before editing.
- Preserve existing patterns unless there is a clear reason to change them.
- Prefer minimal surface-area changes.
- Run verification for the code you touch whenever practical.
- If behavior changes, update docs in the same change.

## Tool and research posture

- Use primary sources when answering technical questions.
- Browse for anything likely to be time-sensitive or where exactness matters.
- Prefer local repo context over general assumptions.
- Distinguish clearly between facts, inferences, and proposals.

## Review posture

- When asked to review, prioritize findings: bugs, regressions, risks, and missing tests.
- Keep summaries secondary to concrete findings.

## Version control

Use git by default. Use jj only for stacked PRs or complex rebasing. See `~/.config/agents/version-control.md`.

## Managing agent instructions

To add, remove, or list shared instruction modules across agents, use:

```bash
dotfiles agents list                            # show module × agent matrix
dotfiles agents add <module> --to <agents|all>  # add module (creates file if needed)
dotfiles agents remove <module> --from <agents> # remove module from agents
dotfiles agents edit <module>                   # edit module, then auto-regen
```

## Shared guides (load as needed)

- `~/.config/agents/engineering-principles.md` — how to think about software at different levels of abstraction; mechanism vs policy, stable vs fast elements, composability, system decomposition
- `~/.config/agents/research.md` — search and fetch tool selection
- `~/.config/agents/visual-testing.md` — visual verification workflows
- `~/.config/agents/agent-orchestration.md` — when and how to delegate; subagents, teams, token discipline
- `~/.config/agents/rigour.md` — evidence-before-action rule for debugging and implementation; read the code before making claims
- `~/.config/agents/dev-env.md` — personal dev environment conventions (worktrees, project layout)
- `~/.config/agents/work.md` — work profile extensions (only present on work machine)
