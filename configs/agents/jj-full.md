# Jujutsu (jj) Version Control Guide

Instructions for using jujutsu instead of git. All version control operations must use jj commands.

## Why jujutsu

This project uses **stacked PR workflows**. Jujutsu handles this natively:

| Concept | Git | jj |
|---|---|---|
| Unit of work | Commit (immutable) | Change (mutable, stable ID) |
| Working state | Uncommitted changes | Working copy `@` (is a commit) |
| Staging | `git add` required | No staging, all changes in `@` |
| History rewriting | `git rebase -i` | `jj edit` + modify |
| Branches | Primary workflow | Bookmarks (just pointers) |
| Rebasing | Manual | Automatic when editing ancestors |
| Conflicts | Block progress | Stored in commit, can continue |

### Reading `jj log` output

```
@  vruxwpqt user 2025-12-19 feature/name    ← working copy
○  qwpmzvol user 2025-12-19 pr-repository   ← regular change
◆  master                                    ← immutable (from remote)
```

- `@` = working copy, `○` = change, `◆` = immutable, `×` = abandoned
- Change ID (e.g. `vruxwpqt`) is stable across rebases
- Bookmarks show after the timestamp

## Workflow Patterns

### Key mental model: bookmarks are branch tips

A bookmark points to the tip of a series of changes — like a git branch pointing to the latest commit. Multiple changes behind a bookmark = multiple commits on a branch. Use `jj new` to add changes, and the bookmark advances.

**Wrong approach** (single change, keep rewriting):
```bash
jj new -m "feat: add everything"
# write a lot of code
jj edit <same-change>     # reviewer asks for changes
# rewrite
jj edit <same-change>     # more changes
# rewrite again — history lost, force-push every time
```

**Right approach** (multiple changes, bookmark at tip):
```bash
jj new -m "add shared AI utilities"
# write code

jj new -m "add abuse-detection graph"
# write code

jj new -m "add controller endpoint"
# write code

# Bookmark points to the tip — PR shows 3 commits
jj bookmark set feature/abuse-detection -r @
jj git push -b feature/abuse-detection
```

Each `jj new` creates a small, functional step. The PR shows proper commit history. No force-pushing.

### Pattern 1: Building a feature (multiple changes, one PR)

```bash
jj new -m "add shared AI utilities"
# write code

jj new -m "add abuse-detection graph"
# write code

jj new -m "add controller endpoint"
# write code

# Create bookmark at the tip
jj bookmark create nassim/abuse-detection -r @
jj git push -b nassim/abuse-detection
gh pr create --base master --head nassim/abuse-detection --title "feat: abuse detection"
```

The PR shows 3 commits. Each is a logical step that compiles.

### After editing a lower PR in a stack

Auto-rebase handles textual conflicts but NOT semantic drift (renamed types, moved exports, changed interfaces). After changing a lower PR, always build from the top of the stack to catch broken imports or references:

```bash
# After editing a change in the middle of the stack
jj edit <top-bookmark>    # go to the tip
yarn build                # catch semantic drift
# fix any broken imports/references
jj git push -b <all-affected-bookmarks>
```

### Pattern 2: Stacked PRs (multiple bookmarks in a chain)

```bash
# First PR: utilities
jj new -m "add AI utilities"
# work...
jj bookmark create nassim/ai-utils -r @

# Second PR: graph (on top of utilities)
jj new -m "add abuse-detection graph"
# work...
jj bookmark create nassim/abuse-detection -r @

# Push both
jj git push -b nassim/ai-utils -b nassim/abuse-detection

# Create PRs
gh pr create --base master --head nassim/ai-utils --title "AI utilities"
gh pr create --base nassim/ai-utils --head nassim/abuse-detection --title "Abuse detection"
```

### Pattern 3: Adding changes to a PR under review

When you need to make changes to a PR, add a new change on top — don't rewrite existing changes.

```bash
# Add a fix on top of the PR
jj new <bookmark> -m "fix: address review comment"
# make the fix

# Move the bookmark forward
jj bookmark set <bookmark> -r @

# Push — the PR gains a new commit, no force-push needed
jj git push -b <bookmark>
```

### Pattern 4: When to use `jj edit` (amending in place)

Only for trivial fixes to the most recent change that don't affect descendants:
- Fix a typo in a string
- Rename a variable in the same file
- Fix a lint warning

