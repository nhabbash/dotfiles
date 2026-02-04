# Git configuration
{ config, pkgs, lib, ... }:

{
  home.file.".gitconfig".source = ../configs/git/config;
}
