# Personal MacBook configuration
{ pkgs, username, ... }:

{
  # Personal-specific settings can go here
  # Most configuration is in common.nix and modules/

  # Hostname
  networking.hostName = "nassim-personal";

  # Disable Ctrl+Space for IME switching (conflicts with Zellij)
  system.defaults.CustomUserPreferences = {
    "com.apple.symbolichotkeys" = {
      AppleSymbolicHotKeys = {
        # 60 = "Select the previous input source" (Ctrl+Space)
        "60" = { enabled = false; };
        # 61 = "Select next source in input menu" (Ctrl+Alt+Space)
        "61" = { enabled = false; };
      };
    };
  };

  # Personal-specific packages (if any)
  environment.systemPackages = with pkgs; [
    # Add personal-only packages here
  ];
}