**Never use `jj edit` for:**
- Structural changes (renaming types, moving files, changing interfaces)
- Changes that affect imports in other files
- Anything in a change that has descendants in a stack

For structural changes, use `jj new` to create a new change on top.

### Pattern 6: Splitting a change

```bash
jj edit <change-id>
jj split                    # interactive: select which changes go in first commit
jj split file1.ts file2.ts  # or split by file

# Create bookmarks for each part
jj bookmark create pr-part1 -r <first-change-id>
jj bookmark create pr-part2 -r <second-change-id>
```

### Pattern 7: Syncing with master

**Critical: Always fetch before rebasing.** The local `master@origin` is a snapshot from the last fetch — it does NOT auto-update.

```bash
# 1. ALWAYS fetch first
jj git fetch --remote origin --branch master

# 2. Rebase stack onto latest master (use -s, not -r)
jj rebase -s <bottom-change-id> -d master@origin

# 3. Push all affected bookmarks
jj git push -b <bookmark-1> -b <bookmark-2>
```

**`-s` vs `-r` flags:**
- `-s` (source): Moves the change **and all descendants**. Use this for stacks.
- `-r` (revision): Moves **only that single change**, orphaning descendants. Rarely what you want.

### Pattern 8: Handling merged PRs in a stack

Stacked PRs merge one by one (bottom first). **Before rebasing, check which PRs are already merged. Only rebase from the first unmerged change onwards.**

```bash
# 1. Fetch latest
jj git fetch --remote origin --branch master

# 2. Check which PRs are merged
gh pr view <PR-number> --json state --jq '.state'

# 3. Delete merged bookmark locally
jj bookmark delete <merged-bookmark>

# 4. Delete merged branch on GitHub (if not auto-deleted)
git push origin --delete <merged-branch-name>

# 5. Rebase only unmerged changes onto master
jj rebase -s <first-unmerged-change-id> -d master@origin

# 6. Push only unmerged bookmarks
jj git push -b <unmerged-bookmark-1> -b <unmerged-bookmark-2>
```

**Never rebase or push bookmarks for already-merged PRs** — this recreates deleted branches on GitHub.

## Workspaces

Workspaces let you have multiple working copies of the same repo. Each has its own directory and checked-out change, but they share the same commit history. The shared store is lock-free and concurrent-safe by design.

```bash
# Create a workspace branching from a revision
jj workspace add ../repo-taskname -r <revision>

# Symlink dependencies (avoids reinstalling)
ln -s "$(jj workspace root)/node_modules" ../repo-taskname/node_modules
echo "node_modules" >> ../repo-taskname/.git/info/exclude

# List workspaces
jj workspace list

# Handle staleness (normal when other workspaces modify the repo)
jj workspace update-stale

# Clean up
jj workspace forget <name>
rm -rf ../repo-taskname
```

**Important:** `auto-track` must be `"all()"` (the jj default). If set to `"none"`, new files won't be committed. Check with `jj config list snapshot.auto-track`.

### Parallel Agent Coordination with Workspaces

When multiple agents work on the same codebase in parallel, use workspaces for isolation and a serialized merge protocol to avoid conflicts.

#### Setup (orchestrator)

```bash
PRIMARY="$(jj workspace root)"
REPO="$(basename "$PRIMARY")"

# Create one workspace per agent, branching from current revision
jj workspace add "../${REPO}-agent-a" -r @
jj workspace add "../${REPO}-agent-b" -r @
jj workspace add "../${REPO}-agent-c" -r @

# Symlink dependencies if needed
for ws in "../${REPO}-agent-a" "../${REPO}-agent-b" "../${REPO}-agent-c"; do
  [ -d "$PRIMARY/node_modules" ] && ln -s "$PRIMARY/node_modules" "$ws/node_modules"
done
```

#### Agent workflow (each agent independently)

```bash
cd /path/to/workspace

# 1. Handle staleness
jj workspace update-stale

# 2. Work — make changes, create logical commits
jj describe -m "feat: description of work"
# ... do work ...
jj new -m "fix: additional change"
# ... more work ...

# 3. When done: create a bookmark at the tip
jj bookmark create agent-a-result -r @

# 4. Run tests
make check  # or equivalent

# 5. Signal ready to merge (report bookmark name to orchestrator)
```

#### Merge protocol (serialized, race-based)

Agents finish at different times. The first to finish merges first. Subsequent agents rebase onto the updated main before merging.

