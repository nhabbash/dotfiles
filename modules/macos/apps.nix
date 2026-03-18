# macOS GUI apps via Homebrew
{ lib, isWork, ... }:

{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false;
      cleanup = "none";  # Don't remove apps not in this list
    };

    taps = [
      "nikitabobko/tap"
      "FelixKratz/formulae"
    ];

    # GUI applications
    casks = [
      # Terminal
      "kitty"
      "nikitabobko/tap/aerospace"
      "hammerspoon"
      # Status bar & widget engine
      "ubersicht"
    ];

    # CLI tools not in nixpkgs (usually prefer nix)
    brews = [
      "felixkratz/formulae/borders"
    ];

    # Mac App Store apps (requires mas CLI)
    masApps = {
    };
  };
}
