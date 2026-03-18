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
