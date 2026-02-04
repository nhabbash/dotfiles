# macOS GUI apps via Homebrew
{ ... }:

{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false;
      cleanup = "none";  # Don't remove apps not in this list
    };

    # GUI applications
    casks = [
      # Terminal
      "kitty"

      # Add more casks here as needed
      # "cursor"
      # "visual-studio-code"
      # "arc"
      # "raycast"
      # "slack"
    ];

    # CLI tools not in nixpkgs (usually prefer nix)
    brews = [
    ];

    # Mac App Store apps (requires mas CLI)
    masApps = {
    };
  };
}
