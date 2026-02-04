# macOS system configuration
{ ... }:

{
  imports = [
    ./system.nix
    ./dock.nix
    ./finder.nix
    ./apps.nix
  ];
}
