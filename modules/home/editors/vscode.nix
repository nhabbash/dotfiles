# VS Code configuration
{ config, pkgs, lib, ... }:

let
  dotfilesPath = ../../../configs;
in
{
  # VS Code is typically installed via Homebrew cask, not Nix
  # But we can manage settings via symlinks

  # Optional: Symlink settings from configs/
  # Note: VS Code on macOS uses ~/Library/Application Support/Code/User/
  # Uncomment when you have settings to manage:
  #
  # home.file."Library/Application Support/Code/User/settings.json" = {
  #   source = "${dotfilesPath}/vscode/settings.json";
  # };
  #
  # home.file."Library/Application Support/Code/User/keybindings.json" = {
  #   source = "${dotfilesPath}/vscode/keybindings.json";
  # };
}
