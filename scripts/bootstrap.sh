#!/bin/bash
# Bootstrap script for new machines
# Usage:
#   macOS:  ./scripts/bootstrap.sh [personal-macbook|work-macbook]
#   Linux:  ./scripts/bootstrap.sh [linux-server|linux-desktop]

set -e

# Detect OS
OS="$(uname -s)"
HOSTNAME="${1:-}"

# Detect dotfiles directory from script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

# Set default hostname based on OS if not provided
if [ -z "$HOSTNAME" ]; then
    if [ "$OS" = "Darwin" ]; then
        HOSTNAME="personal-macbook"
    else
        HOSTNAME="linux-server"
    fi
fi

echo "==> Bootstrapping dotfiles for: $HOSTNAME (OS: $OS)"

# Check if Nix is installed
if ! command -v nix &> /dev/null; then
    echo "==> Installing Nix..."
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
    echo "==> Nix installed. Please restart your shell and run this script again."
    exit 0
fi

# Mark dotfiles as safe directory for git
git config --global --add safe.directory "${DOTFILES_DIR}" 2>/dev/null || true

# macOS-specific setup
if [ "$OS" = "Darwin" ]; then
    # Mark dotfiles as safe for root (needed for darwin-rebuild)
    sudo git config --global --add safe.directory "${DOTFILES_DIR}" 2>/dev/null || true

    # Backup existing shell configs that nix-darwin needs to manage
    for f in /etc/bashrc /etc/zshrc /etc/zshenv; do
        if [ -f "$f" ] && [ ! -f "${f}.before-nix-darwin" ]; then
            echo "==> Backing up $f to ${f}.before-nix-darwin"
            sudo mv "$f" "${f}.before-nix-darwin"
        fi
    done

    # Check for existing config files that might conflict
    CONFLICT_FILES=(
        "$HOME/.zprofile"
        "$HOME/.zshenv"
        "$HOME/.config/kitty/kitty.conf"
        "$HOME/.config/kitty/current-theme.conf"
        "$HOME/.config/zellij/config.kdl"
        "$HOME/.config/zellij/layouts/default.kdl"
        "$HOME/.config/zellij/themes/catppuccin-mocha.kdl"
    )
else
    # Linux: only check for shell configs (no GUI apps on servers)
    CONFLICT_FILES=(
        "$HOME/.zprofile"
        "$HOME/.zshenv"
    )

    # Add GUI configs if installing a desktop config
    if [[ "$HOSTNAME" == "linux-desktop" ]]; then
        CONFLICT_FILES+=(
            "$HOME/.config/kitty/kitty.conf"
            "$HOME/.config/kitty/current-theme.conf"
            "$HOME/.config/zellij/config.kdl"
            "$HOME/.config/zellij/layouts/default.kdl"
            "$HOME/.config/zellij/themes/catppuccin-mocha.kdl"
        )
    fi
fi

EXISTING_FILES=()
for f in "${CONFLICT_FILES[@]}"; do
    if [ -f "$f" ] || [ -L "$f" ]; then
        EXISTING_FILES+=("$f")
    fi
done

if [ ${#EXISTING_FILES[@]} -gt 0 ]; then
    echo ""
    echo "==> Found existing config files that nix will manage:"
    for f in "${EXISTING_FILES[@]}"; do
        echo "    $f"
    done
    echo ""
    echo "How do you want to handle these?"
    echo "  1) Backup (rename to *.backup)"
    echo "  2) Delete (remove them, nix will create new ones)"
    echo "  3) Abort"
    echo ""
    read -p "Choose [1/2/3]: " choice

    case $choice in
        1)
            echo "==> Backing up existing files..."
            for f in "${EXISTING_FILES[@]}"; do
                if [ -f "$f" ] || [ -L "$f" ]; then
                    mv "$f" "${f}.backup"
                    echo "    Backed up: $f"
                fi
            done
            ;;
        2)
            echo "==> Removing existing files..."
            for f in "${EXISTING_FILES[@]}"; do
                if [ -f "$f" ] || [ -L "$f" ]; then
                    rm "$f"
                    echo "    Removed: $f"
                fi
            done
            ;;
        3)
            echo "Aborted."
            exit 1
            ;;
        *)
            echo "Invalid choice. Aborted."
            exit 1
            ;;
    esac
fi

# Ensure flake.lock exists and is valid
if [ ! -s "${DOTFILES_DIR}/flake.lock" ]; then
    echo "==> Generating flake.lock..."
    nix --extra-experimental-features 'nix-command flakes' flake update "${DOTFILES_DIR}"
fi

# Build and activate based on OS
if [ "$OS" = "Darwin" ]; then
    # macOS: use darwin-rebuild
    echo "==> Building configuration..."
    nix --extra-experimental-features 'nix-command flakes' build "${DOTFILES_DIR}#darwinConfigurations.${HOSTNAME}.system"

    echo "==> Activating configuration (requires sudo)..."
    sudo ./result/sw/bin/darwin-rebuild switch --flake "${DOTFILES_DIR}#${HOSTNAME}"

    rm -f result
else
    # Linux: use home-manager
    echo "==> Building and activating configuration..."

    # Check if home-manager is available
    if ! command -v home-manager &> /dev/null; then
        echo "==> Installing home-manager..."
        nix --extra-experimental-features 'nix-command flakes' run home-manager/master -- switch --flake "${DOTFILES_DIR}#${HOSTNAME}"
    else
        home-manager switch --flake "${DOTFILES_DIR}#${HOSTNAME}"
    fi
fi

# Set up ~/.zshrc (editable by you and tools)
if [ -L "$HOME/.zshrc" ]; then
    rm "$HOME/.zshrc"
fi

if [ ! -f "$HOME/.zshrc" ]; then
    echo "==> Creating ~/.zshrc..."
    cat > "$HOME/.zshrc" << 'EOF'
# Editable zsh config - add custom config below
source ~/.zshrc.base
[[ -f ~/.zshrc.work ]] && source ~/.zshrc.work
EOF
    echo "    Created ~/.zshrc"
fi

# Create work-specific config (macOS work machine only)
if [[ "$HOSTNAME" == "work-macbook" ]]; then
    if [ ! -f "$HOME/.zshrc.work" ]; then
        echo "==> Creating ~/.zshrc.work..."
        cat > "$HOME/.zshrc.work" << 'EOF'
# Work-specific config - not tracked in dotfiles repo
source ~/dotfiles/.bash_profile
EOF
        echo "    Created ~/.zshrc.work"
    fi

    if [ ! -f "$HOME/.gitconfig.local" ]; then
        echo "==> Creating ~/.gitconfig.local..."
        cat > "$HOME/.gitconfig.local" << 'EOF'
# Work git config - not tracked in dotfiles repo
[user]
    email = YOUR_EMAIL@monday.com
    # signingkey = YOUR_GPG_KEY
EOF
        echo "    Created ~/.gitconfig.local (edit with your work email)"
    fi
fi

echo ""
echo "==> Bootstrap complete!"
echo ""
echo "Next steps:"

if [[ "$HOSTNAME" == "work-macbook" ]]; then
    echo "  1. Edit ~/.gitconfig.local with your work email"
    echo "  2. Restart your terminal"
elif [ "$OS" = "Darwin" ]; then
    echo "  1. (Optional) Create ~/.gitconfig.local for git signing keys"
    echo "  2. Restart your terminal"
else
    echo "  1. Restart your terminal or run: source ~/.zshrc"
fi
