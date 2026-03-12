# Jujutsu version control configuration
{ config, dotfilesDir, ... }:

{
  xdg.configFile."jj/config.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/configs/jj/config.toml";
}
