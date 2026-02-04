# macOS Finder preferences
{ ... }:

{
  system.defaults.finder = {
    AppleShowAllExtensions = true;
    AppleShowAllFiles = true;
    ShowPathbar = true;
    ShowStatusBar = true;
    FXPreferredViewStyle = "Nlsv";  # icnv=icon, Nlsv=list, clmv=column, Flwv=gallery
    FXDefaultSearchScope = "SCcf";  # SCcf=current folder
    FXEnableExtensionChangeWarning = false;
    QuitMenuItem = true;
    CreateDesktop = true;
    NewWindowTarget = "Home";
  };

  system.defaults.CustomUserPreferences = {
    "com.apple.finder" = {
      _FXShowPosixPathInTitle = true;
      _FXSortFoldersFirst = true;
    };
  };
}
