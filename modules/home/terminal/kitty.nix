# Kitty terminal configuration
{ config, pkgs, ... }:

let
  dotfilesPath = ../../../configs;
in
{
  # Kitty config files (symlinked from configs/)
  xdg.configFile = {
    "kitty/kitty.conf".source = "${dotfilesPath}/kitty/kitty.conf";
    "kitty/current-theme.conf".source = "${dotfilesPath}/kitty/current-theme.conf";
  };
}
