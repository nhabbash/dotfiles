{ config, pkgs, lib, hostname, isWork, ... }:

let
  # Determine if we're on macOS
  isDarwin = pkgs.stdenv.isDarwin;

  # User info - change these for your setup
  username = "nassim";
  homeDirectory = if isDarwin then "/Users/${username}" else "/home/${username}";
in
{
  # Home Manager needs a bit of information about you and the paths it should manage
  home.username = username;
  home.homeDirectory = homeDirectory;

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  home.stateVersion = "24.05";

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  # ===========================================================================
  # Packages
  # ===========================================================================
  home.packages = with pkgs; [
    # Shell & Terminal
    zsh
    starship
    zellij
    fzf
    tmux

    # Modern CLI tools
    bat          # Better cat
    eza          # Better ls
    ripgrep      # Better grep
    fd           # Better find
    jq           # JSON processor
    tree
    htop

    # Git tools
    git
    gh           # GitHub CLI
    lazygit
    gitleaks

    # Development
    neovim

    # Node.js (via volta, managed separately - see notes)
    # volta       # Not in nixpkgs, install separately

    # Python
    # pyenv       # Managed separately for work compatibility

    # Kubernetes
    kubectl
    kubectx
    k9s

    # Cloud
    awscli2

    # Misc
    stow         # Keep for backwards compatibility
    glow         # Markdown viewer
  ];

  # ===========================================================================
  # Program Configurations
  # ===========================================================================

  # ---------------------------------------------------------------------------
  # Git
  # ---------------------------------------------------------------------------
  programs.git = {
    enable = true;
    userName = "Nassim Habbash";
    # Use personal email by default, override in work-specific config
    userEmail = if isWork then "nassimha@monday.com" else "YOUR_PERSONAL_EMAIL";

    extraConfig = {
      push.autoSetupRemote = true;
      init.defaultBranch = "main";
      pull.rebase = true;
      core.editor = "nvim";
    };

    # Useful aliases
    aliases = {
      st = "status";
      co = "checkout";
      br = "branch";
      ci = "commit";
      lg = "log --oneline --graph --decorate";
    };
  };

  # ---------------------------------------------------------------------------
  # Zsh
  # ---------------------------------------------------------------------------
  programs.zsh = {
    enable = true;
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

    # Shell aliases
    shellAliases = {
      # Navigation
      ll = "eza -l --icons --sort newest --group-directories-first -s extension";
      c = "code .";
      s = "cursor .";
      e = "exit";
      r = "cd ~/Development";

      # Git
      g = "git";
      gs = "git status";
      ga = "git add .";
      gc = "git commit -m";
      gagc = "git add . && git commit -m";
      gp = "git fetch -p";
      pp = "git pull --rebase && git push";
      gcom = "git checkout main";
      gcol = "git checkout -";
      gb = "git checkout -b";
      gcl = "git clone";

      # Package managers
      bi = "HOMEBREW_NO_AUTO_UPDATE=1 brew install";
      pi = "pnpm i";
      prd = "pnpm run dev";
      prb = "pnpm run build";

      # Tools
      zz = "zellij";
      tm = "task-master";

      # Tree
      tdl = "tree -a -I 'node_modules|.svelte-kit|.git' --dirsfirst";
    };

    # Extra init (runs at the end of .zshrc)
    initExtra = ''
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

  # ---------------------------------------------------------------------------
  # Starship Prompt
  # ---------------------------------------------------------------------------
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    # Use your custom tokyo theme
    settings = {
      format = lib.concatStrings [
        "[░▒▓](#a3aed2)"
        "[  ](bg:#a3aed2 fg:#090c0c)"
        "[](bg:#769ff0 fg:#a3aed2)"
        "$directory"
        "[](fg:#769ff0 bg:#394260)"
        "$git_branch"
        "$git_status"
        "[](fg:#394260 bg:#2d344b)"
        "\${custom.nodejs}"
        "[](fg:#2d344b)"
        "\n$character"
      ];

      directory = {
        style = "fg:#e3e5e5 bg:#769ff0";
        format = "[ $path ]($style)";
        truncation_length = 3;
        truncation_symbol = ".../";
      };

      git_branch = {
        symbol = "";
        style = "bg:#394260";
        format = "[[ $symbol $branch ](fg:#769ff0 bg:#394260)]($style)";
      };

      git_status = {
        style = "bg:#394260";
        format = "[[($all_status$ahead_behind )](fg:#769ff0 bg:#394260)]($style)";
      };

      custom.nodejs = {
        command = "node --version | tr -d '\\n'";
        when = true;
        symbol = "󰎙";
        style = "bg:#2d344b";
        format = "[[ $symbol $output ](fg:#769ff0 bg:#2d344b)]($style)";
        disabled = false;
      };

      kubernetes = {
        symbol = "☸";
        style = "bg:#212736";
        format = "[[ $symbol ($context \\($namespace\\)) ](fg:#769ff0 bg:#212736)]($style)";
        disabled = false;
      };
    };
  };

  # ---------------------------------------------------------------------------
  # FZF
  # ---------------------------------------------------------------------------
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultOptions = [ "--height 40%" "--layout=reverse" "--border" ];
  };

  # ---------------------------------------------------------------------------
  # Bat (better cat)
  # ---------------------------------------------------------------------------
  programs.bat = {
    enable = true;
    config = {
      theme = "Catppuccin-mocha";
      style = "numbers,changes";
    };
  };

  # ---------------------------------------------------------------------------
  # Eza (better ls)
  # ---------------------------------------------------------------------------
  programs.eza = {
    enable = true;
    icons = "auto";
    git = true;
  };

  # ===========================================================================
  # Config Files (managed by Home Manager)
  # ===========================================================================

  # Kitty terminal
  xdg.configFile."kitty/kitty.conf".source = ./configs/kitty/kitty.conf;
  xdg.configFile."kitty/current-theme.conf".source = ./configs/kitty/current-theme.conf;

  # Zellij
  xdg.configFile."zellij/config.kdl".source = ./configs/zellij/config.kdl;
  xdg.configFile."zellij/themes/catppuccin-mocha.kdl".source = ./configs/zellij/catppuccin-mocha.kdl;

  # ===========================================================================
  # Environment Variables
  # ===========================================================================
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";

    # XDG Base Directory
    XDG_CONFIG_HOME = "${homeDirectory}/.config";
    XDG_DATA_HOME = "${homeDirectory}/.local/share";
    XDG_CACHE_HOME = "${homeDirectory}/.cache";
  };
}
