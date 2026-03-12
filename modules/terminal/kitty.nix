# Kitty terminal configuration
{ config, dotfilesDir, ... }:

let
  mkLink = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/${path}";
in
{
  xdg.configFile = {
    "kitty/kitty.conf".source = mkLink "configs/kitty/kitty.conf";
    "kitty/current-theme.conf".source = mkLink "configs/kitty/current-theme.conf";
  };
}
