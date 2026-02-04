# Kitty terminal configuration
{ config, pkgs, ... }:

{
  xdg.configFile = {
    "kitty/kitty.conf".source = ../../configs/kitty/kitty.conf;
    "kitty/current-theme.conf".source = ../../configs/kitty/current-theme.conf;
  };
}
