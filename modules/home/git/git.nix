# Git configuration
{ config, pkgs, lib, isWork, ... }:

{
  home.packages = with pkgs; [
    git
    gh
    lazygit
    gitleaks
  ];

  programs.git = {
    enable = true;

    # Include local config for secrets/overrides
    includes = [
      { path = "~/.gitconfig.local"; }
    ];

    settings = {
      user = {
        name = "Nassim Habbash";
        # Default to personal email; work overrides via ~/.gitconfig.local
        email = lib.mkIf (!isWork) "nassim@habbash.dev";
      };

      push.autoSetupRemote = true;
      init.defaultBranch = "main";
      pull.rebase = true;
      core.editor = "nvim";

      alias = {
        st = "status";
        co = "checkout";
        br = "branch";
        ci = "commit";
        lg = "log --oneline --graph --decorate";
      };
    };
  };
}
