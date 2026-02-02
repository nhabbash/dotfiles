# Darwin modules entry point
{ ... }:

{
  imports = [
    ./system.nix
    ./dock.nix
    ./finder.nix
  ];
}
