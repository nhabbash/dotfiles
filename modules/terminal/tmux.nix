# Tmux configuration
{ config, dotfilesDir, ... }:

{
  home.file.".tmux.conf".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/configs/tmux/tmux.conf";
}
