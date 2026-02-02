# Dotfiles

Personal dotfiles for macOS/Linux development environment.

## Setup Options

### Option 1: Nix + Home Manager (Recommended)

Fully declarative setup - packages and configs in one place.

```bash
# One-liner for new machines
curl -sSL https://raw.githubusercontent.com/nhabbash/dotfiles/main/nix/bootstrap.sh | bash
```

Or manually:

```bash
# Install Nix
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# Enable flakes
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf

# Clone and activate
git clone https://github.com/nhabbash/dotfiles.git ~/.dotfiles
cd ~/.dotfiles/nix
nix run home-manager/master -- switch --flake '.#nassim@macbook'
```

See [nix/README.md](nix/README.md) for full documentation.

### Option 2: GNU Stow (Legacy)

Symlink-based setup for individual configs.

```bash
# Install stow
brew install stow  # macOS
apt install stow   # Linux

# Clone
git clone https://github.com/nhabbash/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# Symlink individual configs
stow zsh        # ~/.zshrc, ~/.zsh_aliases
stow starship   # ~/.config/starship/
stow tmux       # ~/.tmux.conf
stow zellij     # ~/.config/zellij/
```

## Structure

```
~/.dotfiles/
├── nix/                    # Nix + Home Manager setup
│   ├── flake.nix
│   ├── home.nix
│   ├── bootstrap.sh
│   └── configs/
├── zsh/                    # Stow: zsh config
│   ├── .zshrc
│   └── .zsh_aliases
├── starship/               # Stow: starship prompts
│   └── .config/starship/
├── tmux/                   # Stow: tmux config
│   └── .config/tmux/
├── zellij/                 # Stow: zellij config
│   └── .config/zellij/
└── init.sh                 # Legacy bootstrap script
```

## What's Included

| Tool | Description |
|------|-------------|
| zsh | Shell config with Oh My Zsh, autosuggestions, syntax highlighting |
| starship | Multiple prompt themes (Tokyo, Pure, Pastel) |
| tmux | Terminal multiplexer config |
| zellij | Modern terminal workspace |
| kitty | Terminal emulator (via Nix) |
| git | Aliases and sensible defaults (via Nix) |
| CLI tools | bat, eza, fzf, ripgrep, fd, jq (via Nix) |

## Quick Reference

```bash
# Rebuild Nix config after changes
home-manager switch --flake ~/.dotfiles/nix#nassim@macbook

# Update all Nix packages
cd ~/.dotfiles/nix && nix flake update && home-manager switch --flake '.#nassim@macbook'

# Rollback to previous generation
home-manager rollback

# Re-stow a config
cd ~/.dotfiles && stow -R zsh
```
