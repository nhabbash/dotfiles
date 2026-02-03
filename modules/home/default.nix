# Home Manager modules entry point
{ config, pkgs, lib, username, hostname, isWork, enableGui, ... }:

let
  # CLI-only modules (always included)
  cliModules = [
    ./shell/zsh.nix
    ./shell/starship.nix
    ./shell/aliases.nix
    ./git/git.nix
    ./cli/tools.nix
    ./editors/neovim.nix
    ./kubernetes/k8s.nix
  ];

  # GUI modules (only when enableGui = true)
  guiModules = [
    ./terminal/kitty.nix
    ./terminal/zellij.nix
    ./editors/vscode.nix
  ];
in
{
  imports = cliModules ++ lib.optionals enableGui guiModules;

  # Basic home configuration
  home.stateVersion = "24.05";

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  # Environment variables
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    XDG_CONFIG_HOME = "${config.home.homeDirectory}/.config";
    XDG_DATA_HOME = "${config.home.homeDirectory}/.local/share";
    XDG_CACHE_HOME = "${config.home.homeDirectory}/.cache";
  };

  # Pass flags to other modules
  _module.args = { inherit isWork enableGui; };
}
