# Zellij terminal multiplexer configuration
{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    zellij
  ];

  xdg.configFile = {
    "zellij/config.kdl".source = ../../configs/zellij/config.kdl;
    "zellij/themes/catppuccin-mocha.kdl".source = ../../configs/zellij/themes/catppuccin-mocha.kdl;
    "zellij/layouts/default.kdl".source = ../../configs/zellij/layouts/default.kdl;
  };
}
