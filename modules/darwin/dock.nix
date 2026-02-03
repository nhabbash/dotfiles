# macOS Dock preferences
{ ... }:

{
  system.defaults.dock = {
    autohide = true;
    autohide-delay = 0.0;
    autohide-time-modifier = 0.4;
    orientation = "bottom";
    tilesize = 48;
    magnification = false;
    largesize = 64;
    show-process-indicators = true;
    show-recents = false;
    minimize-to-application = true;
    mineffect = "scale";
    mru-spaces = false;

    # Hot corners: 0=none, 2=mission control, 3=app windows, 4=desktop,
    # 5=screen saver, 6=disable saver, 10=sleep, 11=launchpad, 12=notification center
    wvous-tl-corner = 1;
    wvous-tr-corner = 1;
    wvous-bl-corner = 1;
    wvous-br-corner = 1;
  };
}
