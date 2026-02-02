# ==============================================================================
# Performance Optimizations
# ==============================================================================
DISABLE_AUTO_UPDATE="true"
DISABLE_MAGIC_FUNCTIONS="true"
DISABLE_COMPFIX="true"

# Cache completions aggressively (rebuild once per day)
autoload -Uz compinit
if [ "$(date +'%j')" != "$(stat -f '%Sm' -t '%j' ~/.zcompdump 2>/dev/null)" ]; then
    compinit
else
    compinit -C
fi

# ==============================================================================
# Oh My Zsh Configuration
# ==============================================================================
export ZSH="$HOME/.oh-my-zsh"

# Plugins (syntax highlighting must be last)
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# Starship prompt (after Oh My Zsh)
export STARSHIP_CONFIG=~/.config/starship/tokyo.toml
eval "$(starship init zsh)"

# ==============================================================================
# PATH Configuration (consolidated)
# ==============================================================================
export PATH="\
$HOME/.volta/bin:\
$HOME/.local/bin:\
$HOME/.monday-mirror/bin:\
$HOME/.krew/bin:\
$HOME/.lmstudio/bin:\
/usr/local/sbin:\
/usr/local/bin:\
/usr/sbin:\
/usr/bin:\
/sbin:\
/bin:\
/usr/games:\
/usr/local/games:\
/snap/bin:\
/home/linuxbrew/.linuxbrew/bin/brew:\
$PATH"

# Pyenv path
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"

# ==============================================================================
# Environment Variables
# ==============================================================================

# Python
eval "$(pyenv init -)"
pyenv global 2.7.18
export PYTHON=python

# AWS
export AWS_PROFILE=default
export AWS_REGION=us-east-1

# NVM (for tools like monday-mirror that expect it)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# ------------------------------------------------------------------------------
# Monday.com
# ------------------------------------------------------------------------------
export NODE_EXTRA_CA_CERTS="$HOME/.certs/all-ca-bundle.pem"

# Claude Code on Monday GCloud
export ANTHROPIC_VERTEX_PROJECT_ID="internal-claude-code-ug-3"
export CLOUD_ML_REGION="europe-west1"
export CLAUDE_CODE_USE_VERTEX=1
export ANTHROPIC_MODEL="opus"
alias claude="claude-vertex"

# Task Master
alias tm='task-master'
alias taskmaster='task-master'

# ==============================================================================
# Plugin Settings
# ==============================================================================
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#663399,standout"
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE="20"
ZSH_AUTOSUGGEST_USE_ASYNC=1

# ==============================================================================
# Functions & Key Bindings
# ==============================================================================

# Alias expansion on space
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

# SSH agent (lazy load, runs once per session)
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)" > /dev/null
    ssh-add ~/.ssh/id_github_sign_and_auth 2>/dev/null
fi

# ==============================================================================
# Conditional Blocks
# ==============================================================================

# Zellij tab name support
if [[ -n "$ZELLIJ" ]]; then
    function zellij_tab_name_update_pre() {
        local cmd="${1[(w)1]}"
        if [[ -n "$cmd" ]]; then
            { zellij action rename-tab "$cmd" } >/dev/null 2>&1 &!
        fi
    }

    function zellij_tab_name_update_post() {
        # Optional: rename to current directory after command finishes
        # { zellij action rename-tab "${PWD##*/}" } >/dev/null 2>&1 &!
        :
    }

    autoload -Uz add-zsh-hook
    add-zsh-hook preexec zellij_tab_name_update_pre
    add-zsh-hook precmd zellij_tab_name_update_post
fi

# ==============================================================================
# External Sources
# ==============================================================================
[ -f ~/.zsh_aliases ] && source ~/.zsh_aliases
[ -f ~/dotfiles/.bash_profile ] && source ~/dotfiles/.bash_profile
[ -f ~/dotfiles/.bash_aliases ] && source ~/dotfiles/.bash_aliases
