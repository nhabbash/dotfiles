# Personal MacBook configuration
{ pkgs, username, ... }:

{
  # Platform (Apple Silicon)
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Hostname
  networking.hostName = "nassim-personal";

}
