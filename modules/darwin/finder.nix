# macOS Finder preferences
{ ... }:

{
  system.defaults.finder = {
    # Show all file extensions
    AppleShowAllExtensions = true;

    # Show hidden files
    AppleShowAllFiles = true;

    # Show path bar
    ShowPathbar = true;

    # Show status bar
    ShowStatusBar = true;

    # Default view style (icnv = icon, Nlsv = list, clmv = column, Flwv = gallery)
    FXPreferredViewStyle = "Nlsv";

    # When performing a search, search the current folder by default
    FXDefaultSearchScope = "SCcf";

    # Disable warning when changing file extension
    FXEnableExtensionChangeWarning = false;

    # Allow quitting Finder via Cmd+Q
    QuitMenuItem = true;

    # Show icons on desktop
    CreateDesktop = true;

    # New window target
    NewWindowTarget = "Home";
  };

  # Additional Finder settings via defaults
  system.defaults.CustomUserPreferences = {
    "com.apple.finder" = {
      # Show full POSIX path in Finder title
      _FXShowPosixPathInTitle = true;
      # Keep folders on top when sorting by name
      _FXSortFoldersFirst = true;
    };
  };
}
