# Verification

Use these checks to confirm that a live tool is actually using config from this
repo.

## General Rule

If a tool supports direct file-based config, first verify the home path points
back into this repo.

Examples:

```bash
readlink ~/.config/aerospace
readlink ~/.config/zellij
readlink ~/.hammerspoon
```

The output should point into this repository.

## AeroSpace

Check the config path and reload behavior:

```bash
aerospace config --config-path
```

Expected: the config should resolve through `~/.config/aerospace` to this repo.

If needed:

```bash
dotfiles services
```

## Hammerspoon

Check:

```bash
readlink ~/.hammerspoon
```

Then confirm:

- Hammerspoon is running
- the console shows no load errors
- the expected hotkey is enabled

Remember:
- `dotfiles services` does not launch Hammerspoon

## Zellij

Check:

```bash
readlink ~/.config/zellij
```

If config changes do not appear, restart the relevant session or open a new one.

## Ghostty

Check:

```bash
readlink ~/.config/ghostty
readlink ~/.config/ghostty/shaders
```

Reload Ghostty config after changes.

## zsh

Check:

```bash
readlink ~/.config/zsh
```

Open a new shell after changes to shared zsh config.
