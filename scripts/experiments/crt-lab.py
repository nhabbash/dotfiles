#!/usr/bin/env python3
import argparse
import curses
import json
import shutil
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class ParameterSpec:
    define: str
    label: str
    desc: str
    animated: bool = False
    fine_step: float = 0.02
    coarse_step: float = 0.10
    curve: str = "linear"
    shader_min: float = 0.0
    shader_max: float = 1.0
    readable_max: float | None = None


@dataclass
class Preset:
    name: str
    ui_values: list[float]
    p31: bool = False
    amber: bool = False
    mask_mode: str = "none"


PARAMS = [
    ParameterSpec("CURVATURE", "Curvature", "barrel distortion", False, 0.02, 0.10, "sqrt", 0.0, 1.0, 0.45),
    ParameterSpec("SCAN_INTENSITY", "Scan Intensity", "scanline darkness", False, 0.02, 0.10, "linear"),
    ParameterSpec("SCAN_DENSITY", "Scan Density", "line spacing", False, 0.05, 0.20, "linear"),
    ParameterSpec("SCAN_SPEED", "Scan Speed", "scroll rate", True, 0.01, 0.05, "quadratic", 0.0, 0.20),
    ParameterSpec("SCAN_THICKNESS", "Scan Thickness", "beam width", False, 0.02, 0.10, "linear"),
    ParameterSpec("PHOSPHOR_DECAY", "Phosphor", "beam asymmetry", True, 0.02, 0.10, "quadratic"),
    ParameterSpec("FLICKER_AMP", "Flicker", "visible pulse", True, 0.01, 0.05, "sqrt", 0.0, 1.0),
    ParameterSpec("CHROMA_SHIFT", "Chroma Shift", "RGB split", False, 0.02, 0.10, "sqrt", 0.0, 1.0, 0.35),
    ParameterSpec("CONVERGENCE", "Convergence", "edge channel split", False, 0.01, 0.05, "sqrt", 0.0, 1.0, 0.28),
    ParameterSpec("BLOOM", "Bloom", "glow", False, 0.02, 0.10, "linear", 0.0, 1.0, 0.32),
    ParameterSpec("BLOOM_RADIUS", "Bloom Radius", "spread", False, 0.05, 0.20, "linear"),
    ParameterSpec("HALATION", "Halation", "bright fringe", False, 0.02, 0.10, "linear", 0.0, 1.0, 0.25),
    ParameterSpec("H_SOFTNESS", "H Softness", "horizontal bleed", False, 0.01, 0.05, "sqrt", 0.0, 1.0, 0.22),
    ParameterSpec("VERTICAL_BLEED", "V Bleed", "vertical bleed", False, 0.01, 0.05, "sqrt", 0.0, 1.0, 0.18),
    ParameterSpec("DOT_MATRIX", "Dot Matrix", "phosphor dots", False, 0.01, 0.05, "quadratic", 0.0, 0.30),
    ParameterSpec("EDGE_SOFTNESS", "Edge Softness", "corner defocus", False, 0.01, 0.05, "sqrt", 0.0, 1.0, 0.20),
    ParameterSpec("VIGNETTE", "Vignette", "edge darkening", False, 0.02, 0.10, "linear"),
    ParameterSpec("BRIGHTNESS", "Brightness", "creative boost", False, 0.02, 0.10, "linear"),
    ParameterSpec("GRAIN_AMP", "Grain", "film noise", True, 0.01, 0.05, "sqrt", 0.0, 1.0),
    ParameterSpec("JITTER", "Jitter", "line instability", True, 0.01, 0.05, "quadratic", 0.0, 1.0),
]


