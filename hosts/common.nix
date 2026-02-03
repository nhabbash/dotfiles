# Shared darwin configuration for all machines
{ pkgs, username, ... }:

{
  imports = [
    ../modules/darwin
  ];

  # Nix configuration
  # Disable nix-darwin's Nix management (Determinate Nix manages itself)
  nix.enable = false;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # System packages available globally
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    wget
  ];

  # Fonts
  fonts.packages = with pkgs; [
    nerd-fonts.inconsolata
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
  ];

  # Create /etc/zshrc that loads the nix-darwin environment
  programs.zsh.enable = true;

  # Used for backwards compatibility
  system.stateVersion = 5;

  # The platform the configuration will be used on
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Set the primary user
  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
  };

  # Required for system.defaults options
  system.primaryUser = username;
}
