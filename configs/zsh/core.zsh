# Core shell setup — PATH, tools, performance
#
# Zsh config layout:
#   configs/zsh/*.zsh          Edit these directly, changes are instant (no rebuild)
#     core.zsh                 PATH, homebrew, SSH, keybindings
#     aliases.zsh              All aliases
#     functions.zsh            Shell functions
#     claude.zsh               Claude Code env config
#     zellij.zsh               Zellij tab naming + tmux shim
#     work.zsh / personal.zsh  Machine-profile specific (auto-selected by nix)
#   ~/.zshrc.local             Machine-local experiments, not tracked
#
#   modules/shell/zsh.nix      Plugins, oh-my-zsh, autosuggestions, history settings
#                              Edit this + run 'dotfiles rebuild' to apply

# Homebrew
if [[ -f /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Performance
DISABLE_AUTO_UPDATE="true"
DISABLE_MAGIC_FUNCTIONS="true"
DISABLE_COMPFIX="true"

# SSH agent
if [ -z "$SSH_AUTH_SOCK" ]; then
  eval "$(ssh-agent -s)" > /dev/null
  ssh-add ~/.ssh/id_github_sign_and_auth 2>/dev/null
fi

# Volta
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# Expand aliases on space
globalias() {
  if [[ $LBUFFER =~ '[a-zA-Z0-9]+$' ]]; then
    zle _expand_alias
    zle expand-word
  fi
  zle self-insert
}
zle -N globalias
bindkey " " globalias
bindkey "^[[Z" magic-space
bindkey -M isearch " " magic-space

# Dotfiles dirty detection (login shells only)
if [[ -o login ]] && [[ -d "$DOTFILES_DIR/.git" ]]; then
  local _df_count
  _df_count="$(git -C "$DOTFILES_DIR" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
  if [[ "$_df_count" -gt 0 ]]; then
    echo "dotfiles: $_df_count uncommitted change(s) — run 'dotfiles push' or 'dotfiles status'"
  fi
fi