PRESETS = [
    Preset("Daily Driver", [0.24, 0.10, 0.54, 0.00, 0.42, 0.00, 0.00, 0.06, 0.06, 0.08, 0.10, 0.06, 0.04, 0.02, 0.05, 0.03, 0.08, 0.44, 0.00, 0.00]),
    Preset("Studio Clean", [0.28, 0.08, 0.50, 0.00, 0.38, 0.00, 0.00, 0.04, 0.03, 0.08, 0.10, 0.04, 0.06, 0.03, 0.00, 0.05, 0.08, 0.46, 0.00, 0.00]),
    Preset("Clean", [0.34, 0.12, 0.50, 0.00, 0.44, 0.00, 0.00, 0.08, 0.10, 0.12, 0.14, 0.08, 0.10, 0.05, 0.03, 0.08, 0.08, 0.44, 0.00, 0.00]),
    Preset("Classic", [0.50, 0.34, 0.50, 0.10, 0.50, 0.15, 0.12, 0.26, 0.20, 0.52, 0.22, 0.20, 0.18, 0.10, 0.04, 0.16, 0.12, 0.40, 0.10, 0.02], False, False, "shadow"),
    Preset("Broadcast", [0.36, 0.20, 0.58, 0.02, 0.48, 0.04, 0.02, 0.10, 0.08, 0.22, 0.18, 0.10, 0.08, 0.06, 0.04, 0.12, 0.10, 0.44, 0.02, 0.00]),
    Preset("IBM VGA", [0.42, 0.26, 0.62, 0.03, 0.52, 0.05, 0.02, 0.18, 0.12, 0.18, 0.14, 0.08, 0.05, 0.04, 0.10, 0.12, 0.08, 0.46, 0.01, 0.00], False, False, "slot"),
    Preset("Warm Analog", [0.48, 0.38, 0.50, 0.18, 0.56, 0.55, 0.16, 0.20, 0.18, 0.62, 0.28, 0.30, 0.18, 0.10, 0.00, 0.18, 0.12, 0.38, 0.28, 0.03]),
    Preset("P31 Green", [0.50, 0.42, 0.50, 0.12, 0.55, 0.42, 0.12, 0.00, 0.00, 0.00, 0.00, 0.14, 0.06, 0.04, 0.00, 0.16, 0.15, 0.40, 0.22, 0.02], True),
    Preset("Amber Mono", [0.48, 0.38, 0.50, 0.10, 0.54, 0.38, 0.10, 0.00, 0.00, 0.00, 0.00, 0.12, 0.05, 0.03, 0.00, 0.14, 0.14, 0.42, 0.18, 0.01], False, True),
    Preset("High Refresh", [0.24, 0.22, 0.72, 0.65, 0.32, 0.10, 0.06, 0.12, 0.08, 0.30, 0.16, 0.08, 0.04, 0.04, 0.02, 0.08, 0.06, 0.50, 0.04, 0.02]),
    Preset("Heavy Phosphor", [0.45, 0.40, 0.50, 0.14, 0.60, 0.82, 0.30, 0.22, 0.16, 0.78, 0.50, 0.35, 0.18, 0.12, 0.14, 0.22, 0.14, 0.36, 0.18, 0.04], False, False, "grille"),
    Preset("Terminal Sicko", [0.72, 0.62, 0.48, 0.24, 0.68, 0.76, 0.34, 0.40, 0.34, 0.80, 0.52, 0.44, 0.24, 0.16, 0.26, 0.32, 0.28, 0.34, 0.30, 0.10], False, False, "shadow"),
]


def clamp01(value: float) -> float:
    return max(0.0, min(1.0, value))


def apply_curve(value: float, curve: str) -> float:
    value = clamp01(value)
    if curve == "linear":
        return value
    if curve == "quadratic":
        return value * value
    if curve == "cubic":
        return value * value * value
    if curve == "sqrt":
        return value ** 0.5
    raise ValueError(f"Unknown curve: {curve}")


