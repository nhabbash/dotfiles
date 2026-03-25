# Dev Environment Conventions

Personal conventions that apply across machines and projects.

## Git worktrees

Always use `.worktrees/<branch-name>` inside the repo for feature work.

```bash
git worktree add .worktrees/<branch-name> -b nassim/<branch-name>
```

**Before creating:** verify `.worktrees` is in `.gitignore`. If not, add it and commit before proceeding — otherwise worktree contents get tracked.

```bash
git check-ignore -q .worktrees || echo ".worktrees" >> .gitignore && git add .gitignore && git commit -m "chore: ignore .worktrees directory"
```

**After merging:** remove the worktree.

```bash
git worktree remove .worktrees/<branch-name>
# or if it has untracked files:
git worktree remove --force .worktrees/<branch-name>
```

**Never leave stale worktrees.** Run `git worktree list` to audit.
