#!/bin/bash
# Sync: pull + rebuild: ./scripts/sync.sh [hostname] [-v|--verbose]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
source "$SCRIPT_DIR/lib.sh"

HOSTNAME=""
VERBOSE_FLAG=""
for arg in "$@"; do
    case $arg in
        -v|--verbose)
            VERBOSE=true
            VERBOSE_FLAG="-v"
            ;;
        *) HOSTNAME="$arg" ;;
    esac
done

header "Syncing dotfiles"

init_progress 2

step "Pulling latest changes"
cd "$DOTFILES_DIR"
if $VERBOSE; then
    git pull --rebase
else
    run_quiet git pull --rebase
fi

step "Rebuilding configuration"
echo ""
"$SCRIPT_DIR/switch.sh" $HOSTNAME $VERBOSE_FLAG
