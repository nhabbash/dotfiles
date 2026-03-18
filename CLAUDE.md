# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Bootstrap a new machine (installs Nix, builds system, creates symlinks)
bash scripts/dotfiles.sh bootstrap [hostname]

# Rebuild after Nix changes
bash scripts/dotfiles.sh rebuild [hostname]
# or once bootstrap is done:
rebuild

# Regenerate derived config
dotfiles regen

# Verify repo integrity and drift
dotfiles check [hostname]

# Install explicit external assets
dotfiles assets [hostname]

# Capture a pre/post cutover snapshot
dotfiles snapshot [hostname]

# Run snapshot + integrity checks before switching
dotfiles preflight [hostname]

# Pull latest and auto-rebuild only if Nix files changed
dotfiles pull

# Commit and push all changes
dotfiles push [message]

# Show uncommitted changes and runtime state
dotfiles status

# Enter dev shell (provides nixfmt)
nix develop
```

**Hostnames:** `personal-macbook` (default), `work-macbook`, `linux-server`, `linux-desktop`

## Architecture

This repo uses **Nix Flakes + nix-darwin + home-manager** to declaratively manage the system. There are two tiers of configuration with different edit latency:
This repo also has explicit regeneration and runtime layers; see `docs/architecture.md`.

### Instant (no rebuild needed)
Files in `configs/` are **symlinked** into place by home-manager activation. Editing them takes effect immediately.

Key symlink targets:
- `configs/zsh/` → `~/.config/zsh/` (shell config split across `core.zsh`, `aliases.zsh`, `functions.zsh`, `work.zsh`, `personal.zsh`, `claude.zsh`, `zellij.zsh`)
- `configs/git/config` → `~/.gitconfig`
- `configs/nvim/` → `~/.config/nvim/` (LazyVim)
- `configs/zellij/` → `~/.config/zellij/`
- `configs/ghostty/shaders/` → `~/.config/ghostty/shaders/`
- `configs/aerospace/` → macOS tiling WM config
- `configs/hammerspoon/` → macOS automation
- `configs/agents/` → `~/.config/agents/` (Claude agent definitions)
- `configs/claude/` → `~/.claude/` (Claude Code config)

### Requires rebuild
Editing `.nix` files requires running `rebuild` or `dotfiles rebuild`:
- `flake.nix` — inputs/outputs, supported hosts
- `modules/default.nix` — symlink mappings, home-manager config
- `modules/packages.nix` — installed CLI packages
- `modules/shell/zsh.nix` — zsh plugins and history settings
- `modules/macos/` — macOS system preferences (keyboard, dock, finder)
- `hosts/*.nix` — per-machine overrides

## Multi-machine Strategy

Each hostname gets its own flake output in `flake.nix`. Per-machine differences live in `hosts/<hostname>.nix`. Shared configuration lives in `modules/` and `hosts/common.nix`.

Machine-local files that are intentionally untracked: `~/.zshrc`, `~/.zshrc.local`, `~/.gitconfig.local` (work email/GPG key).

## Scripts

- `scripts/dotfiles.sh` — Main entry point for bootstrap/rebuild/regen/check/services/doctor/pull/push/status
- `scripts/lib.sh` — Shared helpers: colored output, progress tracking, log parsing
- `scripts/generated/` — Generators for derived config such as keymap sync
- `scripts/experiments/` — Mutable experimental tools such as CRT shader workflows
- `scripts/crt-cycle` — Stable wrapper for the CRT preset explorer
- `scripts/crt-tune` — Stable wrapper for the parameterized CRT shader generator

## Further Reading

- `docs/architecture.md`
- `docs/operations.md`
- `docs/hosts.md`
- `docs/adding-tools.md`
- `docs/cutover.md`

## Notable Configs

- **Zellij** (`configs/zellij/`) — Terminal multiplexer; `zellij.zsh` handles tab naming and tmux-shim integration
- **Ghostty shaders** (`configs/ghostty/shaders/`) — Custom GLSL CRT effects; `crt-tune` and `crt-cycle` scripts manage them
- **Claude statusline** (`configs/claude/statusline.sh`) — Parses Claude Code JSON output to render a 2-line status bar with model, context usage, cost, git branch, and gateway stats
