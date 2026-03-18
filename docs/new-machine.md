# New Machine Setup

Use this when setting up a fresh machine from scratch.

## Before You Start

You should have:

- Git access to the repo
- a macOS or Linux target that matches one of the supported hosts
- permission to install Nix

Supported hosts:
- `personal-macbook`
- `work-macbook`
- `personal-macbook-intel`
- `linux-server`
- `linux-desktop`

## Bootstrap

```bash
git clone git@github.com:nhabbash/dotfiles.git ~/Development/dotfiles
cd ~/Development/dotfiles
bash scripts/dotfiles.sh bootstrap [hostname]
```

What bootstrap does:

1. installs Nix if needed
2. asks you to restart the shell if Nix was just installed
3. builds and applies the host configuration
4. creates `~/.zshrc`
5. starts runtime desktop services that are safe to manage automatically

## After Bootstrap

Run:

```bash
dotfiles status
dotfiles doctor
```

If you are on macOS, confirm:

- AeroSpace is installed and running
- the expected config links exist
- Hammerspoon is installed if the profile enables it
- Hammerspoon Accessibility permission is granted if you intend to use it

## Known Manual Steps

- Hammerspoon is not auto-launched by `dotfiles services`
- external assets such as `simple-bar` may require `dotfiles assets`
- local machine-only shell config belongs in `~/.zshrc.local`

## If Something Looks Wrong

Use:

```bash
dotfiles check
dotfiles doctor
```

Then see `docs/troubleshooting.md`.
