#!/bin/bash
# Bootstrap new machine: ./scripts/bootstrap.sh [hostname] [-v|--verbose] [-e|--editable]
# macOS: personal-macbook | work-macbook
# Linux: linux-server | linux-desktop
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
        HOSTNAME="personal-macbook"
    else
        HOSTNAME="linux-server"
    fi
fi

MODE_LABEL=""
if [ "$EDITABLE" = true ]; then
    MODE_LABEL=" (editable)"
fi

header "Bootstrapping: $HOSTNAME ($OS)$MODE_LABEL"

SUMMARY_ITEMS=()

if [ "$OS" = "Darwin" ]; then
    init_progress 6
else
    init_progress 4
fi

step "Checking Nix installation"
if ! command_exists nix; then
    echo ""
    warn "Nix is not installed. Installing now..."
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
    echo ""
    success "Nix installed!"
    echo ""
    echo -e "${BOLD}Please restart your shell and run this script again.${NC}"
    exit 0
fi
SUMMARY_ITEMS+=("Nix already installed")

git config --global --add safe.directory "${DOTFILES_DIR}" 2>/dev/null || true

if [ "$OS" = "Darwin" ]; then
    step "Checking system files"
    sudo git config --global --add safe.directory "${DOTFILES_DIR}" 2>/dev/null || true

    backed_up=0
    for f in /etc/bashrc /etc/zshrc /etc/zshenv; do
        if [ -f "$f" ] && [ ! -f "${f}.before-nix-darwin" ]; then
            sudo mv "$f" "${f}.before-nix-darwin"
            ((backed_up++))
        fi
    done
    [[ $backed_up -gt 0 ]] && SUMMARY_ITEMS+=("$backed_up system files backed up")
fi

step "Checking for config conflicts"

if [ "$OS" = "Darwin" ]; then
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
    CONFLICT_FILES=(
        "$HOME/.zprofile"
        "$HOME/.zshenv"
    )
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
    warn "Found ${#EXISTING_FILES[@]} existing config files that nix will manage:"
    for f in "${EXISTING_FILES[@]}"; do
        echo -e "    ${DIM}$f${NC}"
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
            for f in "${EXISTING_FILES[@]}"; do
                if [ -f "$f" ] || [ -L "$f" ]; then
                    mv "$f" "${f}.backup"
                fi
            done
            SUMMARY_ITEMS+=("${#EXISTING_FILES[@]} config files backed up")
            ;;
        2)
            for f in "${EXISTING_FILES[@]}"; do
                if [ -f "$f" ] || [ -L "$f" ]; then
                    rm "$f"
                fi
            done
            SUMMARY_ITEMS+=("${#EXISTING_FILES[@]} config files removed")
            ;;
        3)
            error "Aborted by user."
            exit 1
            ;;
        *)
            error "Invalid choice. Aborted."
            exit 1
            ;;
    esac
else
    SUMMARY_ITEMS+=("No config conflicts")
fi

if [ ! -s "${DOTFILES_DIR}/flake.lock" ]; then
    step "Generating flake.lock"
    run_quiet nix --extra-experimental-features 'nix-command flakes' flake update "${DOTFILES_DIR}"
    SUMMARY_ITEMS+=("Flake lock generated")
fi

NIX_BUILD_FLAGS="-j auto --cores 0"

if [ "$OS" = "Darwin" ]; then
    step "Building configuration"
    run_quiet nix --extra-experimental-features 'nix-command flakes' build $NIX_BUILD_FLAGS "${DOTFILES_DIR}#darwinConfigurations.${HOSTNAME}.system"

    step "Applying system settings"
    run_quiet sudo ./result/sw/bin/darwin-rebuild switch --flake "${DOTFILES_DIR}#${HOSTNAME}"
    rm -f result
    SUMMARY_ITEMS+=("System preferences applied")
else
    step "Building configuration"
    if command_exists home-manager; then
        run_quiet home-manager switch --flake "${DOTFILES_DIR}#${HOSTNAME}"
    else
        run_quiet nix --extra-experimental-features 'nix-command flakes' run home-manager/master $NIX_BUILD_FLAGS -- switch --flake "${DOTFILES_DIR}#${HOSTNAME}"
    fi
    SUMMARY_ITEMS+=("Home-manager activated")
fi

step "Setting up shell configuration"

if [ -L "$HOME/.zshrc" ]; then
    rm "$HOME/.zshrc"
fi

if [ ! -f "$HOME/.zshrc" ]; then
    cat > "$HOME/.zshrc" << 'EOF'
# Editable zsh config - add custom config below
source ~/.zshrc.base
[[ -f ~/.zshrc.work ]] && source ~/.zshrc.work
EOF
    SUMMARY_ITEMS+=("Created ~/.zshrc")
fi

if [[ "$HOSTNAME" == "work-macbook" ]]; then
    if [ ! -f "$HOME/.zshrc.work" ]; then
        cat > "$HOME/.zshrc.work" << 'EOF'
# Work-specific config - not tracked in personal dotfiles

EOF
        SUMMARY_ITEMS+=("Created ~/.zshrc.work")
    fi

    if [ ! -f "$HOME/.gitconfig.local" ]; then
        cat > "$HOME/.gitconfig.local" << 'EOF'
# Work git config - not tracked in dotfiles repo
[user]
    email = YOUR_EMAIL@monday.com
    # signingkey = YOUR_GPG_KEY
EOF
        SUMMARY_ITEMS+=("Created ~/.gitconfig.local")
    fi
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

    SUMMARY_ITEMS+=("Editable symlinks created")
fi

success "Bootstrap complete!"

echo ""
echo -e "${BOLD}Summary:${NC}"
for item in "${SUMMARY_ITEMS[@]}"; do
    info "$item"
done

echo ""
echo -e "${BOLD}Next steps:${NC}"
if [[ "$HOSTNAME" == "work-macbook" ]]; then
    echo "  1. Edit ~/.gitconfig.local with your work email"
    echo "  2. Edit ~/.zshrc.work with your work config"
    echo "  3. Restart your terminal"
elif [ "$OS" = "Darwin" ]; then
    echo "  1. Restart your terminal"
else
    echo "  1. Restart your terminal or run: source ~/.zshrc"
fi
