# GitHub CLI configuration
{ config, pkgs, ... }:

{
  xdg.configFile."gh/config.yml".source = ../configs/gh/config.yml;
}
