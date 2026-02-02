# Nix + Home Manager Dotfiles

Declarative, reproducible dotfiles using Nix and Home Manager.

## Quick Start (New Machine)

```bash
# One-liner bootstrap
curl -sSL https://raw.githubusercontent.com/nhabbash/dotfiles/main/nix/bootstrap.sh | bash
```

Or step by step:

```bash
# 1. Install Nix (using Determinate Systems installer)
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# 2. Enable flakes
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf

# 3. Clone dotfiles
git clone https://github.com/nhabbash/dotfiles.git ~/.dotfiles

# 4. Run Home Manager
cd ~/.dotfiles/nix
nix run home-manager/master -- switch --flake '.#nassim@macbook'
```

## Available Configurations

| Configuration | System | Description |
|--------------|--------|-------------|
| `nassim@macbook` | Apple Silicon Mac | Primary config |
| `nassim@macbook-intel` | Intel Mac | Intel Mac config |
| `nassim@linux` | x86_64 Linux | Linux config |

## Usage

### Rebuild after changes

```bash
# From the nix directory
cd ~/.dotfiles/nix
home-manager switch --flake '.#nassim@macbook'

# Or with an alias (add to your shell)
alias hms='home-manager switch --flake ~/.dotfiles/nix#nassim@macbook'
```

### Update all packages

```bash
cd ~/.dotfiles/nix
nix flake update
home-manager switch --flake '.#nassim@macbook'
```

### Rollback to previous generation

```bash
# List generations
home-manager generations

# Rollback
home-manager rollback
```

### Garbage collection

```bash
# Remove old generations
nix-collect-garbage -d

# More aggressive (remove everything not currently in use)
nix-collect-garbage --delete-older-than 7d
```

## Structure

```
nix/
├── flake.nix           # Flake definition (inputs, outputs)
├── flake.lock          # Locked versions (auto-generated)
├── home.nix            # Main Home Manager configuration
├── configs/            # External config files
│   ├── kitty/
│   │   ├── kitty.conf
│   │   └── current-theme.conf
│   └── zellij/
│       ├── config.kdl
│       └── catppuccin-mocha.kdl
├── bootstrap.sh        # New machine setup script
└── README.md           # This file
```

## What's Included

### Packages

- **Shell**: zsh, starship, fzf
- **Terminal**: zellij, tmux
- **CLI Tools**: bat, eza, ripgrep, fd, jq, tree, htop
- **Git**: git, gh, lazygit, gitleaks
- **Editor**: neovim
- **Kubernetes**: kubectl, kubectx, k9s
- **Cloud**: awscli2

### Configurations

- **Zsh**: Oh My Zsh, autosuggestions, syntax highlighting, aliases
- **Starship**: Custom Tokyo theme
- **Git**: Sensible defaults, aliases
- **Kitty**: Catppuccin theme, custom keybindings
- **Zellij**: Vim-style keybindings, plugins
- **FZF**: Shell integration
- **Bat**: Catppuccin theme
- **Eza**: Icons and git integration

## Customization

### Adding packages

Edit `home.nix`:

```nix
home.packages = with pkgs; [
  # Add new packages here
  neofetch
  bottom
];
```

### Adding a new program with Home Manager module

```nix
programs.direnv = {
  enable = true;
  enableZshIntegration = true;
  nix-direnv.enable = true;
};
```

### Machine-specific configuration

The flake passes `hostname` and `isWork` to `home.nix`. Use these for conditional config:

```nix
{ config, pkgs, hostname, isWork, ... }:

{
  programs.git.userEmail = if isWork
    then "work@company.com"
    else "personal@email.com";
}
```

## Things NOT Managed by Nix

Some tools are better managed outside of Nix:

| Tool | Why | Install with |
|------|-----|--------------|
| Volta | Better Node.js integration | `curl https://get.volta.sh \| bash` |
| pyenv | Work compatibility | `brew install pyenv` |
| Homebrew Casks | GUI apps on macOS | `brew install --cask app` |
| Fonts | System integration | Download or `brew install --cask font-*` |

## Troubleshooting

### "error: experimental Nix feature 'flakes' is disabled"

```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

### "error: path does not exist"

Make sure you're in the correct directory:

```bash
cd ~/.dotfiles/nix
```

### Conflicting files

If Home Manager can't create a symlink because a file exists:

```bash
# Backup and remove the existing file
mv ~/.config/kitty/kitty.conf ~/.config/kitty/kitty.conf.bak
home-manager switch --flake '.#nassim@macbook'
```

### Reset everything

```bash
# Remove home-manager state
rm -rf ~/.local/state/home-manager
rm -rf ~/.local/state/nix

# Start fresh
home-manager switch --flake '.#nassim@macbook'
```

## Resources

- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Home Manager Options](https://nix-community.github.io/home-manager/options.xhtml)
- [Nixpkgs Search](https://search.nixos.org/packages)
- [Nix Pills](https://nixos.org/guides/nix-pills/) - Learn Nix language
- [Zero to Nix](https://zero-to-nix.com/) - Beginner-friendly guide
