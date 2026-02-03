#!/bin/bash
# Quick rebuild: ./scripts/switch.sh [hostname] [-v|--verbose]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
source "$SCRIPT_DIR/lib.sh"

HOSTNAME=""
for arg in "$@"; do
    case $arg in
        -v|--verbose) VERBOSE=true ;;
        *) HOSTNAME="$arg" ;;
    esac
done

OS="$(uname -s)"

if [ -z "$HOSTNAME" ]; then
    if [ "$OS" = "Darwin" ]; then
        CURRENT_HOST=$(scutil --get LocalHostName 2>/dev/null || echo "")
        if [[ "$CURRENT_HOST" == *"work"* ]] || [[ "$CURRENT_HOST" == *"monday"* ]]; then
            HOSTNAME="work-macbook"
        else
            HOSTNAME="personal-macbook"
        fi
    else
        HOSTNAME="linux-server"
    fi
fi

header "Rebuilding for: $HOSTNAME"

if [ "$OS" = "Darwin" ]; then
    init_progress 3
else
    init_progress 2
fi

if [ ! -s "${DOTFILES_DIR}/flake.lock" ]; then
    step "Generating flake.lock"
    run_quiet nix --extra-experimental-features 'nix-command flakes' flake update "${DOTFILES_DIR}"
fi

if [ "$OS" = "Darwin" ]; then
    step "Building configuration"
    run_quiet nix --extra-experimental-features 'nix-command flakes' build "${DOTFILES_DIR}#darwinConfigurations.${HOSTNAME}.system"

    step "Applying system settings"
    run_quiet sudo ./result/sw/bin/darwin-rebuild switch --flake "${DOTFILES_DIR}#${HOSTNAME}"
    rm -f result

    step "Activating home-manager"
else
    step "Building configuration"
    run_quiet nix --extra-experimental-features 'nix-command flakes' build "${DOTFILES_DIR}#homeConfigurations.${HOSTNAME}.activationPackage"

    step "Activating home-manager"
    if command_exists home-manager; then
        run_quiet home-manager switch --flake "${DOTFILES_DIR}#${HOSTNAME}"
    else
        run_quiet nix --extra-experimental-features 'nix-command flakes' run home-manager/master -- switch --flake "${DOTFILES_DIR}#${HOSTNAME}"
    fi
fi

if [ -L "$HOME/.zshrc" ]; then
    rm "$HOME/.zshrc"
fi

if [ ! -f "$HOME/.zshrc" ]; then
    cat > "$HOME/.zshrc" << 'EOF'
# Editable zsh config - add custom config below
source ~/.zshrc.base
[[ -f ~/.zshrc.work ]] && source ~/.zshrc.work
EOF
fi

success "Done!"
show_summary
