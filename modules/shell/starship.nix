# Starship prompt configuration
{ config, dotfilesDir, ... }:

{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  xdg.configFile."starship.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/configs/starship.toml";
}
