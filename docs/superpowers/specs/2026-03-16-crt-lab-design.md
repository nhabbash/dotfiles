# crt-lab Design Spec
**Date:** 2026-03-16
**Status:** Approved

## Overview

`crt-lab` is an interactive terminal TUI for live-tuning CRT shader parameters in Ghostty. It provides a single-view knob editor with built-in presets and generates `crt-lab.glsl` — an extended version of `crt-clean.glsl` that adds animated scanlines via `iTime`. The user adjusts parameters, presses `r` to reload Ghostty and see the effect, and saves with `w` when satisfied.

## Goals

- Browse curated presets and tweak individual parameters without leaving the terminal
- See changes live by pressing `r` (triggers Cmd+R in Ghostty)
- Add realistic animated scanlines (phosphor beam simulation) not present in existing shaders
- Optional screenshots saved to `/tmp`, paths printed on quit (no clipboard)
- Save tuned values persistently with `w`

## Non-Goals

- Does not replace `crt-cycle` (preset-only browsing tool)
- Does not replace `crt-tune` (one-shot CLI setter)
- No multi-pass rendering, ping-pong buffers, or external dependencies

---

## Script: `scripts/crt-lab`

### Language & Style

Pure bash, matching the style of `crt-cycle` and `crt-tune`. Uses `tput` and ANSI escape codes for the TUI. No Python, no `ncurses` binary dependency.

### Deployment

Added to `scripts/crt-lab`, committed with `chmod +x`. Scripts are not on PATH automatically — a `crt-lab` alias is added to `configs/zsh/aliases.zsh`:
```bash
alias crt-lab='$DOTFILES_DIR/scripts/crt-lab'
```
Same pattern as `rebuild`/`dotfiles` aliases. No Nix changes needed: `crt-lab.glsl` is covered by the existing shaders dir symlink (`".config/ghostty/shaders" = "configs/ghostty/shaders"`), which auto-exposes all `.glsl` files in that directory.

### Invocation

```bash
crt-lab            # starts with preset 1 (Clean)
crt-lab --preset 3 # starts on a specific preset (1-indexed)
```

**On start:** patches both Ghostty config files to use `crt-lab.glsl` instead of `crt-clean.glsl`. Same `patch_configs` pattern as `crt-cycle`:
```bash
# Both files:
REAL_CONFIG="$HOME/Library/Application Support/com.mitchellh.ghostty/config"
DOTS_CONFIG="$HOME/Development/dotfiles/configs/ghostty/config"
patch_configs() { sed -i '' "s|${1}|${2}|g" "$REAL_CONFIG" 2>/dev/null || true
                  sed -i '' "s|${1}|${2}|g" "$DOTS_CONFIG" 2>/dev/null || true; }
```

**On exit (trap EXIT INT TERM):** restores `crt-clean.glsl` in both configs. Trap is set before any patching so even abnormal exits clean up. Parallel instances are safe — each restores to `crt-clean.glsl` on exit (last writer wins, which is acceptable).

### TUI Layout

Single view. No mode switching.

```
 CRT Lab ─────────────────────────── Warm Analog [3/7] ──────

  n/p preset   ↑↓ select   ←→ nudge   [/] coarse
  r reload   s screenshot   w save   q quit

  ▸ Curvature      ████████░░░░░░░░  0.48   barrel distortion
    Scan Intensity  ██████░░░░░░░░░░  0.35   scanline darkness
    Scan Density    ████████░░░░░░░░  0.50   line spacing
    Scan Speed      ███░░░░░░░░░░░░░  0.20 ⟳ scroll rate
    Phosphor        ████░░░░░░░░░░░░  0.30 ⟳ beam asymmetry
    Flicker         ██░░░░░░░░░░░░░░  0.10 ⟳ 60Hz pulse
    Chroma Shift    ████░░░░░░░░░░░░  0.25   RGB split
    Bloom           ████████████░░░░  0.70   glow
    Bloom Radius    ██████░░░░░░░░░░  0.40   spread
    Dot Matrix      ███░░░░░░░░░░░░░  0.18   phosphor dots
    Vignette        ██░░░░░░░░░░░░░░  0.10   edge darkening
    Brightness      ███████░░░░░░░░░  0.35   creative boost
    Grain           ██░░░░░░░░░░░░░░  0.15   film noise
```

- `▸` marks the selected parameter
- `⟳` marks the three animated parameters (use `iTime`)
- Bar: 16 `█`/`░` characters, filled proportional to value (0.0–1.0)

### Key Bindings

