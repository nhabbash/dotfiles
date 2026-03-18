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

  linkCommands = lib.concatStringsSep "\n" (lib.mapAttrsToList (target: source: ''
    mkdir -p "$(dirname "${homeDir}/${target}")"
    rm -rf "${homeDir}/${target}"
    ln -sf "${dotfilesDir}/${source}" "${homeDir}/${target}"
  '') configLinks);
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
  home.activation.linkConfigs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${linkCommands}
  '';

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
