#!/bin/bash
# Sync script: pull latest changes and rebuild
# Usage: ./scripts/sync.sh [hostname]

set -e

DOTFILES_DIR="${HOME}/.dotfiles"
HOSTNAME="${1:-}"

echo "==> Syncing dotfiles..."

# Pull latest changes
cd "$DOTFILES_DIR"
git pull --rebase

# Rebuild
./scripts/switch.sh $HOSTNAME

echo "==> Sync complete!"
