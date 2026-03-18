# Cutover

This document describes how to switch from the current baseline branch to the
refactor branch safely.

## Current Known Points

- Baseline branch: `master`
- Baseline checkpoint commit: `0f2636c`
- Refactor branch: `refactor/dotfiles-architecture`

## Preconditions

Before switching:

1. Ensure current work is committed or otherwise safe.
2. Run `dotfiles snapshot`
3. Run `dotfiles check`
4. Confirm the refactor branch is clean.

## Switch Procedure

1. Capture a baseline snapshot on the current branch:

   ```bash
   dotfiles snapshot
   ```

2. Switch to the refactor branch:

   ```bash
   git checkout refactor/dotfiles-architecture
   ```

3. Validate before applying:

   ```bash
   dotfiles check
   ```

4. Install explicit assets if needed:

   ```bash
   dotfiles assets
   ```

5. Apply the branch:

   ```bash
   dotfiles rebuild
   ```

6. Reconcile runtime state:

   ```bash
   dotfiles services
   dotfiles doctor
   ```

7. Capture a post-switch snapshot:

   ```bash
   dotfiles snapshot
   ```

## Rollback

If the switch is not acceptable:

1. Switch back to the baseline branch:

   ```bash
   git checkout master
   ```

2. Rebuild the baseline:

   ```bash
   dotfiles rebuild
   ```

3. Reconcile runtime state:

   ```bash
   dotfiles services
   dotfiles doctor
   ```

4. If required, use the previous nix-darwin generation.

## Notes

- `dotfiles snapshot` writes a text file to the temp directory so pre/post
  state can be compared.
- `dotfiles assets` is explicit on the refactor branch; rebuild no longer fetches
  mutable external state during activation.
