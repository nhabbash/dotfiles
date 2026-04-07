# macOS system preferences
{ isWork, ... }:

{
  system.defaults = {
    NSGlobalDomain = {
      # Keyboard
      ApplePressAndHoldEnabled = false;
      KeyRepeat = 2;
      InitialKeyRepeat = 15;

      # Trackpad
      AppleEnableMouseSwipeNavigateWithScrolls = true;
      AppleEnableSwipeNavigateWithScrolls = true;

      # Disable auto-corrections
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;

      # UI
      _HIHideMenuBar = !isWork;
      NSWindowResizeTime = 1.0e-3;
      AppleShowAllExtensions = true;
      AppleShowScrollBars = "WhenScrolling";
      NSDocumentSaveNewDocumentsToCloud = false;
      NSNavPanelExpandedStateForSaveMode = true;
      NSNavPanelExpandedStateForSaveMode2 = true;
      PMPrintingExpandedStateForPrint = true;
      PMPrintingExpandedStateForPrint2 = true;
      AppleInterfaceStyle = "Dark";
      AppleInterfaceStyleSwitchesAutomatically = false;
    };

    trackpad = {
      Clicking = true;
      TrackpadRightClick = true;
      TrackpadThreeFingerDrag = true;
    };

    loginwindow = {
      GuestEnabled = false;
      DisableConsoleAccess = true;
    };

    screencapture = {
      location = "~/Pictures/Screenshots";
      type = "png";
      disable-shadow = true;
    };

    spaces.spans-displays = false;

    menuExtraClock = {
      Show24Hour = true;
      ShowDate = 1;
      ShowDayOfWeek = true;
    };

    # Disable Spotlight shortcuts (cmd+space, cmd+alt+space) and input source
    # switching (ctrl+space, ctrl+alt+space) so terminal apps can reliably use
    # those chords.
    CustomUserPreferences."com.apple.symbolichotkeys".AppleSymbolicHotKeys = {
      "64" = { enabled = false; value = { parameters = [ 65535 49 1048576 ]; type = "standard"; }; };
      "65" = { enabled = false; value = { parameters = [ 65535 49 1572864 ]; type = "standard"; }; };
      "60" = { enabled = false; value = { parameters = [ 32 49 262144 ]; type = "standard"; }; };
      "61" = { enabled = false; value = { parameters = [ 32 49 786432 ]; type = "standard"; }; };
    };
  };

  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToEscape = true;
  };
}
