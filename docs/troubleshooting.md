# Troubleshooting

Use this page when the repo is installed but something is not behaving as
expected.

## First Response

Run these in order:

```bash
dotfiles status
dotfiles doctor
dotfiles services
```

This covers the most common cases:
- installed but not running
- symlink exists but app has stale state
- permissions missing
- runtime services not started

## Common Cases

### A config change did not apply

Classify the change first:

- changed `configs/*`
  no rebuild required; reload the relevant app if needed

- changed generated source
  run `dotfiles regen`

- changed `.nix`, `hosts/*`, `modules/*`, or `flake.nix`
  run `dotfiles rebuild`

### A tool is installed but behaves like it is using an old config

1. Verify the linked path points into this repo
2. Reload or restart the tool
3. Run `dotfiles doctor`

See `docs/verification.md` for tool-specific checks.

### Hammerspoon guide shortcut does nothing

Check:

1. Hammerspoon is actually running
2. `~/.hammerspoon` points to this repo
3. Hammerspoon has Accessibility permission
4. Hammerspoon console has no Lua load errors

Note:
- `dotfiles services` does not auto-launch Hammerspoon
- if you want the guide always available, start Hammerspoon through its own background/login path

### AeroSpace changes do not seem to apply

1. Confirm `~/.config/aerospace` points to this repo
2. Reload AeroSpace config or run `dotfiles services`
3. Verify the changed setting in the live config file

### Ghostty / Zellij / shell changes do not show up

- Ghostty: reload config
- Zellij: restart the session or the affected pane/session
- zsh: open a new shell, or source the relevant file only if you know the change is safe to source

### Rebuild succeeded but desktop behavior is wrong

Run:

```bash
dotfiles doctor
dotfiles services
```

If the issue came from the current branch and is unacceptable:

1. switch back to the previous known-good branch
2. run `dotfiles rebuild`
3. run `dotfiles services`

## Escalation Rule

If you do not know whether the problem is:
- config content
- generated drift
- rebuild-required policy
- runtime/app state

do not start changing mechanism files first. Use `status`, `doctor`, and the
verification checks before editing architecture code.
