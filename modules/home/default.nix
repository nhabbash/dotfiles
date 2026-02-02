# Home Manager modules entry point
{ config, pkgs, lib, username, hostname, isWork, ... }:

let
  homeDirectory = "/Users/${username}";
in
{
  imports = [
    ./shell/zsh.nix
    ./shell/starship.nix
    ./shell/aliases.nix
    ./terminal/kitty.nix
    ./terminal/zellij.nix
    ./git/git.nix
    ./cli/tools.nix
    ./editors/neovim.nix
    ./editors/vscode.nix
    ./kubernetes/k8s.nix
  ];

  # Basic home configuration
  home = {
    inherit username homeDirectory;
    stateVersion = "24.05";
  };

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  # Environment variables
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    XDG_CONFIG_HOME = "${homeDirectory}/.config";
    XDG_DATA_HOME = "${homeDirectory}/.local/share";
    XDG_CACHE_HOME = "${homeDirectory}/.cache";
  };

  # Pass isWork flag to other modules
  _module.args = { inherit isWork; };
}
