# Ghostty terminal configuration
# macOS uses ~/Library/Application Support/com.mitchellh.ghostty/
# Linux uses ~/.config/ghostty/
{ config, pkgs, lib, dotfilesDir, ... }:

let
  isDarwin = pkgs.stdenv.isDarwin;
  mkLink = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/${path}";
in
{
  xdg.configFile."ghostty/config" = lib.mkIf (!isDarwin) {
    source = mkLink "configs/ghostty/config";
  };

  home.file."Library/Application Support/com.mitchellh.ghostty/config" = lib.mkIf isDarwin {
    source = mkLink "configs/ghostty/config";
  };

  xdg.configFile."ghostty/shaders/cursor_warp.glsl".source = mkLink "configs/ghostty/shaders/cursor_warp.glsl";
}
