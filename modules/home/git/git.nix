# Git configuration
{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    git
    gh
    lazygit
    gitleaks
  ];

  home.file.".gitconfig".source = ../../../configs/git/config;
}
