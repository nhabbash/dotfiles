# Shared aliases — loaded on all machines

# Navigation
alias ls="eza --icons auto --git"
alias ll="eza -l --icons --sort newest --group-directories-first -s extension"
alias la="eza -a --icons auto --git"
alias lt="eza --tree --icons auto --git"
alias c="codium ."
alias s="cursor ."
alias e="exit"
alias dev="cd ~/Development"

# Git
alias g="git"
alias gs="git status"
alias ga="git add ."
alias gc="git commit -m"
alias gagc="git add . && git commit -m"
alias gp="git fetch -p"
alias pp="git pull --rebase && git push"
alias gcom="git checkout main"
alias gcol="git checkout -"
alias gb="git checkout -b"
alias gcl="git clone"

# Package managers
alias bi="HOMEBREW_NO_AUTO_UPDATE=1 brew install"
alias pi="pnpm i"
alias prd="pnpm run dev"
alias prb="pnpm run build"

# Tools
alias zz="zellij"
alias zs="zellij attach -c"
alias zrs="zellij action rename-session"
alias tdl="tree -a -I 'node_modules|.svelte-kit|.git' --dirsfirst"

# Dotfiles & Nix
alias dotfiles="$DOTFILES_DIR/scripts/dotfiles.sh"
alias rebuild="$DOTFILES_DIR/scripts/dotfiles.sh rebuild"
alias nfu="nix flake update $DOTFILES_DIR"
alias ngc="nix-collect-garbage -d && nix store optimise"

# Ghostty CRT shader toggle
alias crt-on='$DOTFILES_DIR/scripts/crt-on'
alias crt-off='$DOTFILES_DIR/scripts/crt-off'

# zellij
alias zj='zellij'

alias crt-lab='$DOTFILES_DIR/scripts/crt-lab'
alias saver='screensaver'
alias tte-saver='screensaver'
