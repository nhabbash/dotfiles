#!/bin/bash
# Bootstrap script for new machines
# Usage: ./scripts/bootstrap.sh [personal-macbook|work-macbook]

set -e

HOSTNAME="${1:-personal-macbook}"
DOTFILES_DIR="${HOME}/.dotfiles"

echo "==> Bootstrapping dotfiles for: $HOSTNAME"

# Check if Nix is installed
if ! command -v nix &> /dev/null; then
    echo "==> Installing Nix..."
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
    echo "==> Nix installed. Please restart your shell and run this script again."
    exit 0
fi

# Mark dotfiles as safe directory for git (needed when running as root)
git config --global --add safe.directory "${DOTFILES_DIR}" 2>/dev/null || true
sudo git config --global --add safe.directory "${DOTFILES_DIR}" 2>/dev/null || true

# Backup existing shell configs that nix-darwin needs to manage
# nix-darwin adds nix initialization to these system-wide files
for f in /etc/bashrc /etc/zshrc; do
    if [ -f "$f" ] && [ ! -f "${f}.before-nix-darwin" ]; then
        echo "==> Backing up $f to ${f}.before-nix-darwin"
        sudo mv "$f" "${f}.before-nix-darwin"
    fi
done

# Check for existing config files that might conflict
CONFLICT_FILES=(
    "$HOME/.zshrc"
    "$HOME/.zprofile"
    "$HOME/.zshenv"
    "$HOME/.config/kitty/kitty.conf"
    "$HOME/.config/kitty/current-theme.conf"
    "$HOME/.config/zellij/config.kdl"
    "$HOME/.config/zellij/layouts/default.kdl"
    "$HOME/.config/zellij/themes/catppuccin-mocha.kdl"
)

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

# Build the configuration first (as user, to avoid permission issues)
echo "==> Building configuration..."
nix --extra-experimental-features 'nix-command flakes' build "${DOTFILES_DIR}#darwinConfigurations.${HOSTNAME}.system"

# Activate with sudo (required for system settings)
echo "==> Activating configuration (requires sudo)..."
sudo ./result/sw/bin/darwin-rebuild switch --flake "${DOTFILES_DIR}#${HOSTNAME}"

# Clean up build result
rm -f result

# Create machine-specific local configs
if [[ "$HOSTNAME" == "work-macbook" ]]; then
    if [ ! -f "$HOME/.zshrc.monday" ]; then
        echo "==> Creating ~/.zshrc.monday..."
        cat > "$HOME/.zshrc.monday" << 'EOF'
# Monday.com company dotfiles integration
source ~/dotfiles/.bash_profile
EOF
        echo "    Created ~/.zshrc.monday"
    fi

    if [ ! -f "$HOME/.gitconfig.local" ]; then
        echo "==> Creating ~/.gitconfig.local template..."
        cat > "$HOME/.gitconfig.local" << 'EOF'
# Work git configuration (not tracked in personal dotfiles)
# Add your work email and signing key here

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
else
    echo "  1. (Optional) Create ~/.zshrc.local for machine-specific shell config"
    echo "  2. (Optional) Create ~/.gitconfig.local for git signing keys"
    echo "  3. Restart your terminal"
fi
