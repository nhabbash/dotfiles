#!/bin/bash
# Dotfiles manager: ./scripts/dotfiles.sh <command> [options]
#
# Commands:
#   bootstrap [hostname]   First-time setup on a new machine
#   rebuild [hostname]     Rebuild nix configuration
#   regen                  Regenerate derived config from source manifests
#   check [hostname]       Verify repo integrity and config drift
#   assets [hostname]      Install explicit external assets
#   snapshot [hostname]    Capture current repo and runtime state for cutover
#   preflight [hostname]   Capture a snapshot and run integrity checks
#   services [hostname]    Start/reload local desktop services
#   doctor [hostname]      Diagnose local setup and service health
#   pull                   Smart pull: only rebuilds if nix files changed
#   push [message]         Commit and push all changes
#   status [hostname]      Show repo state and local service status
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

run_sync_keymaps() {
    local check_mode="${1:-0}"
    local generator="$DOTFILES_DIR/scripts/generated/sync-keymaps.py"
    if [ "$check_mode" = "1" ]; then
        run_quiet python3 "$generator" --check
    else
        run_quiet python3 "$generator"
    fi
}

check_shell_scripts() {
    local script
    while IFS= read -r script; do
        run_quiet bash -n "$script"
    done < <(find "$DOTFILES_DIR/scripts" -type f \( -name "*.sh" -o -path "$DOTFILES_DIR/scripts/dotfiles.sh" -o -path "$DOTFILES_DIR/scripts/crt-cycle" -o -path "$DOTFILES_DIR/scripts/crt-lab" -o -path "$DOTFILES_DIR/scripts/crt-tune" \) | sort)
}

check_python_scripts() {
    local script
    while IFS= read -r script; do
        run_quiet python3 -m py_compile "$script"
    done < <(find "$DOTFILES_DIR/scripts" -type f -name "*.py" | sort)
}

check_nix_eval() {
    local hostname="$1"
    local OS="$(uname -s)"
    local cache_home="/tmp/dotfiles-nix-cache"

    mkdir -p "$cache_home"

    if [ "$OS" = "Darwin" ]; then
        run_quiet env XDG_CACHE_HOME="$cache_home" DOTFILES_DIR="$DOTFILES_DIR" nix --extra-experimental-features 'nix-command flakes' eval --impure "$DOTFILES_DIR#darwinConfigurations.${hostname}.config.system.primaryUser"
    else
        run_quiet env XDG_CACHE_HOME="$cache_home" DOTFILES_DIR="$DOTFILES_DIR" nix --extra-experimental-features 'nix-command flakes' eval --impure "$DOTFILES_DIR#homeConfigurations.${hostname}.config.home.username"
    fi
}

capture_snapshot() {
    local hostname="$1"
    local os="$(uname -s)"
    local out_dir="${TMPDIR:-/tmp}"
    local out_file="$out_dir/dotfiles-snapshot-${hostname}-$(date +%Y%m%d-%H%M%S).txt"

    {
        echo "# Dotfiles Snapshot"
        echo ""
        echo "timestamp: $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
        echo "hostname: $hostname"
        echo "os: $os"
        echo "branch: $(git -C "$DOTFILES_DIR" branch --show-current 2>/dev/null || true)"
        echo "commit: $(git -C "$DOTFILES_DIR" rev-parse HEAD 2>/dev/null || true)"
        echo ""
        echo "## git status"
        git -C "$DOTFILES_DIR" status --short || true
        echo ""
        echo "## dotfiles status"
        COMMAND=status
        cmd_status "$hostname" || true
        echo ""
        echo "## dotfiles doctor"
        COMMAND=doctor
        cmd_doctor "$hostname" || true
        if [ "$os" = "Darwin" ]; then
            echo ""
            echo "## darwin generations"
            darwin-rebuild --list-generations 2>/dev/null || true
        fi
    } > "$out_file"

    printf '%s\n' "$out_file"
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
# ~/.zshrc — local, untracked. Safe to edit directly.
# For changes you want on ALL machines → edit ~/Development/dotfiles/configs/zsh/
# For changes on THIS machine only    → add them below, or in ~/.zshrc.local
#
# Zsh config map:
#   aliases.zsh      — all shared aliases          (edit + dotfiles push)
#   functions.zsh    — shell functions              (edit + dotfiles push)
#   core.zsh         — PATH, homebrew, keybindings  (edit + dotfiles push)
#   personal.zsh     — personal machine overrides   (edit + dotfiles push)
#   work.zsh         — work machine overrides       (edit + dotfiles push)
#   modules/shell/zsh.nix — plugins, history        (edit + dotfiles rebuild)
#   ~/.zshrc.local   — this machine only, untracked (edit freely)

source ~/.zshrc.base
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
ZSHRC
    fi
}

