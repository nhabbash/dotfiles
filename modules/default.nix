# Home Manager modules entry point
{ config, pkgs, lib, username, isWork, enableGui, ... }:

let
  dotfilesDir = builtins.getEnv "DOTFILES_DIR";
  homeDir = config.home.homeDirectory;
  isDarwin = pkgs.stdenv.isDarwin;

  modules = [
    ./packages.nix
    ./shell/zsh.nix
    ./terminal/zellij.nix
  ];

  # All config symlinks: target (relative to ~) -> source (relative to dotfiles repo)
  configLinks = {
    # Shell
    ".config/zsh/core.zsh" = "configs/zsh/core.zsh";
    ".config/zsh/aliases.zsh" = "configs/zsh/aliases.zsh";
    ".config/zsh/functions.zsh" = "configs/zsh/functions.zsh";
    ".config/zsh/claude.zsh" = "configs/zsh/claude.zsh";
    ".config/zsh/zellij.zsh" = "configs/zsh/zellij.zsh";
    ".config/zsh/work.zsh" = "configs/zsh/work.zsh";
    ".config/zsh/personal.zsh" = "configs/zsh/personal.zsh";
    ".config/starship.toml" = "configs/starship.toml";

    # Git & tools
    ".gitconfig" = "configs/git/config";
    ".config/jj/config.toml" = "configs/jj/config.toml";
    ".config/gh/config.yml" = "configs/gh/config.yml";
    ".tmux.conf" = "configs/tmux/tmux.conf";

    # Claude Code
    ".claude/CLAUDE.md" = "configs/claude/CLAUDE.md";
    ".claude/statusline.sh" = "configs/claude/statusline.sh";

    # Agents (directory symlink)
    ".config/agents" = "configs/agents";

    # Zellij (whole dir so new layouts/themes/plugins just work)
    ".config/zellij" = "configs/zellij";
  }
  // lib.optionalAttrs enableGui {
    # Kitty
    ".config/kitty" = "configs/kitty";

    # Ghostty (whole shaders dir so new shaders auto-appear)
    ".config/ghostty/shaders" = "configs/ghostty/shaders";
  }
  // lib.optionalAttrs (enableGui && isDarwin) {
    "Library/Application Support/com.mitchellh.ghostty/config" = "configs/ghostty/config";
  }
  // lib.optionalAttrs (enableGui && !isDarwin) {
    ".config/ghostty/config" = "configs/ghostty/config";
  };

  # Build the ln -sf commands (rm first to handle stale files/dirs/symlinks)
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

  # Direct symlinks to repo files (one-hop, editable)
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
