# Dotfiles

Personal dev environment managed with Nix + home-manager for Mac and Linux.

## How it works

Configs live in `configs/` and are **symlinked** into place by home-manager on every rebuild. Editing a file in `configs/` is the same as editing `~/.config/zellij/config.kdl` — they're the same file via symlink. No rebuild needed for config changes, only for nix changes.

```
configs/zsh/        → ~/.config/zsh/
configs/zellij/     → ~/.config/zellij/
configs/kitty/      → ~/.config/kitty/
configs/ghostty/    → ~/.config/ghostty/ (+ Library/Application Support on macOS)
configs/git/        → ~/.gitconfig
configs/agents/     → ~/.config/agents/
configs/claude/     → ~/.claude/
```

`~/.zshrc` is a **local, untracked file** (created by bootstrap). Add machine-specific one-off shell config there or in `~/.zshrc.local`.

---

## First-time setup

```bash
git clone git@github.com:nhabbash/dotfiles.git ~/Development/dotfiles
cd ~/Development/dotfiles
bash scripts/dotfiles.sh bootstrap [hostname]
```

Hostnames: `personal-macbook` (default on macOS) · `work-macbook` · `linux-server` · `linux-desktop`

Bootstrap will:
1. Install Nix if missing (then ask you to restart shell and re-run)
2. Back up or delete any existing files that nix will manage
3. Build and activate the nix configuration
4. Create `~/.zshrc`

---

## Daily use

All commands are available as the `dotfiles` alias once your shell is set up.

| Command | What it does |
|---|---|
| `dotfiles pull` | Pull remote changes, rebuild only if nix files changed |
| `dotfiles push [message]` | Commit all changes and push |
| `dotfiles status [hostname]` | Show repo state and local service status |
| `dotfiles rebuild [hostname]` | Force a full nix rebuild |
| `dotfiles services [hostname]` | Start/reload local desktop services after setup |
| `dotfiles doctor [hostname]` | Diagnose setup, links, installs, and service health |
| `rebuild` | Shorthand alias for `dotfiles rebuild` |

---

## Workflows

### Changing a config (zsh, zellij, ghostty, kitty…)

Just edit the file in `configs/`. No rebuild needed — the symlink means it takes effect immediately (or on next shell start for zsh).

```bash
# Example: tweak zellij layout
vim configs/zellij/layouts/default.kdl

# Then push when happy
dotfiles push "zellij: adjust layout"
```

### Changing nix config (packages, plugins, system settings)

Edit the `.nix` files in `modules/` or `hosts/`, then rebuild:

```bash
vim modules/packages.nix
dotfiles rebuild
# or just: rebuild
```

### Syncing to another machine

```bash
# On the other machine — pull and rebuild if nix changed
dotfiles pull
```

`dotfiles pull` will abort if you have uncommitted local changes. You'll see a warning at login too. Commit or push first:

```bash
dotfiles status       # see what's dirty
dotfiles push         # commit and push, then pull on the other machine
```

### Resolving a conflict between machines

If you edited the same file on two machines before syncing:

```bash
# Push the current machine's changes first
dotfiles push "my local changes"

# On the other machine, if pull fails with conflicts:
git -C ~/Development/dotfiles status      # see conflicting files
# Edit the files to resolve, then:
dotfiles push "merge: resolve conflict"
```

### Starting local desktop services

On macOS, `dotfiles rebuild` and `dotfiles bootstrap` now finish by starting the local desktop apps that make the environment usable right away. You can also run that step manually:

```bash
dotfiles services
```

Today that starts or reloads:
- AeroSpace
- Hammerspoon
- Übersicht only when the current profile should use it

### Checking what is ready

Use the quick snapshot when you want to know what is configured and what is actually running:

```bash
dotfiles status
```

Use the diagnostic pass when you want explicit problems called out:

```bash
dotfiles doctor
```

On macOS, these commands currently check:
- git dirtiness in the dotfiles repo
- whether AeroSpace, Hammerspoon, and Übersicht are installed
- whether the relevant apps are running
- whether `~/.hammerspoon` is linked
- whether Hammerspoon has an Accessibility permission entry

### Adding a new tool/config

1. Add the config files under `configs/<tool>/`
2. Add a symlink entry in `modules/default.nix` (in the `configLinks` map)
3. Add the package in `modules/packages.nix` if needed
4. Run `dotfiles rebuild`

### Keeping zshrc local

`~/.zshrc` is not tracked. For experiments or local-only shell config use:
- `~/.zshrc.local` — sourced automatically, never tracked
- `configs/zsh/personal.zsh` or `configs/zsh/work.zsh` — tracked, machine-profile specific

### Updating nix flake inputs

```bash
nfu          # alias for: nix flake update ~/Development/dotfiles
rebuild      # apply updated inputs
```

### Garbage collecting old nix generations

```bash
ngc          # alias for: nix-collect-garbage -d && nix store optimise
```

---

## Zsh config layout

| File | Purpose | Needs rebuild? |
|---|---|---|
| `configs/zsh/core.zsh` | PATH, Homebrew, SSH, keybindings | No |
| `configs/zsh/aliases.zsh` | All aliases | No |
| `configs/zsh/functions.zsh` | Shell functions | No |
| `configs/zsh/claude.zsh` | Claude Code env vars | No |
| `configs/zsh/zellij.zsh` | Zellij tab naming + tmux shim | No |
| `configs/zsh/personal.zsh` | Personal machine overrides | No |
| `configs/zsh/work.zsh` | Work machine overrides | No |
| `modules/shell/zsh.nix` | Plugins, oh-my-zsh, history settings | **Yes** |
| `~/.zshrc.local` | Local experiments, untracked | No |
