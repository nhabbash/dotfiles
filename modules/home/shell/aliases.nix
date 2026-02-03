# Shell aliases
{ config, pkgs, ... }:

{
  programs.zsh.shellAliases = {
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
    tdl = "tree -a -I 'node_modules|.svelte-kit|.git' --dirsfirst";

    # Nix
    rebuild = "~/.dotfiles/scripts/switch.sh";
    nfu = "nix flake update ~/.dotfiles";
    ngc = "nix-collect-garbage -d && nix store optimise";
  };
}
