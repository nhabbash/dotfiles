#!/usr/bin/env bash
# =============================================================================
# Nix + Home Manager Bootstrap Script
# =============================================================================
# This script sets up a fresh machine with Nix and Home Manager.
# Run with: curl -sSL https://raw.githubusercontent.com/nhabbash/dotfiles/main/nix/bootstrap.sh | bash
# Or locally: ./bootstrap.sh
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# =============================================================================
# Detect system
# =============================================================================
detect_system() {
    case "$(uname -s)" in
        Darwin)
            case "$(uname -m)" in
                arm64) SYSTEM="aarch64-darwin" ;;
                x86_64) SYSTEM="x86_64-darwin" ;;
                *) error "Unknown macOS architecture: $(uname -m)" ;;
            esac
            ;;
        Linux)
            case "$(uname -m)" in
                x86_64) SYSTEM="x86_64-linux" ;;
                aarch64) SYSTEM="aarch64-linux" ;;
                *) error "Unknown Linux architecture: $(uname -m)" ;;
            esac
            ;;
        *) error "Unknown OS: $(uname -s)" ;;
    esac
    info "Detected system: $SYSTEM"
}

# =============================================================================
# Install Nix
# =============================================================================
install_nix() {
    if command -v nix &>/dev/null; then
        success "Nix is already installed: $(nix --version)"
        return
    fi

    info "Installing Nix..."

    # Use the Determinate Systems installer (recommended for macOS)
    # It handles macOS quirks better than the official installer
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

    # Source nix in current shell
    if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
        . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
    fi

    success "Nix installed successfully"
}

# =============================================================================
# Enable Flakes
# =============================================================================
enable_flakes() {
    info "Enabling Nix flakes..."

    mkdir -p ~/.config/nix
    if ! grep -q "experimental-features" ~/.config/nix/nix.conf 2>/dev/null; then
        echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
        success "Flakes enabled"
    else
        success "Flakes already enabled"
    fi
}

# =============================================================================
# Clone dotfiles
# =============================================================================
clone_dotfiles() {
    DOTFILES_DIR="$HOME/.dotfiles"

    if [ -d "$DOTFILES_DIR" ]; then
        success "Dotfiles already cloned at $DOTFILES_DIR"
        cd "$DOTFILES_DIR"
        git pull || warn "Could not pull latest changes"
        return
    fi

    info "Cloning dotfiles..."
    git clone https://github.com/nhabbash/dotfiles.git "$DOTFILES_DIR"
    success "Dotfiles cloned to $DOTFILES_DIR"
}

# =============================================================================
# Determine Home Manager configuration name
# =============================================================================
get_config_name() {
    case "$SYSTEM" in
        aarch64-darwin) CONFIG_NAME="nassim@macbook" ;;
        x86_64-darwin) CONFIG_NAME="nassim@macbook-intel" ;;
        x86_64-linux|aarch64-linux) CONFIG_NAME="nassim@linux" ;;
        *) error "No configuration for system: $SYSTEM" ;;
    esac
    info "Using configuration: $CONFIG_NAME"
}

# =============================================================================
# Install/Run Home Manager
# =============================================================================
run_home_manager() {
    info "Building and activating Home Manager configuration..."

    cd "$HOME/.dotfiles/nix"

    # First time: use nix run to bootstrap home-manager
    if ! command -v home-manager &>/dev/null; then
        info "Running initial Home Manager switch..."
        nix run home-manager/master -- switch --flake ".#$CONFIG_NAME"
    else
        home-manager switch --flake ".#$CONFIG_NAME"
    fi

    success "Home Manager configuration activated!"
}

# =============================================================================
# Post-install steps
# =============================================================================
post_install() {
    info "Running post-install steps..."

    # Install Volta (Node.js version manager) - not in nixpkgs
    if ! command -v volta &>/dev/null; then
        info "Installing Volta..."
        curl https://get.volta.sh | bash -s -- --skip-setup
        success "Volta installed"
    fi

    # Remind about manual steps
    echo ""
    echo "=============================================="
    echo -e "${GREEN}Bootstrap complete!${NC}"
    echo "=============================================="
    echo ""
    echo "Manual steps remaining:"
    echo "  1. Update home.nix with your personal email"
    echo "  2. Install your preferred Nerd Font"
    echo "  3. Set up SSH keys for GitHub"
    echo "  4. Install Node.js via Volta: volta install node"
    echo ""
    echo "To rebuild your configuration after changes:"
    echo "  cd ~/.dotfiles/nix && home-manager switch --flake '.#$CONFIG_NAME'"
    echo ""
    echo "Or create an alias:"
    echo "  alias hms='home-manager switch --flake ~/.dotfiles/nix#$CONFIG_NAME'"
    echo ""
}

# =============================================================================
# Main
# =============================================================================
main() {
    echo ""
    echo "=============================================="
    echo "  Nix + Home Manager Bootstrap"
    echo "=============================================="
    echo ""

    detect_system
    install_nix
    enable_flakes
    clone_dotfiles
    get_config_name
    run_home_manager
    post_install
}

main "$@"
