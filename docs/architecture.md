# Architecture

This repo manages a workstation, not a single project. The goal is to keep the
fast path fast for daily edits while keeping ownership boundaries explicit.

## Latency Classes

There are four classes of changes:

1. Live edit
   Files under `configs/` that are linked into the home directory and can be
   edited directly without a Nix rebuild.

2. Regenerate
   Derived config fragments that are generated from canonical manifests.
   These require `dotfiles regen`.

3. Rebuild
   Declarative system or package changes in `flake.nix`, `hosts/`, or
   `modules/`. These require `dotfiles rebuild`.

4. Runtime
   Service startup, reloads, permissions, and health checks.
   These use `dotfiles services` or `dotfiles doctor`.

## Ownership Rules

Each area should have one owner:

- `flake.nix`, `hosts/`, `modules/`
  Declarative package, policy, and system state.

- `configs/`
  Live-editable config content for tools used across the workstation.

- Generated manifests and generators
  Canonical source for derived config. Regeneration must be explicit.

- `scripts/`
  Operational commands, runtime helpers, diagnostics, and experiments.

- Local untracked files
  Machine-specific or secret state such as `~/.zshrc.local` or
  `~/.gitconfig.local`.

## Inclusion Policy

A tool belongs in dotfiles if it is part of the workstation baseline across
multiple unrelated projects. Examples: shell tools, terminals, window managers,
container runtimes, editor config, Git tooling.

A tool does not belong in dotfiles if it is specific to one repo, one stack, or
one team codebase and is better owned by that project.

## Command Model

- `dotfiles rebuild`
  Apply declarative state.

- `dotfiles regen`
  Regenerate derived config from canonical manifests.

- `dotfiles check`
  Verify repo integrity and drift without applying changes.

- `dotfiles services`
  Start or reload runtime services.

- `dotfiles doctor`
  Diagnose runtime state and workstation health.
