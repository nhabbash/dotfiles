# Zsh configuration
{ config, pkgs, lib, dotfilesDir, isWork, ... }:

let
  mkLink = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/${path}";
  profileFile = if isWork then "work" else "personal";
in
{
  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zsh";  # Keep ~/.zshrc user-editable
    enableCompletion = true;
    autosuggestion = {
      enable = true;
      highlight = "fg=#663399,standout";
    };
    syntaxHighlighting.enable = true;

    history = {
      size = 100000;
      save = 100000;
      ignoreDups = true;
      ignoreSpace = true;
      share = true;
    };

    oh-my-zsh = {
      enable = true;
      plugins = [ "git" ];
    };

    initContent = ''
      source ~/.config/zsh/core.zsh
      source ~/.config/zsh/aliases.zsh
      source ~/.config/zsh/functions.zsh
      source ~/.config/zsh/claude.zsh
      source ~/.config/zsh/zellij.zsh
      source ~/.config/zsh/${profileFile}.zsh
    '';
  };

  # Symlink shell config files from the repo (editable, no rebuild needed)
  xdg.configFile = {
    "zsh/core.zsh".source = mkLink "configs/zsh/core.zsh";
    "zsh/aliases.zsh".source = mkLink "configs/zsh/aliases.zsh";
    "zsh/functions.zsh".source = mkLink "configs/zsh/functions.zsh";
    "zsh/claude.zsh".source = mkLink "configs/zsh/claude.zsh";
    "zsh/zellij.zsh".source = mkLink "configs/zsh/zellij.zsh";
    "zsh/work.zsh".source = mkLink "configs/zsh/work.zsh";
    "zsh/personal.zsh".source = mkLink "configs/zsh/personal.zsh";
  };

  # Custom .zshenv - load nix env but don't redirect ZDOTDIR
  home.file.".zshenv".text = ''
    . "${config.home.profileDirectory}/etc/profile.d/hm-session-vars.sh"
    export ZSH="${pkgs.oh-my-zsh}/share/oh-my-zsh"
    export ZSH_CACHE_DIR="$HOME/.cache/oh-my-zsh"
    unset ZDOTDIR
  '';

  # ~/.zshrc.base sources the nix-managed config
  home.file.".zshrc.base".text = ''
    source ${config.xdg.configHome}/zsh/.zshrc
  '';
}