| Key | Action |
|-----|--------|
| `↑` / `↓` (ESC[A / ESC[B) | Select parameter |
| `←` / `→` (ESC[D / ESC[C) | Nudge value ±fine step |
| `[` / `]` | Coarse nudge (±0.10) |
| `n` / `p` | Next / previous preset |
| `r` | Write shader + send Cmd+R to Ghostty via AppleScript |
| `s` | Take screenshot → `/tmp/crt-lab-<PID>/` |
| `w` | Save current values to template + print `crt-tune` equivalent |
| `q` | Quit (restore `crt-clean.glsl` in config, print screenshot paths) |

**Arrow key parsing:** `read -r -s -n 1 key` reads one byte. If `key == $'\033'`, read 1 more byte (`[`), then 1 more (letter). The triple forms ESC[A/B/C/D for up/down/right/left. This is the standard portable approach used by `crt-cycle`. `[` and `]` replace Shift+Arrow (which uses 6-byte sequences, not reliable in raw bash reads).

### Parameter Definitions

| # | Name | GLSL Define | Range | Fine Step | Coarse | Internal Mapping | Perceptual note |
|---|------|-------------|-------|-----------|--------|-----------------|-----------------|
| 1 | Curvature | `CURVATURE` | 0–1 | 0.02 | 0.10 | `x² × 0.08` | quadratic in shader; linear slider distributes effect evenly |
| 2 | Scan Intensity | `SCAN_INTENSITY` | 0–1 | 0.02 | 0.10 | `x × 0.7` | linear |
| 3 | Scan Density | `SCAN_DENSITY` | 0–1 | 0.10 | 0.20 | `floor(mix(2,8,1-x))` → integer periods | Only 7 distinct outputs (periods 2–8); coarser steps match reality |
| 4 | Scan Speed | `SCAN_SPEED` | 0–1 | 0.02 | 0.10 | `sqrt(x) × 150` px/s | sqrt remap: most interesting range is 0–0.4 |
| 5 | Phosphor | `PHOSPHOR_DECAY` | 0–1 | 0.02 | 0.10 | `sqrt(x) × 8` (decay exponent) | sqrt remap: 0=pure sine, 1=full asymmetric |
| 6 | Flicker | `FLICKER_AMP` | 0–1 | 0.02 | 0.10 | `x × 0.04` (amplitude) | Very subtle (0–4% brightness swing) |
| 7 | Chroma Shift | `CHROMA_SHIFT` | 0–1 | 0.02 | 0.10 | `x² × 0.005` | quadratic in shader; linear slider distributes effect evenly |
| 8 | Bloom | `BLOOM` | 0–1 | 0.02 | 0.10 | direct | — |
| 9 | Bloom Radius | `BLOOM_RADIUS` | 0–1 | 0.05 | 0.20 | `mix(4,24,x)` px | coarser steps at wide radius |
| 10 | Dot Matrix | `DOT_MATRIX` | 0–1 | 0.02 | 0.10 | `x × 0.5` | — |
| 11 | Vignette | `VIGNETTE` | 0–1 | 0.02 | 0.10 | `mix(0.001,0.35,x²)` | quadratic in shader; linear slider distributes effect evenly |
| 12 | Brightness | `BRIGHTNESS` | 0–1 | 0.02 | 0.10 | `mix(0.85,1.35,x)` | — |
| 13 | Grain | `GRAIN_AMP` | 0–1 | 0.02 | 0.10 | `x × 0.04` (amplitude) | — |

All values clamped to [0.0, 1.0] after every nudge.

### Preset Values (complete 7×13 table)

13 numeric values per preset (indices 0–12, matching PARAM\_VALS order):

| # | Name | curv | scan | den | spd | phos | flick | chroma | bloom | bl\_r | dot | vig | bright | grain |
|---|------|------|------|-----|-----|------|-------|--------|-------|-------|-----|-----|--------|-------|
| 1 | Clean | 0.30 | 0.10 | 0.50 | 0.00 | 0.00 | 0.00 | 0.00 | 0.10 | 0.10 | 0.00 | 0.05 | 0.45 | 0.00 |
| 2 | Classic | 0.48 | 0.35 | 0.50 | 0.10 | 0.15 | 0.05 | 0.22 | 0.55 | 0.30 | 0.00 | 0.10 | 0.40 | 0.05 |
| 3 | Warm Analog | 0.48 | 0.38 | 0.50 | 0.25 | 0.55 | 0.10 | 0.18 | 0.70 | 0.35 | 0.00 | 0.12 | 0.38 | 0.20 |
| 4 | P31 Green | 0.50 | 0.42 | 0.50 | 0.15 | 0.40 | 0.08 | 0.00 | 0.00 | 0.00 | 0.00 | 0.15 | 0.38 | 0.20 |
| 5 | High Refresh | 0.25 | 0.25 | 0.70 | 0.60 | 0.10 | 0.05 | 0.15 | 0.35 | 0.20 | 0.00 | 0.08 | 0.50 | 0.05 |
| 6 | Heavy Phosphor | 0.45 | 0.40 | 0.50 | 0.15 | 0.80 | 0.25 | 0.20 | 0.80 | 0.50 | 0.10 | 0.15 | 0.35 | 0.15 |
| 7 | Retro Max | 0.70 | 0.60 | 0.50 | 0.30 | 0.65 | 0.20 | 0.50 | 0.75 | 0.45 | 0.40 | 0.30 | 0.38 | 0.30 |

**Per-preset metadata** (separate boolean flag, not part of PARAM\_VALS):

```bash
PRESET_PGREEN=(0 0 0 1 0 0 0)  # index 3 (P31 Green) emits #define PHOSPHOR_GREEN
```

When PHOSPHOR\_GREEN is active the TUI shows `[P31]` in the header line.

### State Management

```bash
# Indexed parallel arrays (bash 3.x compatible)
PARAM_NAMES=("Curvature" "Scan Intensity" ...)    # 13 entries
PARAM_DEFINES=("CURVATURE" "SCAN_INTENSITY" ...)  # GLSL define names
PARAM_FINE=(0.02 0.02 0.10 ...)                    # fine step per param
PARAM_VALS=(...)                                    # current float values (mutable)

SELECTED=0      # currently highlighted row (0-indexed)
PRESET_IDX=0    # current preset (0-indexed)

# Preset data: flat arrays, 13 values each, loaded by index
PRESET_NAMES=("Clean" "Classic" ...)
PRESET_VALS_1=(0.30 0.10 0.50 0.00 0.00 0.00 0.00 0.10 0.10 0.00 0.05 0.45 0.00)
PRESET_VALS_2=(0.48 0.35 0.50 0.10 0.15 0.05 0.22 0.55 0.30 0.00 0.10 0.40 0.05)
# ... one array per preset
PRESET_PGREEN=(0 0 0 1 0 0 0)  # P31 Green flag per preset
```

Loading a preset: copies the corresponding `PRESET_VALS_N` array into `PARAM_VALS`. Nudging a param: updates `PARAM_VALS[$SELECTED]`, clamps to [0,1], re-renders. Shader is **not** auto-reloaded — user presses `r`.

### Save Behavior (`w`)

`w` writes the current 13 `PARAM_VALS` into the `#define` block of `configs/ghostty/shaders/crt-lab.glsl` (the template in the dotfiles repo). This makes the values persistent across `crt-lab` sessions.

Additionally prints:
```
Saved to configs/ghostty/shaders/crt-lab.glsl

Equivalent crt-tune command (9 shared params):
  crt-tune --scale 0.33 --thin 0.35 --blur -2.75 --mask 0.65 --min-vin 0.50 --warp --mask-type shadow
```

**Does NOT modify `crt-clean.glsl`** — that file stays independent. The save writes to `crt-lab.glsl` only.

---

## Shader: `configs/ghostty/shaders/crt-lab.glsl`

The file in the dotfiles repo is the **template** — it contains only the GLSL body with no `#define` values. The script prepends a `#define` block before writing to `~/.config/ghostty/shaders/crt-lab.glsl`.

### All Defines

```glsl
// crt-lab — generated <timestamp>
// Preset: <name>
#define ROWS           <N>        // terminal rows at runtime (tput lines)
#define COLS           <N>        // terminal cols at runtime (tput cols)
#define CURVATURE      <0–1>
#define SCAN_INTENSITY <0–1>
#define SCAN_DENSITY   <0–1>
#define SCAN_SPEED     <0–1>
#define PHOSPHOR_DECAY <0–1>
#define FLICKER_AMP    <0–1>
#define CHROMA_SHIFT   <0–1>
#define BLOOM          <0–1>
#define BLOOM_RADIUS   <0–1>
#define DOT_MATRIX     <0–1>
#define VIGNETTE       <0–1>
#define BRIGHTNESS     <0–1>
#define GRAIN_AMP      <0–1>
// #define PHOSPHOR_GREEN 1    (uncommented for P31 preset only)
```

### New Defines vs `crt-clean.glsl`

| Define | Purpose |
|--------|---------|
| `SCAN_SPEED` | Scrolls scanlines via `iTime` |
| `PHOSPHOR_DECAY` | Morphs beam profile from sine to asymmetric exponential |
| `FLICKER_AMP` | 60Hz brightness oscillation amplitude |
| `GRAIN_AMP` | Film grain amplitude (replaces the per-preset grain in `crt-cycle`) |
| `PHOSPHOR_GREEN` | Enables luma→green monochrome tint |

### Animated Scanline Model

Replaces the `sin²` profile in `crt-clean.glsl`:

```glsl
#define PI 3.14159265359

// Scrolling phase: scanlines move downward at SCAN_SPEED px/s
float scrollRate = sqrt(SCAN_SPEED) * 150.0;   // sqrt for perceptual linearity
float scrolledY  = fragCoord.y - iTime * scrollRate;
float period     = floor(mix(2.0, 8.0, 1.0 - SCAN_DENSITY));
float phase      = mod(scrolledY, period) / period; // 0..1

// Beam profile: mix symmetric sine with asymmetric phosphor decay
float sineScan = pow(sin(phase * PI), 2.0);

float decayExp  = sqrt(PHOSPHOR_DECAY) * 8.0;
// Normalize asymmetric curve so its peak ≈ 1.0 regardless of decayExp.
// The denominator (1-exp(-e)) approaches 0 as e→0, guarded by max() for
// numerical stability only — output is still correct at PHOSPHOR_DECAY=0
// because mix() weight is also 0.
float decayNorm  = 1.0 / max(1.0 - exp(-decayExp), 0.001);
float decayScan  = exp(-phase * decayExp) * (1.0 - exp(-decayExp)) * decayNorm;

float beamProfile = mix(sineScan, decayScan, PHOSPHOR_DECAY);
float scanline    = 1.0 - SCAN_INTENSITY * 0.7 * beamProfile;
color *= scanline;
```

At `PHOSPHOR_DECAY=0`: `decayExp=0`, `mix` weight=0 → `beamProfile = sineScan` exactly. No div-by-zero because `mix(a,b,0) = a` regardless of `b`.

**Flicker (60Hz brightness pulse):**
```glsl
// 60Hz on a 60Hz display produces a stationary-looking oscillation — intentional.
// The effect is felt as a subtle organic "breathing" rather than visible flicker.
float flicker = 1.0 + FLICKER_AMP * 0.04 * sin(iTime * 2.0 * PI * 60.0);
color *= flicker;
```
`FLICKER_AMP` is 0–1; multiplied by `0.04` → max amplitude is 4% brightness swing, below perceptual flicker threshold at typical display brightness.

**Grain:**
```glsl
if (GRAIN_AMP > 0.0) {
    float gr = fract(sin(dot(fragCoord.xy + iTime * 743.0,
                             vec2(12.9898, 78.233))) * 43758.5453) - 0.5;
    color += gr * GRAIN_AMP * 0.04;
}
```

**Phosphor green tint (conditional):**
```glsl
#ifdef PHOSPHOR_GREEN
    float luma = dot(color, vec3(0.2126, 0.7152, 0.0722));
    color = luma * vec3(0.20, 1.0, 0.28);
#endif
```

### Full GLSL Structure

The body follows `crt-clean.glsl` order with extensions:

1. Curvature (existing)
2. Chromatic aberration (existing)
3. Bloom (existing)
4. **Animated scanlines** (new — replaces crt-clean scanlines)
5. **Flicker** (new)
6. Dot matrix (existing)
7. Vignette (existing)
8. **Grain** (new — extracted from crt-cycle warm analog/green presets)
9. **Phosphor green tint** (new, conditional)
10. Brightness compensation (existing)

---

## Screenshot Behavior

- `s` captures the Ghostty window via `osascript` (window bounds) + `screencapture -x -R`
- Saved to `/tmp/crt-lab-<PID>/<counter>_<preset_name>.png` where `<counter>` is a zero-padded 2-digit integer incrementing from `01` per session
- `<preset_name>` is the preset name with spaces/special chars replaced by `_`
- File is resized to 1500px width via `sips --resampleWidth 1500` (same as crt-cycle)
- Empty/permission-failure files (<5KB) are deleted and an error is shown inline
- **No clipboard.** On quit, if any screenshots exist:
  ```
  Screenshots saved:
    /tmp/crt-lab-1234/01_classic.png
    /tmp/crt-lab-1234/02_warm_analog.png
  ```

---

## Files Changed / Created

| Path | Action |
|------|--------|
| `scripts/crt-lab` | Create, `chmod +x` |
| `configs/ghostty/shaders/crt-lab.glsl` | Create (GLSL template body, no defines) |
| `configs/zsh/aliases.zsh` | Add `alias crt-lab='$DOTFILES_DIR/scripts/crt-lab'` |

No Nix changes required: shaders dir is already fully symlinked via `".config/ghostty/shaders" = "configs/ghostty/shaders"`, so `crt-lab.glsl` is automatically exposed. Scripts use aliases (not PATH), same as `rebuild`/`dotfiles`.

`crt-cycle`, `crt-tune`, and `crt-clean.glsl` are **not modified**.

---

## Constraints & Assumptions

- macOS only (`osascript`, `screencapture`, AppleScript Cmd+R)
- `iTime` available in Ghostty shaders (confirmed: used in crt-cycle warm analog grain formula)
- Terminal supports ANSI 256-color and UTF-8 block characters (`█ ░`)
- `bc` available for float arithmetic (standard on macOS)
- `sips` available for image resizing (macOS built-in)
