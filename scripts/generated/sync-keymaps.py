#!/usr/bin/env python3
from __future__ import annotations

import argparse
import difflib
import os
import sys
from pathlib import Path

try:
    import tomllib
except ModuleNotFoundError:  # pragma: no cover
    print("Python 3.11+ is required for tomllib", file=sys.stderr)
    sys.exit(1)


ROOT = Path(os.environ.get("DOTFILES_DIR", Path(__file__).resolve().parents[2]))
KEYMAPS_FILE = ROOT / "configs" / "keymaps.toml"


def load_keymaps() -> dict:
    with KEYMAPS_FILE.open("rb") as f:
        return tomllib.load(f)


def replace_block(text: str, start_marker: str, end_marker: str, replacement: str) -> str:
    start = text.find(start_marker)
    end = text.find(end_marker)
    if start == -1 or end == -1:
        raise ValueError(f"Missing marker pair: {start_marker} / {end_marker}")
    if text.find(start_marker, start + len(start_marker)) != -1:
        raise ValueError(f"Duplicate start marker: {start_marker}")
    if text.find(end_marker, end + len(end_marker)) != -1:
        raise ValueError(f"Duplicate end marker: {end_marker}")
    if end < start:
        raise ValueError(f"End marker before start marker: {start_marker}")

    start_content = start + len(start_marker)
    if not replacement.endswith("\n"):
        replacement += "\n"
    return text[:start_content] + replacement + text[end:]  # keep end marker intact


def update_file(path: Path, replacements: list[tuple[str, str, str]], check: bool) -> bool:
    original = path.read_text()
    updated = original
    for start_marker, end_marker, replacement in replacements:
        updated = replace_block(updated, start_marker, end_marker, replacement)

    if updated == original:
        return False

    if check:
        diff = difflib.unified_diff(
            original.splitlines(True),
            updated.splitlines(True),
            fromfile=str(path),
            tofile=str(path),
        )
        sys.stdout.writelines(diff)
    else:
        tmp = path.with_suffix(path.suffix + ".tmp")
        tmp.write_text(updated)
        tmp.replace(path)
    return True


def ghostty_block(cfg: dict) -> str:
    nav = cfg["ghostty"]["text_navigation"]
    misc = cfg["ghostty"]["misc"]
    return "\n".join(
        [
            "# Source of truth: ~/.dotfiles/configs/keymaps.toml",
            "# Line navigation",
            f'keybind = {nav["line_start"]}=text:\\x01',
            f'keybind = {nav["line_end"]}=text:\\x05',
            "",
            "# Word navigation",
            f'keybind = {nav["word_back"]}=esc:b',
            f'keybind = {nav["word_forward"]}=esc:f',
            "",
            "# Shift+Enter sends escaped return",
            "keybind = shift+enter=text:\\x1b\\r",
            "",
            "# Reload config",
            f'keybind = {misc["reload_config"]}=reload_config',
            "",
            "# Always handle copy/paste at the terminal level (prevents passthrough to apps)",
            f'keybind = {misc["copy"]}=copy_to_clipboard',
            f'keybind = {misc["paste"]}=paste_from_clipboard',
        ]
    )


def hammerspoon_key_label(chord: str) -> str:
    symbol_map = {
        "left": "←",
        "right": "→",
        "up": "↑",
        "down": "↓",
    }
    return "  ".join(symbol_map.get(part, part) for part in chord.split("+"))


def hammerspoon_ghostty_block(cfg: dict) -> str:
    nav = cfg["ghostty"]["text_navigation"]
    return "\n".join(
        [
            f'\t\t\t\t\t{{ "{hammerspoon_key_label(nav["word_back"])} / {hammerspoon_key_label(nav["word_forward"])}", "word back / forward" }},',
            f'\t\t\t\t\t{{ "{hammerspoon_key_label(nav["line_start"])} / {hammerspoon_key_label(nav["line_end"])}", "line start / end" }},',
        ]
    )


