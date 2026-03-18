# Operations

## Baseline Commands

- `dotfiles rebuild [hostname]`
  Apply Nix-managed changes.

- `dotfiles regen`
  Regenerate derived config such as keymap blocks.

- `dotfiles check [hostname]`
  Run repository and configuration validation without applying changes.

- `dotfiles services [hostname]`
  Start or reload runtime desktop services.

- `dotfiles doctor [hostname]`
  Inspect runtime health, installs, links, and permissions.

## Change Routing

When making a change, classify it first:

- Edit `configs/*`
  Live-edit config. Rebuild not required.

- Edit generated source manifests
  Run `dotfiles regen`.

- Edit `modules/*`, `hosts/*`, or `flake.nix`
  Run `dotfiles rebuild`.

- Fix startup, running apps, or permissions
  Use `dotfiles services` or `dotfiles doctor`.

Implementation detail:
- generators live under `scripts/generated/`
- experimental mutable tools live under `scripts/experiments/`

## Recovery

If a change breaks runtime behavior:

1. Run `dotfiles doctor`
2. Run `dotfiles services`
3. Revert the last refactor commit or switch back to the previous branch

If a rebuild regresses system state on macOS:

1. Use the previous nix-darwin generation
2. Return to the last known-good git commit
3. Re-run `dotfiles rebuild`
