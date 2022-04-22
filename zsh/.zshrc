### PATH
export PATH=$HOME/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:/home/linuxbrew/.linuxbrew/bin/brew:$PATH

### ZSH HOME
export ZSH=$HOME/.zsh

### ---- ADDITIONS ----
source $ZSH/.alias
source $ZSH/.devrc

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

### ctrl+arrows
bindkey "\e[1;5C" forward-word
bindkey "\e[1;5D" backward-word

# urxvt
bindkey "\eOc" forward-word
bindkey "\eOd" backward-word

### ctrl+delete
bindkey "\e[3;5~" kill-word
# urxvt
bindkey "\e[3^" kill-word

### ctrl+backspace
bindkey '^H' backward-kill-word

### ctrl+shift+delete
bindkey "\e[3;6~" kill-line
# urxvt
bindkey "\e[3@" kill-line


### ---- PLUGINS -----
source $ZSH/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
source $ZSH/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source $ZSH/plugins/fzf-zsh-plugin/fzf-zsh-plugin.plugin.zsh
fpath=($ZSH/plugins/zsh-completions/src $fpath)
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# ---- THEMES ----
#source $ZSH/themes/common/common.zsh-theme

export STARSHIP_CONFIG=~/.config/starship/pure_prompt.toml
eval "$(starship init zsh)"

# ### START TMUX 
# if command -v tmux &> /dev/null && [ -n "$PS1" ] && [[ ! "$TERM" =~ screen ]] && [[ ! "$TERM" =~ tmux ]] && [ -z "$TMUX" ]; then
#    exec /usr/bin/tmux new-session -t main
# fi

# if [[ ! $(tmux ls)  ]]; then 
#   tmux new-session -t main
# fi
