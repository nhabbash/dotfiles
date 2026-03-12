# Zellij integration — tab naming + tmux shim

[[ -z "$ZELLIJ" || -z "$ZELLIJ_PANE_ID" ]] && return

# --- Tab naming (plugin-based, manual-first) ---
typeset -g ZELLIJ_TAB_AUTO_RENAME="${ZELLIJ_TAB_AUTO_RENAME:-1}"
typeset -g ZELLIJ_TAB_AUTO_LOCKED="${ZELLIJ_TAB_AUTO_LOCKED:-0}"
typeset -g _ZELLIJ_LAST_TAB_NAME=""

function _zellij_tab_name_pipe() {
  local title="$1"
  title="${title//\\/\\\\}"
  title="${title//\"/\\\"}"
  title="${title//\{/\{\{}"
  title="${title//\}/\}\}}"
  { zellij pipe --name change-tab-name -- "{\"pane_id\": \"$ZELLIJ_PANE_ID\", \"name\": \"$title\"}"; } >/dev/null 2>&1 &!
}

function _zellij_tab_name_from_cwd() {
  local dir="$PWD"
  if [[ "$dir" == "$HOME" ]]; then
    dir="~"
  else
    dir="${dir##*/}"
  fi
  local name="{tab_position}: $dir"
  [[ "$name" == "$_ZELLIJ_LAST_TAB_NAME" ]] && return
  _ZELLIJ_LAST_TAB_NAME="$name"
  _zellij_tab_name_pipe "$name"
}

function zellij_tab_auto_precmd() {
  if [[ "$ZELLIJ_TAB_AUTO_RENAME" != "1" || "$ZELLIJ_TAB_AUTO_LOCKED" == "1" ]]; then
    return
  fi
  _zellij_tab_name_from_cwd
}

function tab_auto_on()     { ZELLIJ_TAB_AUTO_RENAME=1; ZELLIJ_TAB_AUTO_LOCKED=0; _zellij_tab_name_from_cwd; }
function tab_auto_off()    { ZELLIJ_TAB_AUTO_RENAME=0; }
function tab_unlock_name() { ZELLIJ_TAB_AUTO_LOCKED=0; }
function tab_name() {
  local title="$*"
  if [[ -z "$title" ]]; then
    echo "usage: tab-name <name>"
    return 1
  fi
  ZELLIJ_TAB_AUTO_LOCKED=1
  _zellij_tab_name_pipe "$title"
}

alias tab-auto-on='tab_auto_on'
alias tab-auto-off='tab_auto_off'
alias tab-unlock-name='tab_unlock_name'
alias tab-name='tab_name'
alias rename-tab='tab_name'

autoload -Uz add-zsh-hook
add-zsh-hook precmd zellij_tab_auto_precmd

# --- Claude Code agent teams (tmux shim) ---
source "$HOME/.local/share/zellij-tmux-shim/activate.sh" 2>/dev/null || true
