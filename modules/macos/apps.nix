# macOS GUI apps via Homebrew
{ lib, isWork, ... }:

{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false;
      cleanup = "none";  # Don't remove apps not in this list
    };

    taps = lib.optionals isWork [
      "nikitabobko/tap"
      "FelixKratz/formulae"
    ];

    # GUI applications
    casks = [
      # Terminal
      "kitty"
    ] ++ lib.optionals isWork [
      "nikitabobko/tap/aerospace"
    ];

    # CLI tools not in nixpkgs (usually prefer nix)
    brews = [
    ] ++ lib.optionals isWork [
      "felixkratz/formulae/borders"
    ];

    # Mac App Store apps (requires mas CLI)
    masApps = {
    };
  };
}
