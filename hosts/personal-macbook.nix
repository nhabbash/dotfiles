# Personal MacBook configuration
{ pkgs, username, ... }:

{
  # Platform (Apple Silicon)
  nixpkgs.hostPlatform = "aarch64-darwin";

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
}
