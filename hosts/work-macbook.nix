# Work MacBook configuration
{ pkgs, username, ... }:

{
  # Platform (Apple Silicon)
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Hostname
  networking.hostName = "nassim-work";

  # Work-specific packages
  environment.systemPackages = with pkgs; [
    awscli2
  ];
}