start_macos_services() {
    local hostname="$1"
    local simplebar_dir="$HOME/Library/Application Support/Übersicht/widgets/simple-bar"

    step "Starting local services"

    if [ -d "/Applications/AeroSpace.app" ]; then
        open -gj -a "AeroSpace" || true
    fi

    if [ -d "/Applications/Hammerspoon.app" ]; then
        open -gj -a "Hammerspoon" || true
        osascript <<'APPLESCRIPT' >/dev/null 2>&1 || true
tell application "Hammerspoon"
    reload config
end tell
APPLESCRIPT
    fi

    if [ "$hostname" != "work-macbook" ] || [ -d "$simplebar_dir" ]; then
        if [ -d "/Applications/Übersicht.app" ]; then
            open -gj -a "Übersicht" || true
        fi
    fi
}

install_external_assets() {
    local hostname="$1"
    local OS="$(uname -s)"
    local simplebar_dir="$HOME/Library/Application Support/Übersicht/widgets/simple-bar"

    if [ "$OS" != "Darwin" ]; then
        return 0
    fi

    step "Installing external assets"

    if [ "$hostname" != "work-macbook" ]; then
        if [ ! -d "$simplebar_dir" ]; then
            mkdir -p "$(dirname "$simplebar_dir")"
            git clone --depth 1 https://github.com/Jean-Tinland/simple-bar "$simplebar_dir"
        fi
    fi
}

is_app_installed() {
    local app_name="$1"
    [ -d "/Applications/${app_name}.app" ] || [ -d "$HOME/Applications/Home Manager Apps/${app_name}.app" ]
}

app_bundle_id() {
    local app_name="$1"

    case "$app_name" in
        AeroSpace) echo "bobko.aerospace" ;;
        Hammerspoon) echo "org.hammerspoon.Hammerspoon" ;;
        Übersicht) echo "tracesOf.Uebersicht" ;;
        *) echo "" ;;
    esac
}

app_running_state() {
    local app_name="$1"
    local bundle_id=""
    local result=""

    bundle_id="$(app_bundle_id "$app_name")"

    if [ -n "$bundle_id" ] && command -v launchctl >/dev/null 2>&1; then
        if launchctl print "gui/$(id -u)" 2>/dev/null | rg -q "application\\.${bundle_id//./\\.}\\."; then
            echo "running"
            return
        fi
    fi

    if command -v osascript >/dev/null 2>&1; then
        result=$(osascript -e "application \"${app_name}\" is running" 2>/dev/null || true)
        case "$result" in
            true)
                echo "running"
                return
                ;;
            false)
                echo "stopped"
                return
                ;;
        esac
    fi

    if command -v pgrep >/dev/null 2>&1; then
        if pgrep -x "$app_name" >/dev/null 2>&1; then
            echo "running"
            return
        fi
        local pgrep_status=$?
        if [ "$pgrep_status" -eq 1 ]; then
            echo "stopped"
            return
        fi
    fi

    echo "unknown"
}

status_line() {
    local label="$1"
    local state="$2"
    local detail="${3:-}"

    case "$state" in
        ok)
            printf "  ${GREEN}%-10s${NC} %s" "ok" "$label"
            ;;
        warn)
            printf "  ${YELLOW}%-10s${NC} %s" "warn" "$label"
            ;;
        error)
            printf "  ${RED}%-10s${NC} %s" "error" "$label"
            ;;
        *)
            printf "  %-10s %s" "$state" "$label"
            ;;
    esac

    if [ -n "$detail" ]; then
        printf " ${DIM}(%s)${NC}" "$detail"
    fi
    printf "\n"
}

