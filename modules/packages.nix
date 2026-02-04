# All CLI/TUI packages
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Shell
    zsh
    starship
    fzf
    tmux

    # Files & Search
    bat
    eza
    ripgrep
    fd
    tree

    # VCS
    git
    gh
    lazygit
    gitleaks
    jujutsu
    lazyjj

    # Editors
    neovim

    # Kubernetes
    kubectl
    kubectx
    k9s

    # Utilities
    jq
    htop
    curl
    wget
    stow
    glow
  ];
}
