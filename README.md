# Dotfiles

Nix-based dotfiles, configs and development environment

## Setup

```bash
git clone https://github.com/nhabbash/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./scripts/bootstrap.sh
```

Available configurations:
- `personal-macbook` - Personal Mac (default on macOS)
- `work-macbook` - Work Mac
- `linux-server` - Linux CLI-only (default on Linux)
- `linux-desktop` - Linux with GUI apps

## Daily Use

```bash
./scripts/switch.sh      # Rebuild after changes
./scripts/sync.sh        # Pull + rebuild
```
