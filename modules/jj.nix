# Jujutsu version control configuration
{ config, pkgs, ... }:

{
  xdg.configFile."jj/config.toml".source = ../configs/jj/config.toml;
}
