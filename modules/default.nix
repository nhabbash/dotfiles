# Home Manager modules entry point
{ config, pkgs, lib, username, isWork, enableGui, ... }:

let
  coreModules = [
    ./packages.nix
    ./shell/zsh.nix
    ./shell/starship.nix
    ./shell/aliases.nix
    ./git.nix
    ./terminal/zellij.nix
  ];

  guiModules = [
    ./terminal/kitty.nix
  ];
in
{
  imports = coreModules ++ lib.optionals enableGui guiModules;

  home.stateVersion = "24.05";
  programs.home-manager.enable = true;

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    XDG_CONFIG_HOME = "${config.home.homeDirectory}/.config";
    XDG_DATA_HOME = "${config.home.homeDirectory}/.local/share";
    XDG_CACHE_HOME = "${config.home.homeDirectory}/.cache";
  };

  _module.args = { inherit isWork enableGui; };

  # Tool-specific configuration
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
