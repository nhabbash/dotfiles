# Zellij terminal multiplexer configuration
# Config file symlinks managed by home.activation.linkConfigs in default.nix
{ pkgs, zellij-tmux-shim, ... }:

let
  patchFile = ../../configs/zellij-tmux-shim/tab-pinning.patch;

  # Apply our tab-pinning patch to the upstream tmux shim
  patchedShim = pkgs.stdenvNoCC.mkDerivation {
    name = "zellij-tmux-shim-patched";
    src = zellij-tmux-shim;
    phases = [ "unpackPhase" "patchPhase" "installPhase" ];
    patches = [ patchFile ];
    installPhase = ''
      mkdir -p $out
      cp -r . $out/
    '';
  };
in
{
  home.packages = with pkgs; [
    zellij
  ];

  # zellij-tmux-shim: makes Claude Code agent teams work in zellij
  # Patched with tab-pinning to keep agent panes in the team lead's tab
  home.file = {
    ".local/share/zellij-tmux-shim/bin/tmux" = {
      source = "${patchedShim}/bin/tmux";
      executable = true;
    };
    ".local/share/zellij-tmux-shim/bin/zellij-pane-wrapper" = {
      source = "${patchedShim}/bin/zellij-pane-wrapper";
      executable = true;
    };
    ".local/share/zellij-tmux-shim/activate.sh".source = "${patchedShim}/activate.sh";
    ".local/share/zellij-tmux-shim/deactivate.sh".source = "${patchedShim}/deactivate.sh";
  };
}
