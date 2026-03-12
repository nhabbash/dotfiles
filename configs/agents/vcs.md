# Version Control Guide

**Default: git.** Use jj only when you need stacked PRs or complex rebasing. For full jj reference, see `~/.config/agents/jj-full.md`.

## Git (default)

Standard git workflow. Claude knows this natively — no special instructions needed.

```bash
git checkout -b nassim/feature-name
# work, stage, commit
git add path/to/files
git commit -m "feat(scope): description"
git push -u origin nassim/feature-name
```

### Branch naming

Prefix with `nassim/` and use kebab-case: `nassim/graphql-subgraph-entities`, `nassim/fast-linting`.

### Commit conventions

- `feat(scope):` — new functionality
- `fix(scope):` — bug fix
- `chore(scope):` — tooling, config, cleanup

### Structuring commits

Use git's staging area to build logical commits:

```bash
git add src/graphql/entities/brand-kit/
git commit -m "feat(marketing-channels): add BrandKit GraphQL entity"
git add src/graphql/entities/insight/
git commit -m "feat(marketing-channels): add Insight GraphQL entity"
```

### Subagent isolation

Use `isolation: "worktree"` for subagents that write code. The worktree gives them a separate directory with their own branch. When they finish, merge or cherry-pick their branch back.

## When to use jj

Switch to jj when you need:
- **Stacked PRs** — multiple PRs in a dependency chain
- **Rebasing a stack** — jj auto-rebases descendants when you edit an ancestor
- **Conflict storage** — jj lets you continue working through conflicts

### Stacked PRs with jj

```bash
# First PR
jj new master@origin -m "add shared utilities"
# work...
jj bookmark create nassim/shared-utils -r @

# Second PR (on top of first)
jj new -m "add feature using utilities"
# work...
jj bookmark create nassim/feature -r @

# Push both
jj git push -b nassim/shared-utils -b nassim/feature --allow-new

# Create PRs
gh pr create --base master --head nassim/shared-utils --title "shared utils"
gh pr create --base nassim/shared-utils --head nassim/feature --title "feature"
```

### Rebasing a stack after base PR merges

```bash
jj git fetch --remote origin --branch master
jj bookmark delete nassim/shared-utils          # merged, remove
jj rebase -s <first-unmerged-change> -d master@origin
jj git push -b nassim/feature
```

### Adding changes to a PR under review

```bash
jj new <bookmark> -m "fix: address review comment"
# make fix
jj bookmark set <bookmark> -r @
jj git push -b <bookmark>
```

### Key jj rules (when using it)

1. **Always check position first:** `jj log -r '@'`
2. **`jj new` before each unit of work** — there's no staging, so declare intent upfront
3. **After any git tool runs:** `jj git import` to sync
4. **Paths are cwd-relative** in jj commands, not repo-root-relative
5. **`-s` for rebase** (moves change + descendants), not `-r` (moves only that change)

### Switching between features in jj

```bash
jj new master@origin -m "feat: other feature"     # start fresh
jj new <bookmark> -m "fix: continue on feature"   # resume existing
```

## For full jj reference

See `~/.config/agents/jj-full.md` for:
- Workspace coordination with parallel agents
- Merge protocols
- Conflict resolution
- Troubleshooting (bookmark conflicts, git interop, editor hangs)
- Importing work from other branches
