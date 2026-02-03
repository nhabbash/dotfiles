# Work MacBook configuration
{ pkgs, username, ... }:

{
  # Work-specific settings
  # Most configuration is in common.nix and modules/
  # Company-specific configs load from ~/.zshrc.work and ~/.gitconfig.local

  # Hostname
  networking.hostName = "nassim-work";

  # Work-specific packages
  environment.systemPackages = with pkgs; [
    awscli2
  ];
}
