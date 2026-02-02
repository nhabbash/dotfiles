# macOS Dock preferences
{ ... }:

{
  system.defaults.dock = {
    # Behavior
    autohide = true;
    autohide-delay = 0.0;
    autohide-time-modifier = 0.4;

    # Appearance
    orientation = "bottom";
    tilesize = 48;
    magnification = false;
    largesize = 64;

    # Show indicators for open applications
    show-process-indicators = true;

    # Don't show recent applications
    show-recents = false;

    # Minimize windows into their application's icon
    minimize-to-application = true;

    # Minimize animation
    mineffect = "scale";

    # Don't automatically rearrange Spaces
    mru-spaces = false;

    # Hot corners
    # Options: 0 = none, 2 = mission control, 3 = application windows,
    # 4 = desktop, 5 = start screen saver, 6 = disable screen saver,
    # 7 = dashboard, 10 = put display to sleep, 11 = launchpad, 12 = notification center
    wvous-tl-corner = 1;  # Top left - disabled
    wvous-tr-corner = 1;  # Top right - disabled
    wvous-bl-corner = 1;  # Bottom left - disabled
    wvous-br-corner = 1;  # Bottom right - disabled

    # Persistent dock items (optional - uncomment to customize)
    # persistent-apps = [
    #   "/Applications/Kitty.app"
    #   "/Applications/Visual Studio Code.app"
    #   "/Applications/Safari.app"
    # ];
  };
}
