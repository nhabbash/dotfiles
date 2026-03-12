# Zellij terminal multiplexer configuration
# Config file symlinks managed by home.activation.linkConfigs in default.nix
{ pkgs, zellij-tmux-shim, ... }:

let
  shimDir = zellij-tmux-shim;
in
{
  home.packages = with pkgs; [
    zellij
  ];

  # zellij-tmux-shim: makes Claude Code agent teams work in zellij
  # These come from a flake input (not the repo), so they use nix file management
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
