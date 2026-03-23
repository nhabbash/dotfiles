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

# Start/reload runtime desktop services that are safe to manage automatically
dotfiles services [hostname]

# Diagnose runtime health, links, installs, and permissions
dotfiles doctor [hostname]

# Enter dev shell (provides nixfmt)
nix develop
```

**Hostnames:** `personal-macbook` (default), `work-macbook`, `linux-server`, `linux-desktop`

## Architecture

This repo uses **Nix Flakes + nix-darwin + home-manager** to declaratively manage the system, while keeping most day-to-day tool configs live-editable. There are four practical classes of change:
- live edit: edit `configs/*`
- regenerate: run `dotfiles regen`
- rebuild: run `dotfiles rebuild`
- runtime: use `dotfiles services` / `dotfiles doctor`

See `docs/architecture.md` for the full model.

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
- `configs/agents/` → `~/.config/agents/` (shared cross-agent instruction modules)
- `configs/claude/` → `~/.claude/` (Claude loader + statusline)
- `configs/codex/` → `~/.config/codex/` (Codex adapter instructions)
- `configs/cursor-agent/` → `~/.config/cursor-agent/` (Cursor Agent adapter instructions)
- `configs/pi/` → `~/.config/pi/` (Pi adapter instructions)

### Requires rebuild
Editing `.nix` files requires running `rebuild` or `dotfiles rebuild`:
- `flake.nix` — inputs/outputs, supported hosts
- `modules/default.nix` — home-manager config and activation wiring
- `modules/links.nix` — live config link ownership map
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

## Human Operating Rules

If you do not know the internal architecture, follow this decision order:

1. If you are changing tool behavior, start in `configs/`
2. If you are changing installed packages/apps or host policy, edit `.nix` files
3. If a file says it is generated, run `dotfiles regen`
4. If something is installed but not behaving, use `dotfiles doctor`

Do not start by editing activation logic or bootstrap code unless the problem is
specifically about linking, startup, or machine setup.

## Documentation Policy

Documentation must be updated in the same change whenever behavior changes.

- If a command changes, update `README.md` and any affected docs under `docs/`
- If ownership or architecture changes, update `docs/architecture.md` and `docs/operations.md`
- If host-specific behavior changes, update `docs/hosts.md`
- If tool-install or tool-placement rules change, update `docs/adding-tools.md`
- If runtime behavior, troubleshooting, onboarding, or verification changes, update the corresponding self-service docs

Treat documentation updates as part of the implementation, not follow-up work.
If a user-facing workflow changed and the docs were not updated, the task is not complete.

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
