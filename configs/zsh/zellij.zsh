# Zellij integration — manual tab naming + tmux shim

[[ -z "$ZELLIJ" || -z "$ZELLIJ_PANE_ID" ]] && return

# --- Manual tab naming (plugin-backed) ---

function _zellij_tab_name_pipe() {
  local title="$1"
  title="${title//\\/\\\\}"
  title="${title//\"/\\\"}"
  zellij pipe --name change-tab-name -- "{\"pane_id\": \"$ZELLIJ_PANE_ID\", \"name\": \"$title\"}" >/dev/null 2>&1
}
function tab_name() {
  local title="$*"
  if [[ -z "$title" ]]; then
    echo "usage: tab-name <name>"
    return 1
  fi
  _zellij_tab_name_pipe "$title"
}

alias tab-name='tab_name'
alias rename-tab='tab_name'

# --- Claude Code agent teams (tmux shim) ---
source "$HOME/.local/share/zellij-tmux-shim/activate.sh" 2>/dev/null || true