def zellij_locked_block(cfg: dict) -> str:
    pane = cfg["zellij"]["direct_pane_navigation"]
    tab = cfg["zellij"]["direct_tab_navigation"]

    def zellij_key(chord: str) -> str:
        parts = chord.split("+")
        rendered = []
        for part in parts:
            if part == "ctrl":
                rendered.append("Ctrl")
            elif part == "alt":
                rendered.append("Alt")
            elif part == "shift":
                rendered.append("Shift")
            elif part == "cmd":
                rendered.append("Super")
            else:
                rendered.append(part)
        return " ".join(rendered)

    return "\n".join(
        [
            '        bind "Ctrl space" { SwitchToMode "normal"; }',
            f'        bind "{zellij_key(pane["left"])}" {{ MoveFocus "left"; }}',
            f'        bind "{zellij_key(pane["down"])}" {{ MoveFocus "down"; }}',
            f'        bind "{zellij_key(pane["up"])}" {{ MoveFocus "up"; }}',
            f'        bind "{zellij_key(pane["right"])}" {{ MoveFocus "right"; }}',
            f'        bind "{zellij_key(tab["next"])}" {{ GoToNextTab; }}',
            f'        bind "{zellij_key(tab["previous"])}" {{ GoToPreviousTab; }}',
        ]
    )


def hammerspoon_zellij_block(cfg: dict) -> str:
    pane = cfg["zellij"]["direct_pane_navigation"]
    tab = cfg["zellij"]["direct_tab_navigation"]
    modes = cfg["zellij"]["modes"]
    return "\n".join(
        [
            f'\t\t\t\t\t{{ "{hammerspoon_key_label(pane["left"])} / {hammerspoon_key_label(pane["down"])} / {hammerspoon_key_label(pane["up"])} / {hammerspoon_key_label(pane["right"])}", "focus pane ←↓↑→" }},',
            f'\t\t\t\t\t{{ "{hammerspoon_key_label(tab["previous"])} / {hammerspoon_key_label(tab["next"])}", "prev / next tab" }},',
            f'\t\t\t\t\t{{ "{hammerspoon_key_label(modes["lock"])}", "→ normal mode" }},',
        ]
    )


def zellij_hints_block(cfg: dict) -> str:
    pane = cfg["zellij"]["direct_pane_navigation"]
    tab = cfg["zellij"]["direct_tab_navigation"]
    return "\n".join(
        [
            f'        "focus next tab" "{tab["next"].replace("+", " + ")}"',
            f'        "focus previous tab" "{tab["previous"].replace("+", " + ")}"',
            f'        "focus pane down" "{pane["down"].replace("+", " + ")}"',
            f'        "focus pane left" "{pane["left"].replace("+", " + ")}"',
            f'        "focus pane right" "{pane["right"].replace("+", " + ")}"',
            f'        "focus pane up" "{pane["up"].replace("+", " + ")}"',
        ]
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="Report drift without writing")
    args = parser.parse_args()

    cfg = load_keymaps()
    changed = False

    changed |= update_file(
        ROOT / "configs" / "ghostty" / "config",
        [
            (
                "# BEGIN GENERATED: keymaps\n",
                "# END GENERATED: keymaps",
                ghostty_block(cfg),
            )
        ],
        args.check,
    )

    changed |= update_file(
        ROOT / "configs" / "zellij" / "config.kdl",
        [
            (
                "    locked {\n        // BEGIN GENERATED: zellij-locked-navigation\n",
                "        // END GENERATED: zellij-locked-navigation",
                zellij_locked_block(cfg),
            ),
            (
                '        "increase size" "+"\n        // BEGIN GENERATED: zellij-hints-navigation\n',
                "        // END GENERATED: zellij-hints-navigation",
                zellij_hints_block(cfg),
            ),
        ],
        args.check,
    )

    changed |= update_file(
        ROOT / "configs" / "hammerspoon" / "navigation-guide.lua",
        [
            (
                "\t\t\t\t\t-- BEGIN GENERATED: hammerspoon-ghostty-navigation\n",
                "\t\t\t\t\t-- END GENERATED: hammerspoon-ghostty-navigation",
                hammerspoon_ghostty_block(cfg),
            ),
            (
                "\t\t\t\t\t-- BEGIN GENERATED: hammerspoon-zellij-direct-navigation\n",
                "\t\t\t\t\t-- END GENERATED: hammerspoon-zellij-direct-navigation",
                hammerspoon_zellij_block(cfg),
            ),
        ],
        args.check,
    )

    return 1 if args.check and changed else 0


if __name__ == "__main__":
    raise SystemExit(main())
