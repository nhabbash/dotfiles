#!/bin/bash
# Shared helper functions for dotfiles scripts

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

STEP=0
TOTAL_STEPS=0
START_TIME=$(date +%s)
VERBOSE=${VERBOSE:-false}
LOG_FILE=$(mktemp)
trap "rm -f $LOG_FILE" EXIT

init_progress() {
    TOTAL_STEPS=$1
    STEP=0
    START_TIME=$(date +%s)
}

step() {
    ((STEP++))
    printf "${BOLD}[%d/%d]${NC} %s...\n" "$STEP" "$TOTAL_STEPS" "$1"
}

success() {
    local elapsed=$(($(date +%s) - START_TIME))
    echo ""
    echo -e "${GREEN}==>${NC} ${BOLD}$1${NC} ${DIM}(${elapsed}s)${NC}"
}

error() {
    echo -e "${RED}==> Error:${NC} $1" >&2
}

warn() {
    echo -e "${YELLOW}==> Warning:${NC} $1"
}

info() {
    echo -e "  ${GREEN}✓${NC} $1"
}

header() {
    echo -e "${GREEN}==>${NC} ${BOLD}$1${NC}"
    echo ""
}

run_quiet() {
    if $VERBOSE; then
        "$@"
        return $?
    fi

    if ! "$@" >> "$LOG_FILE" 2>&1; then
        echo ""
        error "Command failed: $1"
        echo -e "${DIM}Last 30 lines of output:${NC}"
        tail -30 "$LOG_FILE"
        return 1
    fi
    return 0
}

parse_darwin_summary() {
    local log="$1"
    local items=()

    grep -q "system defaults" "$log" && items+=("System preferences applied")
    grep -q "restarting Dock" "$log" && items+=("Dock restarted")
    grep -q "setting up /etc" "$log" && items+=("System files configured")
    grep -q "setting up launchd" "$log" && items+=("Services configured")
    grep -q "setting up /Applications" "$log" && items+=("Applications linked")
    grep -q "configuring keyboard" "$log" && items+=("Keyboard settings applied")
    grep -q "Nix Fonts" "$log" && items+=("Fonts installed")

    for item in "${items[@]}"; do
        info "$item"
    done
}

parse_hm_summary() {
    local log="$1"
    local items=()

    local link_count
    link_count=$(grep -c "Linking" "$log" 2>/dev/null | tr -d '[:space:]' || echo "0")
    [[ -z "$link_count" ]] && link_count=0
    [[ "$link_count" =~ ^[0-9]+$ ]] && [[ "$link_count" -gt 0 ]] && items+=("$link_count home files linked")

    grep -q "Creating home file links" "$log" 2>/dev/null && [[ "$link_count" -eq 0 ]] && items+=("Home files updated")
    grep -q "installPackages" "$log" 2>/dev/null && items+=("Packages synchronized")
    grep -q "batCache" "$log" 2>/dev/null && items+=("Bat cache updated")

    for item in "${items[@]}"; do
        info "$item"
    done
}

show_summary() {
    echo ""
    echo -e "${BOLD}Summary:${NC}"
    parse_darwin_summary "$LOG_FILE"
    parse_hm_summary "$LOG_FILE"
}

command_exists() {
    command -v "$1" &> /dev/null
}
