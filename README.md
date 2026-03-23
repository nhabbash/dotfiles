# Dotfiles

Personal dev environment managed with Nix + home-manager for Mac and Linux.

## How it works

Configs live in `configs/` and are **symlinked** into place by home-manager on every rebuild. Editing a file in `configs/` is the same as editing `~/.config/zellij/config.kdl` — they're the same file via symlink. No rebuild needed for config changes, only for nix changes.

```
configs/zsh/        → ~/.config/zsh/
configs/zellij/     → ~/.config/zellij/
configs/kitty/      → ~/.config/kitty/
configs/ghostty/    → ~/.config/ghostty/ (+ Library/Application Support on macOS)
configs/git/        → ~/.gitconfig
configs/agents/     → ~/.config/agents/
configs/claude/     → ~/.claude/
configs/codex/      → ~/.config/codex/
configs/cursor-agent/ → ~/.config/cursor-agent/
configs/pi/         → ~/.config/pi/
```

`~/.zshrc` is a **local, untracked file** (created by bootstrap). Add machine-specific one-off shell config there or in `~/.zshrc.local`.

---

## First-time setup

```bash
git clone git@github.com:nhabbash/dotfiles.git ~/Development/dotfiles
cd ~/Development/dotfiles
bash scripts/dotfiles.sh bootstrap [hostname]
```

Hostnames: `personal-macbook` (default on macOS) · `work-macbook` · `linux-server` · `linux-desktop`

Bootstrap will:
1. Install Nix if missing (then ask you to restart shell and re-run)
2. Back up or delete any existing files that nix will manage
3. Build and activate the nix configuration
4. Create `~/.zshrc`

---

## Daily use

All commands are available as the `dotfiles` alias once your shell is set up.

| Command | What it does |
|---|---|
| `dotfiles pull` | Pull remote changes, rebuild only if nix files changed |
| `dotfiles push [message]` | Commit all changes and push |
| `dotfiles status [hostname]` | Show repo state and local service status |
| `dotfiles rebuild [hostname]` | Force a full nix rebuild |
| `dotfiles theme [name|list]` | Switch the active Ghostty theme |
| `dotfiles regen` | Regenerate derived config from source manifests |
| `dotfiles check [hostname]` | Verify repo integrity and generated drift |
| `dotfiles assets [hostname]` | Install explicit external assets such as pinned widgets |
| `dotfiles snapshot [hostname]` | Capture current repo and runtime state before/after cutover |
| `dotfiles preflight [hostname]` | Run snapshot + integrity checks before switching or rebuilding |
| `dotfiles services [hostname]` | Start/reload local desktop services after setup |
| `dotfiles doctor [hostname]` | Diagnose setup, links, installs, and service health |
| `rebuild` | Shorthand alias for `dotfiles rebuild` |

---

## If You Are New To This Repo

Use this rule first:

- edit `configs/*` for normal tool config changes
- run `dotfiles regen` only for generated config
- run `dotfiles rebuild` only for `.nix` / host / package changes
- run `dotfiles services` or `dotfiles doctor` for runtime issues

Common examples:

- change shell aliases: edit `configs/zsh/aliases.zsh`
- change AeroSpace bindings: edit `configs/aerospace/aerospace.toml`
- change Hammerspoon guide UI: edit `configs/hammerspoon/`
- add a package: edit `modules/packages.nix`, then `dotfiles rebuild`
- add a macOS app: edit `modules/macos/apps.nix`, then `dotfiles rebuild`

If you are unsure where something belongs, read `docs/architecture.md` and
`docs/adding-tools.md` before changing mechanism files.

---

## Workflows

### Changing a config (zsh, zellij, ghostty, kitty…)

Just edit the file in `configs/`. No rebuild needed — the symlink means it takes effect immediately (or on next shell start for zsh).

```bash
# Example: tweak zellij layout
vim configs/zellij/layouts/default.kdl

# Then push when happy
dotfiles push "zellij: adjust layout"
```

### Switching Ghostty themes

Ghostty now uses a tracked custom theme file at `configs/ghostty/themes/current`.
The vendored Kanso variants live next to it:

