# Neovim configuration
{ config, pkgs, ... }:

let
  dotfilesPath = ../../../configs;
in
{
  home.packages = with pkgs; [
    neovim
  ];

  # Optional: Use external init.lua from configs/
  # Uncomment when you have a neovim config to manage
  # xdg.configFile."nvim/init.lua".source = "${dotfilesPath}/neovim/init.lua";
}
