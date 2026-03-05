# Ghostty terminal configuration
# macOS uses ~/Library/Application Support/com.mitchellh.ghostty/
# Linux uses ~/.config/ghostty/
{ config, pkgs, lib, ... }:

let
  isDarwin = pkgs.stdenv.isDarwin;
in
{
  # Linux: XDG config path
  xdg.configFile."ghostty/config" = lib.mkIf (!isDarwin) {
    source = ../../configs/ghostty/config;
  };

  # macOS: Application Support path
  home.file."Library/Application Support/com.mitchellh.ghostty/config" = lib.mkIf isDarwin {
    source = ../../configs/ghostty/config;
  };

  # Cursor trail shader
  xdg.configFile."ghostty/shaders/cursor_warp.glsl".source = ../../configs/ghostty/shaders/cursor_warp.glsl;
}