- `kanso-zen`
- `kanso-ink`
- `kanso-mist`
- `kanso-pearl`

Use:

```bash
dotfiles theme list
dotfiles theme kanso-zen
dotfiles theme kanso-mist
```

Shorthand:

```bash
gtheme kanso-zen
```

`dotfiles theme` updates `configs/ghostty/themes/current` and tries to run
`ghostty +reload-config`. If the CLI reload is unavailable, press `cmd+r` in
Ghostty.

### Changing nix config (packages, plugins, system settings)

Edit the `.nix` files in `modules/` or `hosts/`, then rebuild:

```bash
vim modules/packages.nix
dotfiles rebuild
# or just: rebuild
```

This is also how new workstation tools are added. The terminal screensaver
wrapper in this repo depends on the `terminaltexteffects` package, so after
pulling these changes you need one rebuild before `screensaver` / `saver`
works.

### Regenerating derived config

When a file is generated from a canonical source, regenerate it explicitly:

```bash
dotfiles regen
```

Use this when you edit a manifest such as `configs/keymaps.toml`.

### Tuning the CRT shader

Ghostty now reads a stable active shader file:

- active shader: `configs/ghostty/shaders/crt-clean.glsl`
- safe pristine backup: `configs/ghostty/shaders/crt-clean.pristine.glsl`
- lab template source: `configs/ghostty/shaders/crt-lab.glsl`

Use the lab like this:

```bash
crt-lab
```

Then:

- adjust presets/parameters in the TUI
- the parameter list scrolls if your terminal is shorter than the full control set
- `o` enables the shader
- `x` disables the shader
- `z` restores the pristine `crt-clean.glsl` baseline
- press `cmd+r` in Ghostty to reload and inspect the current `crt-clean.glsl`

`crt-lab` rewrites `crt-clean.glsl` directly so it uses the same known-good shader path as `crt-on` / `crt-off`.
It also keeps a local machine-only JSON state file next to the TUI script so
your last preset and knob positions survive closing and reopening the lab.
The current lab also includes expanded presets such as `Studio Clean`,
`Broadcast`, `IBM VGA`, `Amber Mono`, and `Terminal Sicko`.
For readability-first tuning, start from `Daily Driver`; the TUI also shows
inline `safe<=` hints for the most blur-prone parameters.

If you want to toggle shaders entirely:

- `crt-on` enables the `crt-clean.glsl` shader line in Ghostty config
- `crt-off` disables the active shader line
- after either command, press `cmd+r` in Ghostty

### Running the terminal screensaver

The shell wrapper is:

```bash
screensaver
```

Short aliases:

```bash
saver
tte-saver
```

Examples:

```bash
screensaver
screensaver -s
screensaver -b
screensaver -f
screensaver matrix
screensaver --effect rain --message "away for coffee"
screensaver --effect synthgrid -- --final-gradient-direction horizontal
```

Behavior:

- outside `zellij`, it uses the terminal alternate screen and restores your
  previous contents when you press any key
- inside `zellij`, the wrapper opens a temporary fullscreen floating pane so it
  covers the tab instead of replacing a tiled pane
- plain `screensaver` animates the currently visible Ghostty screen
- `screensaver -s` also animates the currently visible Ghostty screen
- `screensaver -b` animates the Ghostty scrollback buffer
- `screensaver -f` uses generated fullscreen filler text instead of capture
- press any key to stop it
- `screensaver --list` prints the default random effect pool

### Checking repo integrity

Before a risky rebuild or refactor, run:

```bash
dotfiles check
```

This validates shell scripts, Python scripts, generated-config drift, and a
lightweight Nix evaluation for the active host.

### Installing external assets

Some tools are not packaged directly in Nix or Homebrew and are treated as
explicit external assets. Install them with:

```bash
dotfiles assets
```

This is intentionally separate from `dotfiles rebuild`, so declarative applies
do not fetch mutable upstream state during activation.

### Preflight before switching

Before a cutover or risky rebuild, run:

```bash
dotfiles preflight
```