class CRTLAb:
    def __init__(self, root: Path, start_preset: int) -> None:
        self.root = root
        self.shaders_dir = Path.home() / ".config/ghostty/shaders"
        self.shader_out = self.shaders_dir / "crt-clean.glsl"
        self.shader_pristine = self.shaders_dir / "crt-clean.pristine.glsl"
        self.shader_session_bak = self.shaders_dir / "crt-clean.session.bak.glsl"
        self.template_file = self.root / "configs/ghostty/shaders/crt-lab.glsl"
        self.ghostty_config = self.root / "configs/ghostty/config"
        self.state_file = Path(__file__).with_suffix(".state.json")
        self.template_body = self._load_template_body()
        self.selected = 0
        self.preset_idx = max(0, min(start_preset, len(PRESETS) - 1))
        self.ui_values = PRESETS[self.preset_idx].ui_values.copy()
        self.status = "Press Cmd+R in Ghostty after changes."
        self.dirty = True
        self.last_dims = (24, 80)
        self._backup_current_shader()
        self._load_state()

    def _load_template_body(self) -> str:
        lines: list[str] = []
        for line in self.template_file.read_text().splitlines():
            stripped = line.lstrip()
            if stripped.startswith("//"):
                continue
            if stripped.startswith("#define PI"):
                continue
            lines.append(line)
        return "\n".join(lines).rstrip() + "\n"

    def _backup_current_shader(self) -> None:
        self.shaders_dir.mkdir(parents=True, exist_ok=True)
        if self.shader_out.exists():
            shutil.copy2(self.shader_out, self.shader_session_bak)

    def _load_state(self) -> None:
        if not self.state_file.exists():
            return
        try:
            data = json.loads(self.state_file.read_text())
        except (OSError, json.JSONDecodeError):
            self.status = "Ignoring invalid local CRT lab state file."
            return

        preset_idx = data.get("preset_idx")
        ui_values = data.get("ui_values")
        if isinstance(preset_idx, int) and 0 <= preset_idx < len(PRESETS):
            self.preset_idx = preset_idx
        if isinstance(ui_values, list) and len(ui_values) == len(PARAMS):
            try:
                self.ui_values = [round(clamp01(float(value)), 4) for value in ui_values]
            except (TypeError, ValueError):
                pass

    def _save_state(self) -> None:
        payload = {
            "preset_idx": self.preset_idx,
            "ui_values": self.ui_values,
        }
        self.state_file.write_text(json.dumps(payload, indent=2) + "\n")

    def shader_enabled(self) -> bool:
        for line in self.ghostty_config.read_text().splitlines():
            if line.startswith("custom-shader = ") and "crt-clean.glsl" in line:
                return True
        return False

    def set_shader_enabled(self, enabled: bool) -> None:
        old = "custom-shader = ~/.config/ghostty/shaders/crt-clean.glsl"
        new = "# custom-shader = ~/.config/ghostty/shaders/crt-clean.glsl"
        text = self.ghostty_config.read_text()
        if enabled:
            text = text.replace(new, old)
            self.status = "Shader enabled. Press Cmd+R in Ghostty."
        else:
            text = text.replace(old, new)
            self.status = "Shader disabled. Press Cmd+R in Ghostty."
        self.ghostty_config.write_text(text)

    def load_preset(self, idx: int) -> None:
        self.preset_idx = idx % len(PRESETS)
        self.ui_values = PRESETS[self.preset_idx].ui_values.copy()
        self.status = f"Loaded preset: {PRESETS[self.preset_idx].name}"
        self.dirty = True
        self._save_state()

    def nudge(self, idx: int, delta: float) -> None:
        value = clamp01(self.ui_values[idx] + delta)
        self.ui_values[idx] = round(value, 4)
        self.status = f"Updated {PARAMS[idx].label}. Press Cmd+R in Ghostty."
        self.dirty = True
        self._save_state()

    def shader_value(self, idx: int) -> float:
        spec = PARAMS[idx]
        curved = apply_curve(self.ui_values[idx], spec.curve)
        mapped = spec.shader_min + (spec.shader_max - spec.shader_min) * curved
        return round(mapped, 4)

    def write_shader(self, rows: int, cols: int) -> None:
        preset = PRESETS[self.preset_idx]
        tint_line = ""
        if preset.p31:
            tint_line = "#define PHOSPHOR_GREEN 1\n"
        elif preset.amber:
            tint_line = "#define PHOSPHOR_AMBER 1\n"

        mask_line = {
            "none": "",
            "shadow": "#define MASK_SHADOW 1\n",
            "grille": "#define MASK_GRILLE 1\n",
            "slot": "#define MASK_SLOT 1\n",
        }[preset.mask_mode]
        shader_values = [self.shader_value(i) for i in range(len(PARAMS))]
        header = (
            f"// crt-lab — generated\n"
            f"// Preset: {preset.name}\n"
            f"#define ROWS           {rows}\n"
            f"#define COLS           {cols}\n"
            + "".join(
                f"#define {spec.define:<15} {shader_values[idx]:.4f}\n"
                for idx, spec in enumerate(PARAMS)
            )
            + f"#define PI             3.14159265359\n"
            + mask_line
            + tint_line
            + "\n"
        )
        self.shader_out.write_text(header + self.template_body)

    def restore_pristine(self) -> None:
        shutil.copy2(self.shader_pristine, self.shader_out)
        self.status = "Restored pristine crt-clean.glsl. Press Cmd+R in Ghostty."
        self.dirty = False
        self._save_state()

    def bar(self, value: float, width: int = 16) -> str:
        filled = round(value * width)
        return "#" * filled + "-" * (width - filled)

    def init_colors(self) -> None:
        if not curses.has_colors():
            return
        curses.start_color()
        curses.use_default_colors()
        curses.init_pair(1, curses.COLOR_CYAN, -1)
        curses.init_pair(2, curses.COLOR_YELLOW, -1)
        curses.init_pair(3, curses.COLOR_GREEN, -1)
        curses.init_pair(4, curses.COLOR_BLACK, curses.COLOR_CYAN)
        curses.init_pair(5, curses.COLOR_MAGENTA, -1)
        curses.init_pair(6, curses.COLOR_RED, -1)

    def color(self, pair: int, fallback: int = 0) -> int:
        if curses.has_colors():
            return curses.color_pair(pair)
        return fallback

    def draw(self, stdscr: curses.window) -> None:
        stdscr.erase()
        rows, cols = stdscr.getmaxyx()
        preset = PRESETS[self.preset_idx]
        header = f"CRT Lab  {preset.name} [{self.preset_idx + 1}/{len(PRESETS)}]"
        if preset.p31:
            header += " [P31]"
        elif preset.amber:
            header += " [Amber]"
        if preset.mask_mode != "none":
            header += f" [{preset.mask_mode}]"
        header += " [shader on]" if self.shader_enabled() else " [shader off]"
        stdscr.addnstr(0, 0, header, cols - 1, self.color(1, curses.A_BOLD) | curses.A_BOLD)
        stdscr.addnstr(2, 0, "n/p preset  arrows move  [/] coarse  o on  x off  z reset  q quit", cols - 1, self.color(2))
        hint = "Change values, then press Cmd+R in Ghostty."
        spec = PARAMS[self.selected]
        if spec.readable_max is not None:
            hint += f"  Readable target: <= {spec.readable_max:.2f}"
        stdscr.addnstr(3, 0, hint, cols - 1, self.color(5))

        list_top = 5
        visible = max(1, rows - list_top - 2)
        offset = min(max(0, self.selected - visible + 1), max(0, len(PARAMS) - visible))
        for row, idx in enumerate(range(offset, min(len(PARAMS), offset + visible))):
            spec = PARAMS[idx]
            y = list_top + row
            prefix = "> " if idx == self.selected else "  "
            anim = " *" if spec.animated else ""
            line = (
                f"{prefix}{spec.label:<15} "
                f"{self.bar(self.ui_values[idx])}  "
                f"{self.ui_values[idx]:>4.2f}{anim}  "
                f"{spec.desc}"
            )
            if spec.readable_max is not None:
                line += f"  [safe<= {spec.readable_max:.2f}]"
            attr = self.color(4, curses.A_REVERSE) if idx == self.selected else self.color(3)
            stdscr.addnstr(y, 0, line, cols - 1, attr)

        status_attr = self.color(6) if "disabled" in self.status.lower() else self.color(3)
        stdscr.addnstr(rows - 1, 0, self.status, cols - 1, status_attr)
        stdscr.refresh()

    def run(self, stdscr: curses.window) -> None:
        self.init_colors()
        curses.curs_set(0)
        stdscr.keypad(True)
        while True:
            rows, cols = stdscr.getmaxyx()
            if (rows, cols) != self.last_dims:
                self.last_dims = (rows, cols)
                self.dirty = True
            if self.dirty:
                self.write_shader(max(rows, 24), max(cols, 80))
                self.dirty = False
            self.draw(stdscr)
            key = stdscr.getch()

            if key in (ord("q"), ord("Q")):
                return
            if key == curses.KEY_UP:
                self.selected = (self.selected - 1) % len(PARAMS)
            elif key == curses.KEY_DOWN:
                self.selected = (self.selected + 1) % len(PARAMS)
            elif key == curses.KEY_LEFT:
                self.nudge(self.selected, -PARAMS[self.selected].fine_step)
            elif key == curses.KEY_RIGHT:
                self.nudge(self.selected, PARAMS[self.selected].fine_step)
            elif key == ord("["):
                self.nudge(self.selected, -PARAMS[self.selected].coarse_step)
            elif key == ord("]"):
                self.nudge(self.selected, PARAMS[self.selected].coarse_step)
            elif key in (ord("n"), ord("N")):
                self.load_preset(self.preset_idx + 1)
            elif key in (ord("p"), ord("P")):
                self.load_preset(self.preset_idx - 1)
            elif key in (ord("o"), ord("O")):
                self.set_shader_enabled(True)
            elif key in (ord("x"), ord("X")):
                self.set_shader_enabled(False)
            elif key in (ord("z"), ord("Z")):
                self.restore_pristine()
            elif key in (ord("r"), ord("R")):
                self.status = "Use Cmd+R in Ghostty to reload."


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument("--preset", type=int, default=None)
    parser.add_argument("-h", "--help", action="store_true")
    args = parser.parse_args()
    if args.help:
        print("Usage: crt-lab [--preset N]")
        print("  arrows move  [/] coarse  n/p preset  o on  x off  z reset  q quit")
        raise SystemExit(0)
    return args


def main() -> None:
    args = parse_args()
    root = Path(__file__).resolve().parents[2]
    start_preset = 0 if args.preset is None else args.preset - 1
    app = CRTLAb(root, start_preset)
    if args.preset is not None:
        app.load_preset(start_preset)
    curses.wrapper(app.run)


if __name__ == "__main__":
    main()
