# Orchestration & Token Efficiency

How to organize work between orchestrator and subagents to minimize cost and maximize quality.

## Core Principle: Distill, Don't Spoonfeed

The orchestrator's job is to **think** — not to read files, not to write code.

A senior engineer doesn't read every file before giving a task to a junior. They know the architecture, describe the approach, set guardrails, and let the junior figure out the implementation details. The orchestrator should work the same way:

- Use your existing knowledge (memory, CLAUDE.md, conversation context) to form the plan
- Write a **method** (how to approach it), not a **solution** (exact code to paste)
- Let the executing agent read files, understand context, and write code — that's what it's for

## Model Tiers

| Tier | Model | Role | When |
|---|---|---|---|
| Default | Sonnet | Orchestration, planning, most interactions | Always unless escalated |
| Execution | Haiku | File reads, code writing, tests, fixtures | Delegated tasks |
| Escalation | Opus | Novel architecture, complex debugging, hard design calls | User explicitly switches |

The orchestrator should almost never read files. If it needs to understand something, it should:
1. Check memory/CLAUDE.md first
2. If truly unknown, send one Explore agent (haiku) to report back
3. Only read a file directly if it's 1-2 files and the answer is quick

## Planning Phase

### What the plan should contain
- **Goal**: What we're building/fixing and why
- **Approach**: High-level method — what patterns to follow, what libraries to use
- **Task breakdown**: Independent units of work, each ownable by one agent
- **Guardrails**: What to avoid, interface constraints, library decisions
- **Acceptance criteria**: How to verify each task worked

### What the plan should NOT contain
- Full file contents (agents read files themselves)
- Exact code to write (agents figure out implementation)
- Detailed exploration of the codebase (use memory instead)

### Planning cost budget
- **0-2 file reads** for a plan in a mature project (use memory)
- **3-5 file reads** maximum for a plan involving unfamiliar code
- If you're reading 10+ files to plan, you're doing the agent's job

## Delegation Phase

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

### Agent should own
- Reading files to understand current code
- Writing the implementation
- Running tests or verification
- Reporting results

### Orchestrator should own
- Deciding the approach
- Choosing libraries and patterns
- Breaking work into tasks
- Reviewing results (briefly — don't re-read all files)
- Re-delegating if something's wrong (with adjusted guidance, not by doing it)

## Anti-Patterns

### 1. Orchestrator over-reading
Reading 10+ files on expensive model before delegating to cheap model.
**Fix**: Use memory. If unknown, send an Explore agent first.

### 2. Spoonfeeding exact code
Pasting full file content and exact replacement code in the agent prompt.
**Fix**: Describe the change, reference a pattern, let the agent read and implement.

### 3. Ad hoc debug scripts
Writing `python3 -c "import json; ..."` one-liners to inspect state.
**Fix**: Use existing CLI tools. If none exist, that's a task for an agent.

### 4. Fixing agent output directly
Agent makes a mistake, orchestrator reads the file and fixes it.
**Fix**: Re-delegate with adjusted guidance. The fix costs the same but the orchestrator's context stays clean.

### 5. Re-exploring a mature codebase
Reading the same core files every session when the architecture hasn't changed.
**Fix**: Keep memory updated. After the first few sessions, the orchestrator should know the codebase from memory alone.

### 6. Planning by exploring
Using Explore/Plan agents with many tool calls just to form a plan.
**Fix**: Plan from memory. Explore only when architecture has genuinely changed.

## Session Hygiene

- One plan = one session. Don't mix planning + multi-round execution.
- If context > 2MB, you're doing too much in-session — delegate more.
- If you hit a context continuation, the session was mismanaged.
- Keep orchestrator context clean: it should contain plans, decisions, and results — not file contents.

## Memory as Exploration Replacement

After the first few sessions in a project, memory should contain enough architectural context that the orchestrator never needs to re-read core files. Keep memory updated with:

- Module contracts (what each module expects/returns)
- Established patterns (naming, error handling, config loading)
- Library decisions and rationale
- File layout and responsibilities

This is the highest-leverage investment: every token spent updating memory saves 10x in future sessions.

## Future: Hooks

A pre-delegation hook could enforce these patterns automatically:
- Warn if orchestrator has >5 Read calls before first Agent call
- Warn if agent prompt contains >100 lines of pasted code
- Auto-inject project AGENTS.md into agent prompts
- Track token usage per session and flag sessions that exceed budget

Not implemented yet — noting for future iteration.
