#!/bin/bash
# Quick rebuild script
# Usage: ./scripts/switch.sh [hostname]

set -e

# Detect dotfiles directory from script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

# Detect hostname or use provided argument
if [ -n "$1" ]; then
    HOSTNAME="$1"
else
    # Try to detect based on current hostname or default to personal
    CURRENT_HOST=$(scutil --get LocalHostName 2>/dev/null || echo "")
    if [[ "$CURRENT_HOST" == *"work"* ]] || [[ "$CURRENT_HOST" == *"monday"* ]]; then
        HOSTNAME="work-macbook"
    else
        HOSTNAME="personal-macbook"
    fi
fi

echo "==> Rebuilding configuration for: $HOSTNAME"

# darwin-rebuild needs sudo for system activation
sudo darwin-rebuild switch --flake "${DOTFILES_DIR}#${HOSTNAME}"

echo "==> Done!"
