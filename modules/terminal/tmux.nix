# Tmux configuration
{ config, pkgs, ... }:

{
  home.file.".tmux.conf".source = ../../configs/tmux/tmux.conf;
}
