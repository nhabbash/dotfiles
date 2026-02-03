# CLI tools configuration
{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    # Shell & Terminal
    zsh
    starship
    fzf
    tmux

    # Modern CLI tools
    bat
    eza
    ripgrep
    fd
    jq
    tree
    htop

    # Misc
    stow
    glow
  ];

  # FZF
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultOptions = [ "--height 40%" "--layout=reverse" "--border" ];
  };

  # Bat (better cat)
  programs.bat = {
    enable = true;
    config = {
      theme = "TwoDark";
      style = "numbers,changes";
    };
  };

  # Eza (better ls)
  programs.eza = {
    enable = true;
    icons = "auto";
    git = true;
  };
}