This captures a snapshot and runs the same integrity checks as `dotfiles check`.

### Syncing to another machine

```bash
# On the other machine — pull and rebuild if nix changed
dotfiles pull
```

`dotfiles pull` will abort if you have uncommitted local changes. You'll see a warning at login too. Commit or push first:

```bash
dotfiles status       # see what's dirty
dotfiles push         # commit and push, then pull on the other machine
```

### Resolving a conflict between machines

If you edited the same file on two machines before syncing:

```bash
# Push the current machine's changes first
dotfiles push "my local changes"

# On the other machine, if pull fails with conflicts:
git -C ~/Development/dotfiles status      # see conflicting files
# Edit the files to resolve, then:
dotfiles push "merge: resolve conflict"
```

### Starting local desktop services

On macOS, `dotfiles rebuild` and `dotfiles bootstrap` finish by starting the local desktop apps that are safe to manage automatically. You can also run that step manually:

```bash
dotfiles services
```

Today that starts or reloads:
- AeroSpace
- Übersicht only when the current profile should use it

Hammerspoon is intentionally not auto-launched by `dotfiles services`, because
launching it directly can pop the console. If you want Hammerspoon running in
the background, configure it through its own login/background behavior rather
than tying that to rebuild.

### Checking what is ready

Use the quick snapshot when you want to know what is configured and what is actually running:

```bash
dotfiles status
```

Use the diagnostic pass when you want explicit problems called out:

```bash
dotfiles doctor
```

On macOS, these commands currently check:
- git dirtiness in the dotfiles repo
- whether AeroSpace, Hammerspoon, and Übersicht are installed
- whether the relevant apps are running
- whether `~/.hammerspoon` is linked
- whether Hammerspoon has an Accessibility permission entry

### Adding a new tool/config

1. Add the config files under `configs/<tool>/`
2. Add a link entry in `modules/links.nix`
3. Add the package in `modules/packages.nix` if needed
4. Run `dotfiles rebuild`

### Keeping zshrc local

`~/.zshrc` is not tracked. For experiments or local-only shell config use:
- `~/.zshrc.local` — sourced automatically, never tracked
- `configs/zsh/personal.zsh` or `configs/zsh/work.zsh` — tracked, machine-profile specific

### Updating nix flake inputs

```bash
nfu          # alias for: nix flake update ~/Development/dotfiles
rebuild      # apply updated inputs
```

### Garbage collecting old nix generations

```bash
ngc          # alias for: nix-collect-garbage -d && nix store optimise
```

---

## Zsh config layout

| File | Purpose | Needs rebuild? |
|---|---|---|
| `configs/zsh/core.zsh` | PATH, Homebrew, SSH, keybindings | No |
| `configs/zsh/aliases.zsh` | All aliases | No |
| `configs/zsh/functions.zsh` | Shell functions | No |
| `configs/zsh/claude.zsh` | Claude Code env vars | No |
| `configs/zsh/zellij.zsh` | Zellij tab naming + tmux shim | No |
| `configs/zsh/personal.zsh` | Personal machine overrides | No |
| `configs/zsh/work.zsh` | Work machine overrides | No |
| `modules/shell/zsh.nix` | Plugins, oh-my-zsh, history settings | **Yes** |
| `~/.zshrc.local` | Local experiments, untracked | No |

---

## More documentation

- `docs/architecture.md` — ownership model and latency classes
- `docs/operations.md` — rebuild/regen/check/services/doctor workflow
- `docs/hosts.md` — host/profile dimensions
- `docs/adding-tools.md` — how to classify and add new tools
- `docs/tooling-map.md` — plain-English map of the major tools in this repo
- `docs/new-machine.md` — bootstrap and post-bootstrap checklist for a fresh machine
- `docs/verification.md` — how to verify tools are using repo-managed config
- `docs/troubleshooting.md` — what to do first when something is wrong
- `docs/cutover.md` — safe switch and rollback procedure for the refactor branch
- `scripts/generated/` — implementation for generated config workflows
- `scripts/experiments/` — implementation for mutable experimental tools