```
Agent A finishes first:
  1. A rebases onto main:     jj rebase -s <first-change> -d main
  2. A resolves conflicts:    edit files, jj squash/new as needed
  3. A runs tests:            make check
  4. A merges into main:      (orchestrator squashes or merges)

Agent C finishes next:
  1. C rebases onto main:     jj rebase -s <first-change> -d main
     (main now includes A's changes — C resolves any conflicts)
  2. C runs tests:            make check
  3. C merges into main

Agent B finishes last:
  1. B rebases onto main:     jj rebase -s <first-change> -d main
     (main now includes A+C — B resolves any conflicts)
  2. B runs tests:            make check
  3. B merges into main
```

**Key rules:**
- Only ONE agent merges at a time (mutex). The orchestrator coordinates the order.
- Each agent rebases onto the LATEST main before merging (picks up all prior merges).
- The agent that rebases is responsible for conflict resolution — it knows its own changes best.
- Tests must pass AFTER rebase, BEFORE merge. If tests fail, the agent fixes before merging.
- The orchestrator does NOT resolve conflicts — agents own their merges.

#### Orchestrator merge commands

```bash
# After agent A signals ready:
cd "$PRIMARY"
jj workspace update-stale

# Option 1: Merge the bookmark (creates merge commit)
jj new @ agent-a-result -m "merge: agent A work"

# Option 2: Rebase onto main (linear history)
jj rebase -s agent-a-result -d @
jj new -m "merge point"

# Clean up workspace
jj workspace forget agent-a
rm -rf "../${REPO}-agent-a"
```

#### When NOT to use parallel workspaces

- Changes are deeply interconnected (same files, dependent interfaces)
- The task is small enough that parallelism adds more overhead than it saves
- Only one logical unit of work (single agent is simpler)

Use parallel workspaces when work is truly independent: different packages, frontend vs backend, separate features, different adapters.

For using workspaces with agent teams, see `~/.config/agents/delegation.md`.

## Agent Instructions

### Critical: verify position before every task

**jj has no passive branch isolation.** In git, being "on a branch" protects you. In jj, `@` is just wherever you last left it. Always verify before working:

```bash
# MANDATORY first step before any work
jj log -r '@'    # Where am I? What bookmark? What parent?
```

If `@` is not where you expect, navigate first. Never assume.

### Before making any changes

**Always identify the target first:**

```bash
# 1. Check which bookmark the PR uses
gh pr view <PR-number> --json headRefName --jq '.headRefName'

# 2. Check the change tree
jj log -r 'ancestors(<bookmark>, 5)'

# 3. Navigate to the right place — DEFAULT to jj new, not jj edit
jj new <bookmark> -m "fix: ..."
```

Never edit from wherever `@` happens to be — always navigate first.

### Switching between features

In git you'd `git checkout <branch>`. In jj, use `jj new`:

```bash
# Switch to work on a different feature
jj new <target-bookmark> -m "feat: next thing"

# Or start fresh from master
jj new master@origin -m "feat: new feature"
```

The files on disk change, `@` moves, previous work stays on its bookmark. This is clean isolation — but you must actively navigate, it won't protect you passively.

### Structuring commit history

**jj auto-tracks everything into `@`. There is no staging area.** Structure commits by declaring intent upfront with `jj new`, not by splitting after the fact.

```bash
# WRONG: do a bunch of work, then try to untangle
# ... write code for feature A and feature B ...
jj split  # painful, error-prone

# RIGHT: declare each unit before starting it
jj new -m "feat: add BrandKit entity"
# only work on BrandKit files
jj new -m "feat: add Insight entity"
# only work on Insight files
```

**If you forget and need to split:** `jj squash --into` and `jj split` work, but note that jj uses **cwd-relative paths**, not repo-root paths.

### Subagent work

**Always prepare a change for the subagent before launching it**, or use `isolation: "worktree"`. Otherwise the subagent's files land in whatever `@` currently is, mixing with unrelated work.

```bash
# Option 1: Pre-create the change
jj new -m "feat: add AnalyticsEvent entity"
# THEN launch the subagent — its work lands cleanly in this change

# Option 2: Use worktree isolation (for background agents)
# Pass isolation: "worktree" to the Agent tool
```

### Importing work from other branches

