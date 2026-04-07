# Hosts

## Host Dimensions

The repo currently uses these axes:

- `hostname`
  Concrete machine target such as `work-macbook` or `personal-macbook`

- `isWork`
  Profile split between work and personal behavior

- `enableGui`
  Whether GUI-facing configs and apps should be linked or installed

## Current Host Targets

- `personal-macbook`
- `work-macbook`
- `personal-macbook-intel`
- `linux-server`
- `linux-desktop`

## Policy Direction

Host differences should be expressed as feature flags derived from the axes
above, rather than re-encoding host logic in many places. Examples:

- `features.aerospace`
- `features.hammerspoon`
- `features.ubersicht`
- `features.simpleBar`
- `features.workProfile`

## Shared macOS Shortcut Policy

All macOS hosts disable these system symbolic hotkeys in the shared module:

- Spotlight search: `cmd+space`
- Spotlight Finder search: `cmd+alt+space`
- Previous input source: `ctrl+space`
- Next input source: `ctrl+alt+space`

This keeps Raycast and terminal-local chords such as Zellij's mode toggle from
being intercepted by macOS.
