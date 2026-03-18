# Home Manager modules entry point
{ config, pkgs, lib, username, isWork, enableGui, ... }:

let
  policy = import ./policy.nix {
    inherit pkgs isWork enableGui;
  };
  features = policy.features;
  dotfilesDir = builtins.getEnv "DOTFILES_DIR";
  homeDir = config.home.homeDirectory;
  isDarwin = policy.isDarwin;

  modules = [
    ./packages.nix
    ./shell/zsh.nix
    ./terminal/zellij.nix
  ];

  # All live-editable config links: target (relative to ~) -> source (relative to dotfiles repo)
  configLinks = import ./links.nix {
    inherit lib features;
  };

  linkTargets = lib.mapAttrs (target: source: {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/${source}";
  }) configLinks;
in
{
  imports = modules;

  home.stateVersion = "24.05";
  programs.home-manager.enable = true;

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    XDG_CONFIG_HOME = "${config.home.homeDirectory}/.config";
    XDG_DATA_HOME = "${config.home.homeDirectory}/.local/share";
    XDG_CACHE_HOME = "${config.home.homeDirectory}/.cache";
    DOTFILES_DIR = dotfilesDir;
  };

  _module.args = {
    inherit isWork dotfilesDir;
  };

  # Direct editable symlinks from the repo into $HOME.
  home.file = linkTargets;

  # simple-bar: clone once into Übersicht widgets dir (macOS only)
  home.activation.installSimpleBar = lib.mkIf features.simpleBar (lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    SIMPLEBAR_DIR="${homeDir}/Library/Application Support/Übersicht/widgets/simple-bar"
    if [ ! -d "$SIMPLEBAR_DIR" ]; then
      ${pkgs.git}/bin/git clone --depth 1 https://github.com/Jean-Tinland/simple-bar "$SIMPLEBAR_DIR"
    fi
  '');

  # Tool integrations (packages are in packages.nix, configs are in configs/)
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultOptions = [ "--height 40%" "--layout=reverse" "--border" ];
  };

  programs.bat = {
    enable = true;
    config = {
      theme = "TwoDark";
      style = "numbers,changes";
    };
  };

  programs.eza = {
    enable = true;
    enableZshIntegration = false;
  };
}
