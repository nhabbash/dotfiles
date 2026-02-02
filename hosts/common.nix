# Shared darwin configuration for all machines
{ pkgs, username, ... }:

{
  imports = [
    ../modules/darwin
  ];

  # Nix configuration
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      warn-dirty = false;
    };
    # Automatic garbage collection
    gc = {
      automatic = true;
      interval = { Weekday = 0; Hour = 2; Minute = 0; };
      options = "--delete-older-than 30d";
    };
  };

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
