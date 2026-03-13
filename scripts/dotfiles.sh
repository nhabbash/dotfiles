#!/bin/bash
# Dotfiles manager: ./scripts/dotfiles.sh <command> [options]
#
# Commands:
#   bootstrap [hostname]   First-time setup on a new machine
#   rebuild [hostname]     Rebuild nix configuration
#   pull                   Smart pull: only rebuilds if nix files changed
#   push [message]         Commit and push all changes
#   status                 Show uncommitted changes
#
# Flags:
#   -v, --verbose          Show detailed output

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
source "$SCRIPT_DIR/lib.sh"

# --- Shared helpers ---

detect_hostname() {
    local OS="$(uname -s)"
    if [ "$OS" = "Darwin" ]; then
        local host
        host=$(scutil --get LocalHostName 2>/dev/null || echo "")
        if [[ "$host" == *"work"* ]] || [[ "$host" == *"monday"* ]]; then
            echo "work-macbook"
        else
            echo "personal-macbook"
        fi
    else
        echo "linux-server"
    fi
}

ensure_flake_lock() {
    if [ ! -s "${DOTFILES_DIR}/flake.lock" ]; then
        step "Generating flake.lock"
        run_quiet nix --extra-experimental-features 'nix-command flakes' flake update "${DOTFILES_DIR}"
    fi
}

setup_zshrc() {
    if [ -L "$HOME/.zshrc" ]; then
        rm "$HOME/.zshrc"
    fi
    # Upgrade old .zshrc that sources .zshrc.work → .zshrc.local
    if [ -f "$HOME/.zshrc" ] && grep -q '\.zshrc\.work' "$HOME/.zshrc" 2>/dev/null; then
        sed -i.bak 's/\.zshrc\.work/.zshrc.local/g' "$HOME/.zshrc"
        rm -f "$HOME/.zshrc.bak"
    fi
    if [ ! -f "$HOME/.zshrc" ]; then
        cat > "$HOME/.zshrc" << 'ZSHRC'
# Editable zsh config - add custom config below
source ~/.zshrc.base
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
ZSHRC
    fi
}

nix_rebuild() {
    local hostname="$1"
    local OS="$(uname -s)"
    local NIX_BUILD_FLAGS="-j auto --cores 0 --impure"

    ensure_flake_lock

    if [ "$OS" = "Darwin" ]; then
        step "Building configuration"
        run_quiet nix --extra-experimental-features 'nix-command flakes' build $NIX_BUILD_FLAGS "${DOTFILES_DIR}#darwinConfigurations.${hostname}.system"

        step "Applying system settings"
        run_quiet sudo DOTFILES_DIR="$DOTFILES_DIR" ./result/sw/bin/darwin-rebuild switch --flake "${DOTFILES_DIR}#${hostname}" --impure
        rm -f result

        step "Activating home-manager"
    else
        step "Building configuration"
        run_quiet nix --extra-experimental-features 'nix-command flakes' build $NIX_BUILD_FLAGS "${DOTFILES_DIR}#homeConfigurations.${hostname}.activationPackage"

        step "Activating home-manager"
        if command_exists home-manager; then
            run_quiet home-manager switch --flake "${DOTFILES_DIR}#${hostname}" --impure
        else
            run_quiet nix --extra-experimental-features 'nix-command flakes' run home-manager/master -- switch --flake "${DOTFILES_DIR}#${hostname}" --impure
        fi
    fi

    setup_zshrc
}

# --- Commands ---

cmd_rebuild() {
    local hostname="${1:-$(detect_hostname)}"
    local OS="$(uname -s)"

    header "Rebuilding for: $hostname"

    if [ "$OS" = "Darwin" ]; then
        init_progress 3
    else
        init_progress 2
    fi

    nix_rebuild "$hostname"

    success "Done!"
    show_summary
}

