# Personal MacBook configuration
{ pkgs, username, ... }:

{
  # Personal-specific settings can go here
  # Most configuration is in common.nix and modules/

  # Hostname
  networking.hostName = "nassim-personal";

  # Personal-specific packages (if any)
  environment.systemPackages = with pkgs; [
    # Add personal-only packages here
  ];
}
