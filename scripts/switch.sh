#!/bin/bash
# Quick rebuild: ./scripts/switch.sh [hostname] [-v|--verbose] [-e|--editable]
#
# Flags:
#   -e, --editable   Use direct symlinks (configs editable at expected paths)
#   -v, --verbose    Show detailed output

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
source "$SCRIPT_DIR/lib.sh"

HOSTNAME=""
EDITABLE=false

for arg in "$@"; do
    case $arg in
        -v|--verbose) VERBOSE=true ;;
        -e|--editable) EDITABLE=true ;;
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

MODE_LABEL=""
if [ "$EDITABLE" = true ]; then
    MODE_LABEL=" (editable)"
fi

header "Rebuilding for: $HOSTNAME$MODE_LABEL"

if [ "$OS" = "Darwin" ]; then
    init_progress 3
else
    init_progress 2
fi

if [ ! -s "${DOTFILES_DIR}/flake.lock" ]; then
    step "Generating flake.lock"
    run_quiet nix --extra-experimental-features 'nix-command flakes' flake update "${DOTFILES_DIR}"
fi

NIX_BUILD_FLAGS="-j auto --cores 0"

if [ "$OS" = "Darwin" ]; then
    step "Building configuration"
    run_quiet nix --extra-experimental-features 'nix-command flakes' build $NIX_BUILD_FLAGS "${DOTFILES_DIR}#darwinConfigurations.${HOSTNAME}.system"

    step "Applying system settings"
    run_quiet sudo ./result/sw/bin/darwin-rebuild switch --flake "${DOTFILES_DIR}#${HOSTNAME}"
    rm -f result

    step "Activating home-manager"
else
    step "Building configuration"
    run_quiet nix --extra-experimental-features 'nix-command flakes' build $NIX_BUILD_FLAGS "${DOTFILES_DIR}#homeConfigurations.${HOSTNAME}.activationPackage"

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

# Editable mode: replace nix store symlinks with direct symlinks to dotfiles
if [ "$EDITABLE" = true ]; then
    step "Creating editable symlinks"

    CONFIGS_DIR="${DOTFILES_DIR}/configs"

    # Kitty
    mkdir -p "$HOME/.config/kitty"
    ln -sfn "${CONFIGS_DIR}/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
    ln -sfn "${CONFIGS_DIR}/kitty/current-theme.conf" "$HOME/.config/kitty/current-theme.conf"

    # Zellij
    mkdir -p "$HOME/.config/zellij/layouts" "$HOME/.config/zellij/themes"
    ln -sfn "${CONFIGS_DIR}/zellij/config.kdl" "$HOME/.config/zellij/config.kdl"
    ln -sfn "${CONFIGS_DIR}/zellij/layouts/default.kdl" "$HOME/.config/zellij/layouts/default.kdl"
    ln -sfn "${CONFIGS_DIR}/zellij/themes/catppuccin-mocha.kdl" "$HOME/.config/zellij/themes/catppuccin-mocha.kdl"

    # Starship (if external config exists)
    if [ -f "${CONFIGS_DIR}/starship.toml" ]; then
        ln -sfn "${CONFIGS_DIR}/starship.toml" "$HOME/.config/starship.toml"
    fi

    # Git (if external config exists)
    if [ -f "${CONFIGS_DIR}/git/config" ]; then
        ln -sfn "${CONFIGS_DIR}/git/config" "$HOME/.gitconfig"
    fi
fi

success "Done!"
show_summary
