# GitHub CLI configuration
{ config, dotfilesDir, ... }:

{
  xdg.configFile."gh/config.yml".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/configs/gh/config.yml";
}