check_macos_service() {
    local hostname="$1"
    local app_name="$2"
    local required="$3"
    local detail=""

    if ! is_app_installed "$app_name"; then
        if [ "$required" = "required" ]; then
            status_line "$app_name" "error" "not installed"
        else
            status_line "$app_name" "warn" "not installed"
        fi
        return
    fi

    local running_state
    running_state="$(app_running_state "$app_name")"

    case "$running_state" in
        running)
            status_line "$app_name" "ok" "running"
            ;;
        stopped)
            if [ "$required" = "required" ]; then
                detail="installed but not running"
                if [ "$app_name" = "Hammerspoon" ] || [ "$app_name" = "AeroSpace" ]; then
                    detail="${detail}; run 'dotfiles services'"
                fi
                status_line "$app_name" "warn" "$detail"
            else
                status_line "$app_name" "warn" "installed but not running"
            fi
            ;;
        *)
            status_line "$app_name" "warn" "installed; runtime state unavailable"
            ;;
    esac

    if [ "$app_name" = "Übersicht" ]; then
        local simplebar_dir="$HOME/Library/Application Support/Übersicht/widgets/simple-bar"
        if [ "$hostname" = "work-macbook" ] && [ -d "$simplebar_dir" ]; then
            status_line "simple-bar" "warn" "present on work profile"
        elif [ "$hostname" != "work-macbook" ] && [ -d "$simplebar_dir" ]; then
            status_line "simple-bar" "ok" "installed"
        elif [ "$hostname" != "work-macbook" ]; then
            status_line "simple-bar" "warn" "missing widget install"
        else
            status_line "simple-bar" "ok" "not enabled for work"
        fi
    fi
}

check_hammerspoon_config() {
    local config_dir="$HOME/.hammerspoon"
    local init_file="$config_dir/init.lua"

    if [ -L "$config_dir" ] || [ -d "$config_dir" ]; then
        status_line "Hammerspoon cfg" "ok" "$config_dir"
    else
        status_line "Hammerspoon cfg" "error" "missing $config_dir"
        return
    fi

    if [ -f "$init_file" ]; then
        status_line "init.lua" "ok" "$init_file"
    else
        status_line "init.lua" "error" "missing $init_file"
    fi
}

check_hammerspoon_permissions() {
    local db="$HOME/Library/Application Support/com.apple.TCC/TCC.db"

    if [ ! -f "$db" ]; then
        status_line "Accessibility" "warn" "unable to inspect TCC database"
        return
    fi

    local access
    access=$(sqlite3 "$db" "select auth_value from access where service='kTCCServiceAccessibility' and client like '%Hammerspoon.app' order by last_modified desc limit 1;" 2>/dev/null || true)

    if [ "$access" = "2" ]; then
        status_line "Accessibility" "ok" "granted to Hammerspoon"
    elif [ -n "$access" ]; then
        status_line "Accessibility" "warn" "Hammerspoon present but not granted"
    else
        status_line "Accessibility" "warn" "no Hammerspoon permission entry yet"
    fi
}

show_repo_status() {
    local changes
    changes="$(git -C "$DOTFILES_DIR" status --porcelain)"

    echo -e "${BOLD}Repo:${NC}"
    if [ -z "$changes" ]; then
        status_line "dotfiles git" "ok" "clean"
    else
        local change_count
        change_count=$(printf "%s\n" "$changes" | sed '/^$/d' | wc -l | tr -d ' ')
        status_line "dotfiles git" "warn" "$change_count uncommitted change(s)"
        git -C "$DOTFILES_DIR" status --short
    fi
}

show_runtime_status() {
    local hostname="$1"
    local OS="$(uname -s)"

    echo ""
    echo -e "${BOLD}Runtime:${NC}"

    if [ "$OS" != "Darwin" ]; then
        status_line "platform" "warn" "runtime checks currently implemented for macOS only"
        return
    fi

    status_line "hostname" "ok" "$hostname"
    check_macos_service "$hostname" "AeroSpace" "required"
    check_macos_service "$hostname" "Hammerspoon" "required"
    check_hammerspoon_config
    check_hammerspoon_permissions
    check_macos_service "$hostname" "Übersicht" "optional"
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
        init_progress 4
    else
        init_progress 2
    fi

    nix_rebuild "$hostname"

    if [ "$OS" = "Darwin" ]; then
        start_macos_services "$hostname"
    fi

    success "Done!"
    show_summary
}

cmd_services() {
    local hostname="${1:-$(detect_hostname)}"
    local OS="$(uname -s)"

    if [ "$OS" != "Darwin" ]; then
        error "Service startup is currently only defined for macOS."
        return 1
    fi

    header "Starting services for: $hostname"
    init_progress 1
    start_macos_services "$hostname"
    success "Services ready."
    show_summary
}

cmd_assets() {
    local hostname="${1:-$(detect_hostname)}"

    header "Installing assets for: $hostname"
    init_progress 1
    install_external_assets "$hostname"
    success "Assets installed."
}

cmd_regen() {
    header "Regenerating derived config"
    init_progress 1

    step "Syncing generated keymaps"
    run_sync_keymaps 0

    success "Regeneration complete."
}

cmd_snapshot() {
    local hostname="${1:-$(detect_hostname)}"
    local snapshot_file

    header "Capturing snapshot for: $hostname"
    init_progress 1

    step "Recording current state"
    snapshot_file="$(capture_snapshot "$hostname")"

    success "Snapshot captured."
    info "$snapshot_file"
}

