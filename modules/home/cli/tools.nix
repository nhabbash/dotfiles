# CLI tools
{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    zsh starship fzf tmux
    bat eza ripgrep fd jq tree htop
    stow glow
  ];

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultOptions = [ "--height 40%" "--layout=reverse" "--border" ];
  };

  programs.bat = {
    enable = true;
    config = {
      theme = "TwoDark";
      style = "numbers,changes";
    };
  };

  programs.eza = {
    enable = true;
    icons = "auto";
    git = true;
  };
}