Use sequential `jj new` + `jj restore`, not multi-parent merges (those create merge commits that don't work for linear PR history).

```bash
# For each branch to import:
jj new -m "feat: description of this branch's work"
jj restore --from <branch>@origin -- path/to/file1 path/to/file2
# repeat for next branch
```

### When user asks to "commit"

```bash
jj new -m "Description"      # commits current @ and creates next change
jj describe -m "New message"  # update description of current @
```

Do **not** use `git commit`. Always use jj.

### For making changes (features, fixes, refactors)

**Always use `jj new` for each logical step.** Each change should be small, compilable, and represent one step in the work. Move the bookmark forward with `jj bookmark set <name> -r @` after each change.

Do NOT accumulate all work into a single change via `jj edit`. This loses history and forces destructive force-pushes.

### For addressing review comments

1. Check the PR's bookmark: `gh pr view <PR> --json headRefName`
2. `jj new <bookmark> -m "fix: address review"` — add a new change on top
3. Make the fix
4. `jj bookmark set <bookmark> -r @` — move bookmark forward
5. `jj git push -b <bookmark>` — push (no force-push needed)

## Git interop

jj and git share the same `.git` store. Some tools (Claude Code's `isolation: "worktree"`, git hooks, external scripts) modify git directly. jj won't see those changes until you sync.

### After any tool touches git directly

```bash
jj git import    # re-read .git, pick up new branches/commits
```

Run this after:
- A subagent finishes with `isolation: "worktree"` (uses git worktree, not jj workspace)
- Any script that runs `git commit`, `git branch`, or `git push`
- Manual git commands

### Integrating a git worktree agent's work

When a subagent uses `isolation: "worktree"`, it creates a git worktree and makes git commits there. To bring that work into jj:

```bash
# 1. Import the new git branch into jj
jj git import

# 2. Create a jj change from the branch
jj new <branch-name> -m "integrate: agent work"

# 3. Or cherry-pick files from it
jj new -m "feat: agent's work"
jj restore --from <branch-name> -- path/to/files
```

### When in doubt

If jj behaves unexpectedly (missing commits, stale bookmarks, unexpected conflicts), `jj git import` is a safe first step — it's read-only and just syncs jj's view with git's state.

## Troubleshooting

### "Change has conflicts"

jj stores conflicts in the change itself. Edit the conflict markers in files, then continue working — no special resolve command needed.

### "Bookmark is conflicted" / "references unexpectedly moved"

Both mean the remote bookmark moved (GitHub merge commit, CI rebase, someone else pushed).

```bash
jj git fetch                                # sync with remote
jj bookmark list | grep conflicted          # find conflicted bookmarks
jj log -r 'change_id(<change-id>)'          # see local vs remote versions
jj abandon <unwanted-remote-commit>         # abandon the one you don't want
jj bookmark set <bookmark-name> -r <id>     # set to your version
jj git push -b <bookmark-name>              # force-update remote
```

**Common cause:** GitHub's "Update branch" button creates merge commits. Always prefer rebasing.

### Commands hang waiting for editor

`jj squash`, `jj describe`, `jj split` and others open an editor if no `-m` flag is given. Always pass `-m "message"` to avoid hanging. For `jj squash --into`, use `-m` to set the resulting commit's description.

### Push fails with "--allow-new deprecated"

Use `jj bookmark track <name> --remote=origin` before pushing, or use `--allow-new` (still works, just warns).

## Quick Reference

```bash
# Work
jj new -m "msg"                # Create new change
jj edit <id>                   # Work on specific change
jj describe -m "msg"           # Update description
jj squash                      # Squash into parent
jj split                       # Split change

# View
jj log                         # See change tree
jj show <id>                   # Show specific change
jj diff                        # Show current changes

# Bookmarks
jj bookmark create name -r @   # Create bookmark
jj bookmark set name -r @      # Move bookmark
jj bookmark delete name        # Delete bookmark

# GitHub
jj git fetch --remote origin --branch master  # Fetch latest
jj git push -b name                           # Push bookmark
jj git push -b a -b b -b c                    # Push multiple

# Rebase (always fetch first!)
jj git fetch --remote origin --branch master
jj rebase -s <id> -d master@origin

# Workspaces
jj workspace add ../path -r <rev>    # Create workspace
jj workspace list                    # List all workspaces
jj workspace forget <name>           # Remove workspace tracking
jj workspace update-stale            # Update stale working copy

# Safety
jj undo                        # Undo last operation
jj abandon <id>                # Abandon a change
```
