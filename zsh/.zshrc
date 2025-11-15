# Performance optimizations
DISABLE_AUTO_UPDATE="true"
DISABLE_MAGIC_FUNCTIONS="true"
DISABLE_COMPFIX="true"

# Cache completions aggressively
autoload -Uz compinit
if [ "$(date +'%j')" != "$(stat -f '%Sm' -t '%j' ~/.zcompdump 2>/dev/null)" ]; then
    compinit
else
    compinit -C
fi

# Oh My Zsh path
export ZSH="$HOME/.oh-my-zsh"

# Theme config
export STARSHIP_CONFIG=~/.config/starship/tokyo.toml
eval "$(starship init zsh)"

# Carefully ordered plugins (syntax highlighting must be last)
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
)

# Source Oh My Zsh
source $ZSH/oh-my-zsh.sh

# Autosuggest settings
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#663399,standout"
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE="20"
ZSH_AUTOSUGGEST_USE_ASYNC=1

# Alias expansion function
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

# Lazy load SSH agent
function _load_ssh_agent() {
    if [ -z "$SSH_AUTH_SOCK" ]; then
        eval "$(ssh-agent -s)" > /dev/null
        ssh-add ~/.ssh/id_github_sign_and_auth 2>/dev/null
    fi
}
autoload -U add-zsh-hook
add-zsh-hook precmd _load_ssh_agent

# Path configurations  
export PATH=$HOME/.volta/bin:$HOME/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:/home/linuxbrew/.linuxbrew/bin/brew:$HOME/.krew/bin:$PATH

# Source aliases last
[ -f ~/.zsh_aliases ] && source ~/.zsh_aliases

# monday.com stuff
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
pyenv global 2.7.18
export PYTHON=python
export AWS_PROFILE=default
export AWS_REGION=us-east-1

# Claude Code on Monday GCloud
export ANTHROPIC_VERTEX_PROJECT_ID="internal-claude-code-ug-3"
export CLOUD_ML_REGION="europe-west1" 
export CLAUDE_CODE_USE_VERTEX=1
alias claude="claude-vertex"


# monday.com dotfiles
[ -f ~/dotfiles/.bash_profile ] && source ~/dotfiles/.bash_profile
[ -f ~/dotfiles/.bash_aliases ] && source ~/dotfiles/.bash_aliases

# Task Master aliases added on 29/09/2025
alias tm='task-master'
alias taskmaster='task-master'
export PATH="$HOME/.monday-mirror/bin:$PATH"
