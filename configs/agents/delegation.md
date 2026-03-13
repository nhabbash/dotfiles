# Delegation Guide

When and how to delegate work to subagents or agent teams.

## Decision: subagent vs agent team

| Question | If yes → | If no → |
|---|---|---|
| Do agents need to talk to each other? | Team | Subagent |
| Does work span multiple files that could conflict? | Team (with workspaces) | Either |
| Is it just "fetch info and report back"? | Subagent | — |
| Do you want to monitor/steer agents in real time? | Team (split panes) | Subagent (background) |
| Is the task quick and focused (< 2 min)? | Subagent | — |
| Are there 3+ parallel tasks sharing patterns? | Team | — |

### Use subagents for

- Research and exploration (search code, read docs, fetch URLs)
- Running tests or lint checks
- Single focused tasks where only the result matters
- Anything where inter-agent communication adds no value

### Use agent teams for

- Parallel implementation across different files/modules
- Code review from multiple angles (security, performance, tests)
- Debugging with competing hypotheses
- Cross-layer work (frontend + backend + tests)
- Any task where agents benefit from sharing discoveries

## Agent teams

### Setup

Agent teams require `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` in settings (already enabled).

Split panes require running inside `tmux` before starting `claude`. Without tmux, teammates run in-process (cycle with `Shift+Down`).

### Team sizing

- 3-5 teammates for most tasks
- 5-6 tasks per teammate keeps everyone productive
- More teammates = more tokens, diminishing returns beyond 5

### Teammate models

Choose model based on the task type, not as a blanket default:
- `haiku` — execution tasks where the plan is already provided (write code following a pattern, run tests, create fixtures)
- `sonnet` — tasks requiring judgment (code review, analysis, exploration, debugging, feature implementation with ambiguity)
- `opus` — complex tasks requiring deep reasoning or architectural decisions

### Parallel implementation with jj workspaces

When teammates need to write code in parallel, use jj workspaces for isolation. See `~/.config/agents/jj.md` for workspace basics.

#### Setup (lead does this before spawning teammates)

```bash
PRIMARY="$(jj workspace root)"
REPO="$(basename "$PRIMARY")"
BASE_REV="<bookmark-or-revision>"

# 1. Create workspaces
jj workspace add "../${REPO}-task-a" -r "$BASE_REV"
jj workspace add "../${REPO}-task-b" -r "$BASE_REV"

# 2. Ensure .gitignore covers symlinks (node_modules/ only matches dirs, not symlinks)
grep -q '^node_modules$' .gitignore || sed -i '' 's|^node_modules/$|node_modules|' .gitignore

# 3. Symlink dependencies
for ws in "../${REPO}-task-a" "../${REPO}-task-b"; do
  ln -s "$PRIMARY/node_modules" "$ws/node_modules"
done

# 4. Register workspace paths for agent access
#    /add-dir <workspace-path> for each workspace
```

#### Teammate prompt template

Each teammate receives its workspace path and owns the full workflow:

```
You are working in workspace /path/to/workspace. cd there and stay there.

1. jj workspace update-stale
2. jj describe -m "feat: ..."
3. [do the work]
4. Run lint/tests
5. jj bookmark create <name> -r @
6. jj git push -b <name> --allow-new
7. gh pr create --base <base-branch> --head <name> --title "..." --label "PR: New Feature 🕹" --body "..."
   Labels: "PR: New Feature 🕹", "PR: Improvement 💅", "PR: Bugfix 🐛", "PR: Infrastructure 👷‍♀️", "PR: Dependencies 🛠"
8. Report: PR link, change ID, summary
```

#### Workspace rules for teammates

1. `cd` to workspace and never leave
2. Only modify your own `@`
3. Never run jj commands from the primary directory
4. Handle staleness with `jj workspace update-stale`
5. Own your full workflow: code, test, bookmark, push, PR

#### Cleanup (lead does this after all teammates finish)

```bash
jj workspace forget task-a
jj workspace forget task-b
rm -rf "../${REPO}-task-a" "../${REPO}-task-b"
```

### Shared file conflicts

When multiple teammates need to modify the same file (e.g., a barrel `index.ts`), each teammate should add only its own import. The lead resolves any jj conflicts after merging.

Alternatively, design the architecture to avoid shared files (e.g., auto-discovery instead of explicit imports).

## Subagents

### When to run in background vs foreground

- **Background** (`run_in_background: true`) — when you don't need the result before proceeding. You'll be notified when it completes.
- **Foreground** (default) — when you need the result to continue. Blocks until done.

### Parallel subagents

Launch multiple subagents in a single message (multiple Task tool calls). They run concurrently. Use for independent research queries, parallel test runs, or fetching from multiple sources.

### Sandbox constraints

Background subagents auto-deny file access outside the project directory. They cannot prompt for permissions. If a subagent needs to access files outside the project root:
- Use `/add-dir` to pre-approve the paths before launching
- Or use an agent team instead (teammates can prompt interactively)
