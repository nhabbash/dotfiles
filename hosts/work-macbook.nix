# Work MacBook configuration
{ pkgs, username, ... }:

{
  # Work-specific settings
  # Most configuration is in common.nix and modules/
  # Company-specific configs load from ~/.zshrc.local and ~/.gitconfig.local

  # Hostname
  networking.hostName = "nassim-work";

  # Work-specific packages (if any)
  environment.systemPackages = with pkgs; [
    # Add work-only packages here
  ];
}
