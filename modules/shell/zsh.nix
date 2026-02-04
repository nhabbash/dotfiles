# Zsh configuration
{ config, pkgs, lib, ... }:

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
      # Homebrew
      if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
      fi

      # Performance
      DISABLE_AUTO_UPDATE="true"
      DISABLE_MAGIC_FUNCTIONS="true"
      DISABLE_COMPFIX="true"

      # Expand aliases on space
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

      # SSH agent
      if [ -z "$SSH_AUTH_SOCK" ]; then
        eval "$(ssh-agent -s)" > /dev/null
        ssh-add ~/.ssh/id_github_sign_and_auth 2>/dev/null
      fi

      # Zellij tab naming
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

      # Volta
      export VOLTA_HOME="$HOME/.volta"
      export PATH="$VOLTA_HOME/bin:$PATH"
      export PATH="$HOME/.local/bin:$PATH"
    '';
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