cmd_pull() {
    header "Pulling latest changes"

    if [ -n "$(git -C "$DOTFILES_DIR" status --porcelain)" ]; then
        error "Uncommitted changes detected — commit or push them first (run 'dotfiles status')"
        return 1
    fi

    local before after
    before="$(git -C "$DOTFILES_DIR" rev-parse HEAD)"
    git -C "$DOTFILES_DIR" pull --rebase || { error "Pull failed"; return 1; }
    after="$(git -C "$DOTFILES_DIR" rev-parse HEAD)"

    if [ "$before" = "$after" ]; then
        success "Already up to date."
        return
    fi

    # Check if nix files changed (requires rebuild) or just configs (instant)
    if git -C "$DOTFILES_DIR" diff --name-only "$before" "$after" | grep -qE '\.nix$|flake\.lock'; then
        echo ""
        warn "Nix files changed — rebuilding..."
        echo ""
        cmd_rebuild
    else
        success "Config changes applied (no rebuild needed)."
    fi
}

cmd_push() {
    local msg="${1:-update configs}"

    if [ -z "$(git -C "$DOTFILES_DIR" status --porcelain)" ]; then
        echo "Nothing to push."
        return
    fi

    header "Pushing dotfiles changes"

    git -C "$DOTFILES_DIR" add -A
    echo ""
    echo -e "${BOLD}Changes:${NC}"
    git -C "$DOTFILES_DIR" diff --cached --stat
    echo ""

    git -C "$DOTFILES_DIR" commit -m "$msg"
    git -C "$DOTFILES_DIR" push

    success "Pushed!"
}

cmd_status() {
    local changes
    changes="$(git -C "$DOTFILES_DIR" status --porcelain)"

    if [ -z "$changes" ]; then
        echo "Dotfiles clean — no uncommitted changes."
    else
        echo -e "${BOLD}Uncommitted changes:${NC}"
        git -C "$DOTFILES_DIR" status --short
    fi
}

cmd_bootstrap() {
    local hostname="${1:-}"
    local OS="$(uname -s)"

    if [ -z "$hostname" ]; then
        if [ "$OS" = "Darwin" ]; then
            hostname="personal-macbook"
        else
            hostname="linux-server"
        fi
    fi

    header "Bootstrapping: $hostname ($OS)"
    SUMMARY_ITEMS=()

    if [ "$OS" = "Darwin" ]; then
        init_progress 6
    else
        init_progress 4
    fi

    # Nix installation
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

    # macOS system files
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

    # Config conflict resolution
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
        if [[ "$hostname" == "linux-desktop" ]]; then
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

    # Build and activate
    nix_rebuild "$hostname"
    SUMMARY_ITEMS+=("Configuration built and activated")

    # Shell setup
    step "Setting up shell configuration"
    setup_zshrc

    if [[ "$hostname" == "work-macbook" ]]; then
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

    success "Bootstrap complete!"

    echo ""
    echo -e "${BOLD}Summary:${NC}"
    for item in "${SUMMARY_ITEMS[@]}"; do
        info "$item"
    done

    echo ""
    echo -e "${BOLD}Next steps:${NC}"
    if [[ "$hostname" == "work-macbook" ]]; then
        echo "  1. Edit ~/.gitconfig.local with your work email"
        echo "  2. Restart your terminal"
    elif [ "$OS" = "Darwin" ]; then
        echo "  1. Restart your terminal"
    else
        echo "  1. Restart your terminal or run: source ~/.zshrc"
    fi
}

# --- Main ---

# Parse global flags
COMMAND=""
ARGS=()
for arg in "$@"; do
    case $arg in
        -v|--verbose) VERBOSE=true ;;
        *) ARGS+=("$arg") ;;
    esac
done

COMMAND="${ARGS[0]:-}"
COMMAND_ARGS=("${ARGS[@]:1}")

case "$COMMAND" in
    bootstrap)  cmd_bootstrap "${COMMAND_ARGS[@]}" ;;
    rebuild)    cmd_rebuild "${COMMAND_ARGS[@]}" ;;
    pull)       cmd_pull ;;
    push)       cmd_push "${COMMAND_ARGS[*]}" ;;
    status)     cmd_status ;;
    *)
        echo "Dotfiles manager"
        echo ""
        echo "Usage: dotfiles <command> [options]"
        echo ""
        echo "Commands:"
        echo "  bootstrap [hostname]   First-time setup on a new machine"
        echo "  rebuild [hostname]     Rebuild nix configuration"
        echo "  pull                   Pull changes (rebuilds only if nix files changed)"
        echo "  push [message]         Commit and push all changes"
        echo "  status                 Show uncommitted changes"
        echo ""
        echo "Flags:"
        echo "  -v, --verbose          Show detailed output"
        ;;
esac
