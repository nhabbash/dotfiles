#!/bin/bash
# Sync script: pull latest changes and rebuild
# Usage: ./scripts/sync.sh [hostname]

set -e

# Detect dotfiles directory from script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
HOSTNAME="${1:-}"

echo "==> Syncing dotfiles..."

# Pull latest changes
cd "$DOTFILES_DIR"
git pull --rebase

# Rebuild
./scripts/switch.sh $HOSTNAME

echo "==> Sync complete!"