cmd_preflight() {
    local hostname="${1:-$(detect_hostname)}"
    local snapshot_file

    header "Preflight for: $hostname"
    init_progress 2

    step "Capturing current state"
    snapshot_file="$(capture_snapshot "$hostname")"

    step "Running integrity checks"
    check_shell_scripts
    check_python_scripts
    run_sync_keymaps 1
    check_nix_eval "$hostname"

    success "Preflight passed."
    info "$snapshot_file"
}

cmd_check() {
    local hostname="${1:-$(detect_hostname)}"

    header "Checking repo for: $hostname"
    init_progress 4

    step "Checking shell scripts"
    check_shell_scripts

    step "Checking python scripts"
    check_python_scripts

    step "Checking generated config drift"
    run_sync_keymaps 1

    step "Checking nix evaluation"
    check_nix_eval "$hostname"

    success "Checks passed."
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
    local hostname="${1:-$(detect_hostname)}"

    header "Status for: $hostname"
    show_repo_status
    show_runtime_status "$hostname"
}

cmd_doctor() {
    local hostname="${1:-$(detect_hostname)}"
    local OS="$(uname -s)"
    local failures=0

    header "Doctor for: $hostname"
    show_repo_status
    show_runtime_status "$hostname"

    echo ""
    echo -e "${BOLD}Checks:${NC}"

    if [ "$OS" = "Darwin" ]; then
        if ! is_app_installed "AeroSpace"; then
            status_line "AeroSpace install" "error" "missing app"
            failures=$((failures + 1))
        fi
        if ! is_app_installed "Hammerspoon"; then
            status_line "Hammerspoon install" "error" "missing app"
            failures=$((failures + 1))
        fi
        if [ ! -L "$HOME/.hammerspoon" ] && [ ! -d "$HOME/.hammerspoon" ]; then
            status_line "Hammerspoon link" "error" "missing ~/.hammerspoon"
            failures=$((failures + 1))
        fi
        local hammerspoon_state
        local aerospace_state
        hammerspoon_state="$(app_running_state "Hammerspoon")"
        aerospace_state="$(app_running_state "AeroSpace")"

        if [ "$hammerspoon_state" = "stopped" ]; then
            status_line "Hammerspoon runtime" "warn" "not running; run 'dotfiles services'"
            failures=$((failures + 1))
        elif [ "$hammerspoon_state" = "unknown" ]; then
            status_line "Hammerspoon runtime" "warn" "runtime state unavailable"
        fi

        if [ "$aerospace_state" = "stopped" ]; then
            status_line "AeroSpace runtime" "warn" "not running; run 'dotfiles services'"
            failures=$((failures + 1))
        elif [ "$aerospace_state" = "unknown" ]; then
            status_line "AeroSpace runtime" "warn" "runtime state unavailable"
        fi
    else
        status_line "platform" "warn" "doctor currently focuses on macOS desktop services"
    fi

    echo ""
    if [ "$failures" -eq 0 ]; then
        success "Doctor found no blocking issues."
    else
        warn "Doctor found $failures issue(s)."
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

    if [ "$OS" = "Darwin" ]; then
        start_macos_services "$hostname"
        SUMMARY_ITEMS+=("Local desktop services started")
    fi

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
    regen)      cmd_regen ;;
    check)      cmd_check "${COMMAND_ARGS[@]}" ;;
    assets)     cmd_assets "${COMMAND_ARGS[@]}" ;;
    snapshot)   cmd_snapshot "${COMMAND_ARGS[@]}" ;;
    preflight)  cmd_preflight "${COMMAND_ARGS[@]}" ;;
    services)   cmd_services "${COMMAND_ARGS[@]}" ;;
    doctor)     cmd_doctor "${COMMAND_ARGS[@]}" ;;
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
        echo "  regen                  Regenerate derived config from source manifests"
        echo "  check [hostname]       Verify repo integrity and config drift"
        echo "  assets [hostname]      Install explicit external assets"
        echo "  snapshot [hostname]    Capture current repo and runtime state for cutover"
        echo "  preflight [hostname]   Capture a snapshot and run integrity checks"
        echo "  services [hostname]    Start/reload local desktop services"
        echo "  doctor [hostname]      Diagnose local setup and service health"
        echo "  pull                   Pull changes (rebuilds only if nix files changed)"
        echo "  push [message]         Commit and push all changes"
        echo "  status [hostname]      Show repo state and local service status"
        echo ""
        echo "Flags:"
        echo "  -v, --verbose          Show detailed output"
        ;;
esac
