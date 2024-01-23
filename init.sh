#/bin/bash

### ZSH
# init plugins
mkdir -p ~/.zsh/plugins 
git clone https://github.com/z-shell/F-Sy-H.git  ~/.zsh/plugins/fast-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions.git ~/.zsh/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-completions.git  ~/.zsh/plugins//zsh-completions
git clone https://github.com/unixorn/fzf-zsh-plugin.git ~/.zsh/plugins/fzf-zsh-plugin

### TMUX
git clone https://github.com/tmux-plugins/tpm.git ~/.tmux/plugins/tpm

### Stow
cd $(pwd)

for dir in */; do
  stow -D $dir
done

for dir in */; do
  stow $dir
done
