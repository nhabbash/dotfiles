{ pkgs, isWork, enableGui }:

let
  isDarwin = pkgs.stdenv.isDarwin;
in
{
  inherit isDarwin;

  features = {
    gui = enableGui;
    darwin = isDarwin;
    workProfile = isWork;

    ghostty = enableGui;
    aerospace = enableGui && isDarwin;
    hammerspoon = enableGui && isDarwin;
    ubersicht = enableGui && isDarwin;
    simpleBar = enableGui && isDarwin && !isWork;
  };
}
