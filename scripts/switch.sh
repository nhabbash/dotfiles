#!/bin/bash
# Quick rebuild script
# Usage: ./scripts/switch.sh [hostname]

set -e

# Detect OS
OS="$(uname -s)"

# Detect dotfiles directory from script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

# Detect hostname or use provided argument
if [ -n "$1" ]; then
    HOSTNAME="$1"
else
    if [ "$OS" = "Darwin" ]; then
        # macOS: try to detect based on current hostname
        CURRENT_HOST=$(scutil --get LocalHostName 2>/dev/null || echo "")
        if [[ "$CURRENT_HOST" == *"work"* ]] || [[ "$CURRENT_HOST" == *"monday"* ]]; then
            HOSTNAME="work-macbook"
        else
            HOSTNAME="personal-macbook"
        fi
    else
        # Linux: default to server
        HOSTNAME="linux-server"
    fi
fi

echo "==> Rebuilding configuration for: $HOSTNAME"

# Ensure flake.lock exists and is valid
if [ ! -s "${DOTFILES_DIR}/flake.lock" ]; then
    echo "==> Generating flake.lock..."
    nix --extra-experimental-features 'nix-command flakes' flake update "${DOTFILES_DIR}"
fi

# Build and activate based on OS
if [ "$OS" = "Darwin" ]; then
    # darwin-rebuild needs sudo for system activation
    sudo darwin-rebuild switch --flake "${DOTFILES_DIR}#${HOSTNAME}"
else
    # Linux: use home-manager
    home-manager switch --flake "${DOTFILES_DIR}#${HOSTNAME}"
fi

echo "==> Done!"
