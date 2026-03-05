# Ghostty terminal configuration
{ config, pkgs, ... }:

{
  xdg.configFile."ghostty/config".source = ../../configs/ghostty/config;
}
