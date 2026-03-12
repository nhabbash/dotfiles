# Zellij terminal multiplexer configuration
{ config, pkgs, dotfilesDir, zellij-tmux-shim, ... }:

let
  mkLink = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/${path}";
  shimDir = zellij-tmux-shim;
in
{
  home.packages = with pkgs; [
    zellij
  ];

  xdg.configFile = {
    "zellij/config.kdl".source = mkLink "configs/zellij/config.kdl";
    "zellij/themes/catppuccin-mocha.kdl".source = mkLink "configs/zellij/themes/catppuccin-mocha.kdl";
    "zellij/layouts/default.kdl".source = mkLink "configs/zellij/layouts/default.kdl";
  };

  # zellij-tmux-shim: makes Claude Code agent teams work in zellij
  home.file = {
    ".local/share/zellij-tmux-shim/bin/tmux" = {
      source = "${shimDir}/bin/tmux";
      executable = true;
    };
    ".local/share/zellij-tmux-shim/bin/zellij-pane-wrapper" = {
      source = "${shimDir}/bin/zellij-pane-wrapper";
      executable = true;
    };
    ".local/share/zellij-tmux-shim/activate.sh".source = "${shimDir}/activate.sh";
    ".local/share/zellij-tmux-shim/deactivate.sh".source = "${shimDir}/deactivate.sh";
  };
}
