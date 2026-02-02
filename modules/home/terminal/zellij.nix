# Zellij terminal multiplexer configuration
{ config, pkgs, ... }:

let
  dotfilesPath = ../../../configs;
in
{
  home.packages = with pkgs; [
    zellij
  ];

  # Zellij config files (symlinked from configs/)
  xdg.configFile = {
    "zellij/config.kdl".source = "${dotfilesPath}/zellij/config.kdl";
    "zellij/themes/catppuccin-mocha.kdl".source = "${dotfilesPath}/zellij/themes/catppuccin-mocha.kdl";
    "zellij/layouts/default.kdl".source = "${dotfilesPath}/zellij/layouts/default.kdl";
  };
}
