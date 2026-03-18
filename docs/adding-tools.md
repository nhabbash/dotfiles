# Adding Tools

## Decision Order

When adding a tool, classify it before editing the repo:

1. Is it a workstation baseline tool used across multiple projects?
   If no, keep it out of dotfiles.

2. Is it available in `nixpkgs`?
   Prefer Nix for CLI tools and packages.

3. Is it a macOS GUI app available via Homebrew cask?
   Use nix-darwin Homebrew integration.

4. Is it only available as an external GitHub repo or release artifact?
   Add it as an explicitly pinned external asset. Do not fetch latest during
   activation.

5. Does it need live-editable config?
   Put config under `configs/`.

6. Does it need generated config?
   Add a manifest and a regeneration step under `dotfiles regen`.

## Placement

- CLI package
  `modules/packages.nix`

- macOS GUI app
  `modules/macos/apps.nix`

- live-edit config
  `configs/<tool>/`

- generated config source
  canonical manifest plus generator script

- runtime startup or reload behavior
  `scripts/dotfiles.sh` or dedicated runtime helpers
