### PATH
export PATH=$HOME/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:/home/linuxbrew/.linuxbrew/bin/brew:export:$HOME/.krew/bin:$PATH

### ZSH HOME
export ZSH=$HOME/.zsh

# The following lines were added by compinstall
zstyle :compinstall filename '/Users/nassim/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall

### ---- HISTORY ----
export HISTFILE=$ZSH/.zsh_history

# How many commands zsh will load to memory.
export HISTSIZE=10000

# How maney commands history will save on file.
export SAVEHIST=20000

# History won't save duplicates.
setopt HIST_IGNORE_ALL_DUPS

# History won't show duplicates on search.
setopt HIST_FIND_NO_DUPS

### ---- KEYBINDINGS ----

### ---- PLUGINS -----
source $ZSH/plugins/fast-syntax-highlighting/F-Sy-H.plugin.zsh
source $ZSH/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source $ZSH/plugins/fzf-zsh-plugin/fzf-zsh-plugin.plugin.zsh
fpath=($ZSH/plugins/zsh-completions/src $fpath)
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# ---- THEMES ----
#source $ZSH/themes/common/common.zsh-theme

export STARSHIP_CONFIG=~/.config/starship/tokyo.toml
eval "$(starship init zsh)"

# ### START TMUX 
# if command -v tmux &> /dev/null && [ -n "$PS1" ] && [[ ! "$TERM" =~ screen ]] && [[ ! "$TERM" =~ tmux ]] && [ -z "$TMUX" ]; then
#    exec /usr/bin/tmux new-session -t main
# fi

# if [[ ! $(tmux ls)  ]]; then 
#   tmux new-session -t main
# fi

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/usr/local/bin/google-cloud-sdk/path.zsh.inc' ]; then . '/usr/local/bin/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/usr/local/bin/google-cloud-sdk/completion.zsh.inc' ]; then . '/usr/local/bin/google-cloud-sdk/completion.zsh.inc'; fi

### ---- ADDITIONS ----
source $ZSH/.alias
source $ZSH/.devrc