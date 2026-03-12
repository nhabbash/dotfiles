# Git configuration
{ config, dotfilesDir, ... }:

{
  home.file.".gitconfig".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/configs/git/config";
}
