# Agent Orchestration

How to decide what to delegate, who to delegate to, and how to run agents without wasting tokens or quality.

---

## Decision: delegate or do it yourself

If the target files are already in context and the change is ≤ 3–4 edits, do it directly. Delegating means the agent re-reads those files, paying initialization overhead with no benefit.

Delegate when:
- The task is large enough that keeping it out of the orchestrator's context is worth the overhead
- The task is clearly separable with a well-defined result
- You want parallelism across independent work

---

## Decision: subagent vs agent team

| Question | If yes → | If no → |
|---|---|---|
| Do agents need to talk to each other? | Team | Subagent |
| Does work span multiple files that could conflict? | Team (with workspaces) | Either |
| Is it just "fetch info and report back"? | Subagent | — |
| Do you want to monitor/steer agents in real time? | Team (split panes) | Subagent (background) |
| Is the task quick and focused (< 2 min)? | Subagent | — |
| Are there 3+ parallel tasks sharing patterns? | Team | — |

---

## Subagents

### Background vs foreground

- **Background** (`run_in_background: true`) — when you don't need the result before proceeding. You'll be notified when it completes.
- **Foreground** (default) — when you need the result to continue. Blocks until done.

### Parallel subagents

Launch multiple subagents in a single message (multiple Task tool calls). They run concurrently. Use for independent research queries, parallel test runs, or fetching from multiple sources.

### Sandbox constraints

Background subagents auto-deny file access outside the project directory. They cannot prompt for permissions. If a subagent needs to access files outside the project root:
- Use `/add-dir` to pre-approve the paths before launching
- Or use an agent team instead (teammates can prompt interactively)

---

## Agent teams

### Setup

Agent teams require `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` in settings (already enabled).

Split panes require running inside `tmux` before starting `claude`. Without tmux, teammates run in-process (cycle with `Shift+Down`).

### Team sizing

- 3–5 teammates for most tasks
- 5–6 tasks per teammate keeps everyone productive
- More teammates = more tokens, diminishing returns beyond 5

### Teammate models

Choose model based on task type:
- `haiku` — execution tasks where the plan is already provided (write code following a pattern, run tests, create fixtures)
- `sonnet` — tasks requiring judgment (code review, analysis, exploration, debugging, feature implementation with ambiguity)
- `opus` — complex tasks requiring deep reasoning or architectural decisions

### Parallel implementation with jj workspaces

When teammates need to write code in parallel, use jj workspaces for isolation. See `~/.config/agents/version-control.md` for workspace basics.

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

```
You are working in workspace /path/to/workspace. cd there and stay there.

1. jj workspace update-stale
2. jj describe -m "feat: ..."
3. [do the work]
4. Run lint/tests
5. jj bookmark create <name> -r @
6. jj git push -b <name> --allow-new
7. gh pr create --base <base-branch> --head <name> --title "..." --body "..."
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

---

## How to orchestrate

### Core principle: distill, don't spoonfeed

The orchestrator's job is to **think** — not to read files, not to write code.

A senior engineer doesn't read every file before giving a task to a junior. They know the architecture, describe the approach, set guardrails, and let the junior figure out the implementation details.

- Use your existing knowledge (memory, CLAUDE.md, conversation context) to form the plan
- Write a **method** (how to approach it), not a **solution** (exact code to paste)
- Let the executing agent read files, understand context, and write code — that's what it's for

### Model tiers

| Tier | Model | Role | When |
|---|---|---|---|
| Default | Sonnet | Orchestration, planning, most interactions | Always unless escalated |
| Execution | Haiku | Code writing, tests, fixtures (plan already provided) | Delegated implementation tasks |
| Analysis | Sonnet | Code review, debugging, exploration, judgment calls | Tasks requiring reasoning |
| Escalation | Opus | Novel architecture, complex debugging, hard design calls | User explicitly switches |

### Planning cost budget

- **0–2 file reads** for a plan in a mature project (use memory)
- **3–5 file reads** maximum for a plan involving unfamiliar code
- If you're reading 10+ files to plan, you're doing the agent's job

### Prompt structure for executing agents

```
## Task
[One sentence: what to do]

## Context
[Which file(s) to modify. What the module does — one sentence.]

## Approach
[Which pattern to follow. Reference existing code as example, don't paste it.]
[Key decisions: which library, which API, what function signature.]

## Guardrails
[What NOT to do. Common pitfalls. Interface constraints.]

## Verification
[How to check it worked: run tests, check output, etc.]

Read the target file(s) first to understand the current structure.
```

### What the agent owns

- Reading files to understand current code
- Writing the implementation
- Running tests or verification
- Reporting results

### What the orchestrator owns

- Deciding the approach
- Choosing libraries and patterns
- Breaking work into tasks
- Reviewing results (briefly — don't re-read all files)
- Re-delegating if something's wrong (with adjusted guidance, not by doing it)

---

## Anti-patterns

### Orchestrator over-reading
Reading 10+ files on expensive model before delegating to cheap model.
**Fix**: Use memory. If unknown, send one Explore agent (haiku) to report back.

### Spoonfeeding exact code
Pasting full file content and exact replacement code in the agent prompt.
**Fix**: Describe the change, reference a pattern, let the agent read and implement.

### Ad hoc debug scripts
Writing `python3 -c "import json; ..."` one-liners to inspect state.
**Fix**: Use existing CLI tools. If none exist, that's a task for an agent.

### Fixing agent output directly
Agent makes a mistake, orchestrator reads the file and fixes it.
**Fix**: Re-delegate with adjusted guidance. The fix costs the same but the orchestrator's context stays clean.

### Re-exploring a mature codebase
Reading the same core files every session when the architecture hasn't changed.
**Fix**: Keep memory updated. After the first few sessions, the orchestrator should know the codebase from memory alone.

### Delegating work already in context
Target files are already loaded. Delegating means the agent re-reads them at no benefit.
**Fix**: If the file is in context and the change is ≤ 3–4 edits, do it directly.

---

## Session hygiene

- One plan = one session. Don't mix planning + multi-round execution.
- If context > 2MB, you're doing too much in-session — delegate more.
- Keep orchestrator context clean: it should contain plans, decisions, and results — not file contents.

## Memory as exploration replacement

After the first few sessions in a project, memory should contain enough architectural context that the orchestrator never needs to re-read core files. Keep memory updated with:

- Module contracts (what each module expects/returns)
- Established patterns (naming, error handling, config loading)
- Library decisions and rationale
- File layout and responsibilities
