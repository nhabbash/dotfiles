# Home Manager modules entry point
{ config, pkgs, lib, username, isWork, enableGui, ... }:

let
  cliModules = [
    ./shell/zsh.nix
    ./shell/starship.nix
    ./shell/aliases.nix
    ./git/git.nix
    ./cli/tools.nix
    ./editors/neovim.nix
    ./kubernetes/k8s.nix
    ./terminal/zellij.nix
  ];

  guiModules = [
    ./terminal/kitty.nix
  ];
in
{
  imports = cliModules ++ lib.optionals enableGui guiModules;

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
}
