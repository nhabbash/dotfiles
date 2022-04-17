#/bin/bash

### ZSH
# init plugins
mkdir -p ~/.zsh/plugins 
git clone git@github.com:zdharma-zmirror/fast-syntax-highlighting.git ~/.zsh/plugins/fast-syntax-highlighting
git clone git@github.com:zsh-users/zsh-autosuggestions.git ~/.zsh/plugins/zsh-autosuggestions
git clone git@github.com:zsh-users/zsh-completions.git ~/.zsh/plugins//zsh-completions
git clone git@github.com:unixorn/fzf-zsh-plugin.git ~/.zsh/plugins/fzf-zsh-plugin

### TMUX
git clone git@github.com:tmux-plugins/tpm.git ~/.tmux/plugins/tpm

### Stow
cd ~/dotfiles
stow zsh
stow xdg
stow tmux
stow starship