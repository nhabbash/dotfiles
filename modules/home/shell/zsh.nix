# Zsh configuration
{ config, pkgs, lib, ... }:

{
  programs.zsh = {
    enable = true;

    # Put nix-managed zsh files in .config/zsh
    # This leaves ~/.zshrc free for user/tool edits
    dotDir = "${config.xdg.configHome}/zsh";

    enableCompletion = true;
    autosuggestion = {
      enable = true;
      highlight = "fg=#663399,standout";
    };
    syntaxHighlighting.enable = true;

    # History settings
    history = {
      size = 100000;
      save = 100000;
      ignoreDups = true;
      ignoreSpace = true;
      share = true;
    };

    # Oh My Zsh
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" ];
    };

    # Extra init (runs at the end of .config/zsh/.zshrc)
    initContent = ''
      # Homebrew (must be early for PATH)
      if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
      fi

      # Performance: Cache completions aggressively
      DISABLE_AUTO_UPDATE="true"
      DISABLE_MAGIC_FUNCTIONS="true"
      DISABLE_COMPFIX="true"

      # Alias expansion function
      globalias() {
        if [[ $LBUFFER =~ '[a-zA-Z0-9]+$' ]]; then
          zle _expand_alias
          zle expand-word
        fi
        zle self-insert
      }
      zle -N globalias
      bindkey " " globalias
      bindkey "^[[Z" magic-space
      bindkey -M isearch " " magic-space

      # SSH agent (runs once per session)
      if [ -z "$SSH_AUTH_SOCK" ]; then
        eval "$(ssh-agent -s)" > /dev/null
        ssh-add ~/.ssh/id_github_sign_and_auth 2>/dev/null
      fi

      # Zellij tab name support
      if [[ -n "$ZELLIJ" ]]; then
        function zellij_tab_name_update_pre() {
          local cmd="''${1[(w)1]}"
          if [[ -n "$cmd" ]]; then
            { zellij action rename-tab "$cmd" } >/dev/null 2>&1 &!
          fi
        }
        autoload -Uz add-zsh-hook
        add-zsh-hook preexec zellij_tab_name_update_pre
      fi

      # Volta (Node.js version manager)
      export VOLTA_HOME="$HOME/.volta"
      export PATH="$VOLTA_HOME/bin:$PATH"

      # Additional PATH entries
      export PATH="$HOME/.local/bin:$PATH"
    '';

    # Profile extra (runs in .zprofile, for login shells)
    profileExtra = ''
      # Homebrew (macOS)
      if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
      fi
    '';
  };

  # Create ~/.zshrc.base that sources the nix config
  home.file.".zshrc.base".text = ''
    # Nix-managed zsh config - do not edit directly
    # Edit ~/.zshrc for custom additions
    source ${config.xdg.configHome}/zsh/.zshrc
  '';
}
