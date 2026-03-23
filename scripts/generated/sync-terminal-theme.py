#!/usr/bin/env python3
from __future__ import annotations

import argparse
import difflib
import os
import sys
import textwrap
from pathlib import Path


ROOT = Path(os.environ.get("DOTFILES_DIR", Path(__file__).resolve().parents[2]))
GHOSTTY_THEME = ROOT / "configs" / "ghostty" / "themes" / "current"


def parse_ghostty_theme(path: Path) -> dict:
    palette: dict[int, str] = {}
    values: dict[str, str] = {}

    for raw_line in path.read_text().splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        if "=" not in line:
            continue
        key, value = [part.strip() for part in line.split("=", 1)]
        if key == "palette":
            index_str, color = [part.strip() for part in value.split("=", 1)]
            palette[int(index_str)] = color
        else:
            values[key] = value

    missing = [idx for idx in range(16) if idx not in palette]
    if missing:
        raise ValueError(f"Missing palette indexes in {path}: {missing}")

    required = ["background", "foreground", "selection-background", "selection-foreground"]
    for key in required:
        if key not in values:
            raise ValueError(f"Missing required key in {path}: {key}")

    return {"palette": palette, **values}


def hex_to_rgb(color: str) -> tuple[int, int, int]:
    color = color.lstrip("#")
    return tuple(int(color[i : i + 2], 16) for i in (0, 2, 4))


def relative_luminance(color: str) -> float:
    def channel(value: int) -> float:
        srgb = value / 255
        return srgb / 12.92 if srgb <= 0.04045 else ((srgb + 0.055) / 1.055) ** 2.4

    r, g, b = hex_to_rgb(color)
    r_l, g_l, b_l = channel(r), channel(g), channel(b)
    return 0.2126 * r_l + 0.7152 * g_l + 0.0722 * b_l


def contrast_ratio(a: str, b: str) -> float:
    l1, l2 = sorted((relative_luminance(a), relative_luminance(b)))
    return (l2 + 0.05) / (l1 + 0.05)


def best_contrast(bg: str, candidates: list[str]) -> str:
    return max(candidates, key=lambda candidate: contrast_ratio(bg, candidate))


def theme_colors(theme: dict) -> dict[str, str]:
    palette = theme["palette"]
    bg = theme["background"]
    fg = theme["foreground"]
    select_bg = theme["selection-background"]
    select_fg = theme["selection-foreground"]

    soft_bg = palette[0] if palette[0].lower() != bg.lower() else select_bg
    muted = palette[8]

    accent_blue = palette[12]
    accent_yellow = palette[11]
    accent_green = palette[10]
    accent_cyan = palette[14]
    accent_magenta = palette[13]
    accent_red = palette[9]
    accent_orange = palette[1]

    return {
        "bg": bg,
        "fg": fg,
        "soft_bg": soft_bg,
        "surface": select_bg,
        "surface_fg": select_fg,
        "muted": muted,
        "blue": accent_blue,
        "yellow": accent_yellow,
        "green": accent_green,
        "cyan": accent_cyan,
        "magenta": accent_magenta,
        "red": accent_red,
        "orange": accent_orange,
        "accent_text_blue": best_contrast(accent_blue, [bg, fg]),
        "accent_text_yellow": best_contrast(accent_yellow, [bg, fg]),
        "accent_text_green": best_contrast(accent_green, [bg, fg]),
        "accent_text_cyan": best_contrast(accent_cyan, [bg, fg]),
        "accent_text_magenta": best_contrast(accent_magenta, [bg, fg]),
        "accent_text_red": best_contrast(accent_red, [bg, fg]),
    }


def replace_block(text: str, start_marker: str, end_marker: str, replacement: str) -> str:
    start = text.find(start_marker)
    end = text.find(end_marker)
    if start == -1 or end == -1:
        raise ValueError(f"Missing marker pair: {start_marker} / {end_marker}")
    if end < start:
        raise ValueError(f"End marker before start marker: {start_marker}")

    start_content = start + len(start_marker)
    indent = start_marker.splitlines()[-1].split("//", 1)[0]
    replacement = textwrap.dedent(replacement).strip("\n")
    replacement = "\n".join(
        f"{indent}{line}" if line else "" for line in replacement.splitlines()
    )
    replacement += "\n"
    return text[:start_content] + replacement + text[end:]


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


def zellij_current_theme_block(c: dict[str, str]) -> str:
    return f"""// Managed by `dotfiles theme` and `dotfiles regen`.
// Source palette: configs/ghostty/themes/current

themes {{
    current {{
        bg "{c["bg"]}"
        fg "{c["fg"]}"

        black "{c["bg"]}"
        red "{c["red"]}"
        green "{c["green"]}"
        yellow "{c["yellow"]}"
        blue "{c["blue"]}"
        magenta "{c["magenta"]}"
        cyan "{c["cyan"]}"
        white "{c["fg"]}"
        orange "{c["orange"]}"

        text "{c["fg"]}"
        subtext1 "{c["surface_fg"]}"
        subtext0 "{c["cyan"]}"
        overlay2 "{c["muted"]}"
        overlay1 "{c["muted"]}"
        overlay0 "{c["surface"]}"
        surface2 "{c["muted"]}"
        surface1 "{c["surface"]}"
        surface0 "{c["soft_bg"]}"
        base "{c["bg"]}"
        mantle "{c["bg"]}"
        crust "{c["bg"]}"

        ribbon_unselected {{
            base "{c["fg"]}"
            background "{c["soft_bg"]}"
            emphasis_0 "{c["blue"]}"
            emphasis_1 "{c["yellow"]}"
            emphasis_2 "{c["cyan"]}"
            emphasis_3 "{c["magenta"]}"
        }}

        text_unselected {{
            base "{c["fg"]}"
            background "{c["bg"]}"
            emphasis_0 "{c["blue"]}"
            emphasis_1 "{c["yellow"]}"
            emphasis_2 "{c["cyan"]}"
            emphasis_3 "{c["magenta"]}"
        }}

        text_selected {{
            base "{best_contrast(c["fg"], [c["bg"], c["surface"]])}"
            background "{c["fg"]}"
            emphasis_0 "{c["blue"]}"
            emphasis_1 "{c["yellow"]}"
            emphasis_2 "{c["cyan"]}"
            emphasis_3 "{c["magenta"]}"
        }}

        ribbon_selected {{
            base "{c["accent_text_blue"]}"
            background "{c["blue"]}"
            emphasis_0 "{c["accent_text_blue"]}"
            emphasis_1 "{c["accent_text_blue"]}"
            emphasis_2 "{c["accent_text_blue"]}"
            emphasis_3 "{c["accent_text_blue"]}"
        }}

        frame_unselected {{
            base "{c["muted"]}"
            background "{c["bg"]}"
            emphasis_0 "{c["muted"]}"
            emphasis_1 "{c["muted"]}"
            emphasis_2 "{c["muted"]}"
            emphasis_3 "{c["muted"]}"
        }}

        frame_selected {{
            base "{c["blue"]}"
            background "{c["bg"]}"
            emphasis_0 "{c["blue"]}"
            emphasis_1 "{c["blue"]}"
            emphasis_2 "{c["blue"]}"
            emphasis_3 "{c["blue"]}"
        }}

        frame_highlight {{
            base "{c["yellow"]}"
            background "{c["bg"]}"
            emphasis_0 "{c["yellow"]}"
            emphasis_1 "{c["yellow"]}"
            emphasis_2 "{c["yellow"]}"
            emphasis_3 "{c["yellow"]}"
        }}
    }}
}}"""


def generated_blocks(c: dict[str, str]) -> dict[str, str]:
    return {
        "config_vertical_tabs": f"""
        format "#[fg={c["blue"]}]{{index}} {{name}}"
        format_active "#[fg={c["yellow"]}]{{index}} {{name}}"
        """.strip(),
        "default_top": f"""
            format_left   "#[bg={c["soft_bg"]},fg={c["cyan"]}]\\u{{e0b6}}#[bg={c["cyan"]},fg={c["accent_text_cyan"]}] {{session}} #[bg={c["soft_bg"]},fg={c["cyan"]}]\\u{{e0b4}}"
            format_center "{{notifications}}"
            format_right  "#[bg={c["soft_bg"]},fg={c["red"]}]\\u{{e0b6}}#[bg={c["red"]},fg={c["accent_text_red"]}]\\u{{f00ed}}#[bg={c["muted"]},fg={c["red"]}]\\u{{e0b4}} {{datetime}}#[bg={c["soft_bg"]},fg={c["muted"]}]\\u{{e0b4}}"
            format_space  "#[bg={c["soft_bg"]}]"
            format_hide_on_overlength "true"
            format_precedence "lrc"

            notification_format_unread           "#[bg={c["yellow"]},fg={c["accent_text_yellow"]},blink] \\u{{f0f3}} #[bg={c["muted"]},fg={c["yellow"]}]\\u{{e0b4}} {{message}}#[bg={c["soft_bg"]},fg={c["muted"]}]\\u{{e0b4}}"
            notification_format_no_notifications ""
            notification_show_interval           "10"

            mode_normal        "#[bg={c["blue"]},fg={c["accent_text_blue"]}] NORMAL#[bg={c["soft_bg"]},fg={c["blue"]}]\\u{{e0b4}}"
            mode_locked        "#[bg={c["red"]},fg={c["accent_text_red"]}] LOCKED#[bg={c["soft_bg"]},fg={c["red"]}]\\u{{e0b4}}"
            mode_pane          "#[bg={c["cyan"]},fg={c["accent_text_cyan"]}] PANE#[bg={c["soft_bg"]},fg={c["cyan"]}]\\u{{e0b4}}"
            mode_tab           "#[bg={c["cyan"]},fg={c["accent_text_cyan"]}] TAB#[bg={c["soft_bg"]},fg={c["cyan"]}]\\u{{e0b4}}"
            mode_scroll        "#[bg={c["cyan"]},fg={c["accent_text_cyan"]}] SCROLL#[bg={c["soft_bg"]},fg={c["cyan"]}]\\u{{e0b4}}"
            mode_search        "#[bg={c["cyan"]},fg={c["accent_text_cyan"]}] SEARCH#[bg={c["soft_bg"]},fg={c["cyan"]}]\\u{{e0b4}}"
            mode_enter_search  "#[bg={c["cyan"]},fg={c["accent_text_cyan"]}] ENT-SEARCH#[bg={c["soft_bg"]},fg={c["cyan"]}]\\u{{e0b4}}"
            mode_resize        "#[bg={c["yellow"]},fg={c["accent_text_yellow"]}] RESIZE#[bg={c["soft_bg"]},fg={c["yellow"]}]\\u{{e0b4}}"
            mode_rename_tab    "#[bg={c["yellow"]},fg={c["accent_text_yellow"]}] RENAME-TAB#[bg={c["soft_bg"]},fg={c["yellow"]}]\\u{{e0b4}}"
            mode_rename_pane   "#[bg={c["yellow"]},fg={c["accent_text_yellow"]}] RENAME-PANE#[bg={c["soft_bg"]},fg={c["yellow"]}]\\u{{e0b4}}"
            mode_move          "#[bg={c["yellow"]},fg={c["accent_text_yellow"]}] MOVE#[bg={c["soft_bg"]},fg={c["yellow"]}]\\u{{e0b4}}"
            mode_session       "#[bg={c["magenta"]},fg={c["accent_text_magenta"]}] SESSION#[bg={c["soft_bg"]},fg={c["magenta"]}]\\u{{e0b4}}"
            mode_prompt        "#[bg={c["magenta"]},fg={c["accent_text_magenta"]}] PROMPT#[bg={c["soft_bg"]},fg={c["magenta"]}]\\u{{e0b4}}"
        """.strip(),
        "default_vertical_tabs": f"""
                format        " #[fg={c["blue"]}]\\u{{e0b6}}#[bg={c["blue"]},fg={c["accent_text_blue"]}]{{index}}#[bg=none,fg={c["blue"]}]\\u{{e0b4}} {{=12:name}}"
                format_active " #[fg={c["yellow"]}]\\u{{e0b6}}#[bg={c["yellow"]},fg={c["accent_text_yellow"]}]{{index}}#[bg=none,fg={c["yellow"]}]\\u{{e0b4}} {{=12:name}}"
        """.strip(),
        "default_bottom": f"""
            format_space  "#[bg={c["soft_bg"]}]"

            mode_normal        "[bg={c["surface"]},fg={c["blue"]}]\\u{{e0b6}}#[bg={c["blue"]},fg={c["accent_text_blue"]}]NORMAL#[bg={c["soft_bg"]},fg={c["blue"]}]\\u{{e0b4}}"
            mode_locked        "[bg={c["surface"]},fg={c["red"]}]\\u{{e0b6}}#[bg={c["red"]},fg={c["accent_text_red"]}]LOCKED#[bg={c["soft_bg"]},fg={c["red"]}]\\u{{e0b4}}"
            mode_pane          "[bg={c["surface"]},fg={c["cyan"]}]\\u{{e0b6}}#[bg={c["cyan"]},fg={c["accent_text_cyan"]}]PANE#[bg={c["soft_bg"]},fg={c["cyan"]}]\\u{{e0b4}}"
            mode_tab           "[bg={c["surface"]},fg={c["cyan"]}]\\u{{e0b6}}#[bg={c["cyan"]},fg={c["accent_text_cyan"]}]TAB#[bg={c["soft_bg"]},fg={c["cyan"]}]\\u{{e0b4}}"
            mode_scroll        "[bg={c["surface"]},fg={c["cyan"]}]\\u{{e0b6}}#[bg={c["cyan"]},fg={c["accent_text_cyan"]}]SCROLL#[bg={c["soft_bg"]},fg={c["cyan"]}]\\u{{e0b4}}"
            mode_search        "[bg={c["surface"]},fg={c["cyan"]}]\\u{{e0b6}}#[bg={c["cyan"]},fg={c["accent_text_cyan"]}]SEARCH#[bg={c["soft_bg"]},fg={c["cyan"]}]\\u{{e0b4}}"
            mode_enter_search  "[bg={c["surface"]},fg={c["cyan"]}]\\u{{e0b6}}#[bg={c["cyan"]},fg={c["accent_text_cyan"]}]ENT-SEARCH#[bg={c["soft_bg"]},fg={c["cyan"]}]\\u{{e0b4}}"
            mode_resize        "[bg={c["surface"]},fg={c["yellow"]}]\\u{{e0b6}}#[bg={c["yellow"]},fg={c["accent_text_yellow"]}]RESIZE#[bg={c["soft_bg"]},fg={c["yellow"]}]\\u{{e0b4}}"
            mode_rename_tab    "[bg={c["surface"]},fg={c["yellow"]}]\\u{{e0b6}}#[bg={c["yellow"]},fg={c["accent_text_yellow"]}]RENAME-TAB#[bg={c["soft_bg"]},fg={c["yellow"]}]\\u{{e0b4}}"
            mode_rename_pane   "[bg={c["surface"]},fg={c["yellow"]}]\\u{{e0b6}}#[bg={c["yellow"]},fg={c["accent_text_yellow"]}]RENAME-PANE#[bg={c["soft_bg"]},fg={c["yellow"]}]\\u{{e0b4}}"
            mode_move          "[bg={c["surface"]},fg={c["yellow"]}]\\u{{e0b6}}#[bg={c["yellow"]},fg={c["accent_text_yellow"]}]MOVE#[bg={c["soft_bg"]},fg={c["yellow"]}]\\u{{e0b4}}"
            mode_session       "[bg={c["surface"]},fg={c["magenta"]}]\\u{{e0b6}}#[bg={c["magenta"]},fg={c["accent_text_magenta"]}]SESSION#[bg={c["soft_bg"]},fg={c["magenta"]}]\\u{{e0b4}}"
            mode_prompt        "[bg={c["surface"]},fg={c["magenta"]}]\\u{{e0b6}}#[bg={c["magenta"]},fg={c["accent_text_magenta"]}]PROMPT#[bg={c["soft_bg"]},fg={c["magenta"]}]\\u{{e0b4}}"
        """.strip(),
        "classic_top": f"""
                // Format configuration
                format_left   " #[bg={c["soft_bg"]}] {{mode}}#[bg={c["soft_bg"]}] {{tabs}}"
                format_center "{{notifications}}"
                format_right  "#[bg={c["soft_bg"]},fg={c["cyan"]}]\\u{{e0b6}}#[fg={c["accent_text_cyan"]},bg={c["cyan"]}]\\u{{f0219}} #[bg={c["muted"]},fg={c["cyan"]}]\\u{{e0b4}} {{command_kube}}#[bg={c["soft_bg"]},fg={c["muted"]}]\\u{{e0b4}}#[bg={c["soft_bg"]},fg={c["red"]}]\\u{{e0b6}}#[bg={c["red"]},fg={c["accent_text_red"]}]\\u{{f00ed}} #[bg={c["muted"]},fg={c["red"]}]\\u{{e0b4}} {{datetime}}#[bg={c["soft_bg"]},fg={c["muted"]}]\\u{{e0b4}}"
                format_space  "#[bg={c["soft_bg"]}]"
                format_hide_on_overlength "true"
                format_precedence "lrc"

                // Notifications
                notification_format_unread           "#[bg={c["yellow"]},fg={c["accent_text_yellow"]},blink] \\u{{f0f3}} #[bg={c["muted"]},fg={c["yellow"]}]\\u{{e0b4}} {{message}}#[bg={c["soft_bg"]},fg={c["muted"]}]\\u{{e0b4}}"
                notification_format_no_notifications ""
                notification_show_interval           "10"


                // Tab formatting
                tab_normal              "#[bg={c["soft_bg"]},fg={c["blue"]}]\\u{{e0b6}}#[bg={c["blue"]},fg={c["accent_text_blue"]}]{{index}}#[bg={c["muted"]},fg={c["blue"]}]\\u{{e0b4}} {{name}}{{floating_indicator}}#[bg={c["soft_bg"]},fg={c["muted"]}]\\u{{e0b4}}"
                tab_normal_fullscreen   "#[bg={c["soft_bg"]},fg={c["blue"]}]\\u{{e0b6}}#[bg={c["blue"]},fg={c["accent_text_blue"]}]{{index}}#[bg={c["muted"]},fg={c["blue"]}]\\u{{e0b4}} {{name}}{{fullscreen_indicator}}#[bg={c["soft_bg"]},fg={c["muted"]}]\\u{{e0b4}}"
                tab_normal_sync         "#[bg={c["soft_bg"]},fg={c["blue"]}]\\u{{e0b6}}#[bg={c["blue"]},fg={c["accent_text_blue"]}]{{index}}#[bg={c["muted"]},fg={c["blue"]}]\\u{{e0b4}} {{name}}{{sync_indicator}}#[bg={c["soft_bg"]},fg={c["muted"]}]\\u{{e0b4}}"
                tab_active              "#[bg={c["soft_bg"]},fg={c["yellow"]}]\\u{{e0b6}}#[bg={c["yellow"]},fg={c["accent_text_yellow"]}]{{index}}#[bg={c["muted"]},fg={c["yellow"]}]\\u{{e0b4}} {{name}}{{floating_indicator}}#[bg={c["soft_bg"]},fg={c["muted"]}]\\u{{e0b4}}"
                tab_active_fullscreen   "#[bg={c["soft_bg"]},fg={c["yellow"]}]\\u{{e0b6}}#[bg={c["yellow"]},fg={c["accent_text_yellow"]}]{{index}}#[bg={c["muted"]},fg={c["yellow"]}]\\u{{e0b4}} {{name}}{{fullscreen_indicator}}#[bg={c["soft_bg"]},fg={c["muted"]}]\\u{{e0b4}}"
                tab_active_sync         "#[bg={c["soft_bg"]},fg={c["yellow"]}]\\u{{e0b6}}#[bg={c["yellow"]},fg={c["accent_text_yellow"]}]{{index}}#[bg={c["muted"]},fg={c["yellow"]}]\\u{{e0b4}} {{name}}{{sync_indicator}}#[bg={c["soft_bg"]},fg={c["muted"]}]\\u{{e0b4}}"
                tab_separator           "#[bg={c["soft_bg"]}] "

                tab_sync_indicator       " \\u{{f021}}"
                tab_fullscreen_indicator " \\u{{f0293}}"
                tab_floating_indicator   " \\u{{f0e59}}"

                tab_display_count        "20"
                tab_truncate_start_format "#[fg={c["muted"]}] \\u{{e0b6}}+{{count}}\\u{{e0b4}}"
                tab_truncate_end_format  "#[fg={c["muted"]}] +{{count}}\\u{{e0b6}}"
        """.strip(),
        "classic_bottom": f"""
                // Mode indicators
                mode_normal        "#[bg={c["blue"]},fg={c["accent_text_blue"]}] \\u{{2764}} NORMAL#[bg={c["soft_bg"]},fg={c["blue"]}]\\u{{e0b4}}"
                mode_tmux          "#[bg={c["magenta"]},fg={c["accent_text_magenta"]}] \\u{{2764}} TMUX#[bg={c["soft_bg"]},fg={c["magenta"]}]\\u{{e0b4}}"
                mode_locked        "#[bg={c["red"]},fg={c["accent_text_red"]}] \\u{{2764}} LOCKED#[bg={c["soft_bg"]},fg={c["red"]}]\\u{{e0b4}}#[fg={c["muted"]}]"
                mode_pane          "#[bg={c["cyan"]},fg={c["accent_text_cyan"]}] \\u{{2764}} PANE#[bg={c["soft_bg"]},fg={c["cyan"]}]\\u{{e0b4}}"
                mode_tab           "#[bg={c["cyan"]},fg={c["accent_text_cyan"]}] \\u{{2764}} TAB#[bg={c["soft_bg"]},fg={c["cyan"]}]\\u{{e0b4}}"
                mode_scroll        "#[bg={c["cyan"]},fg={c["accent_text_cyan"]}] \\u{{2764}} SCROLL#[bg={c["soft_bg"]},fg={c["cyan"]}]\\u{{e0b4}}"
                mode_enter_search  "#[bg={c["cyan"]},fg={c["accent_text_cyan"]}] \\u{{2764}} ENT-SEARCH#[bg={c["soft_bg"]},fg={c["cyan"]}]\\u{{e0b4}}"
                mode_search        "#[bg={c["cyan"]},fg={c["accent_text_cyan"]}] \\u{{2764}} SEARCH#[bg={c["soft_bg"]},fg={c["cyan"]}]\\u{{e0b4}}"
                mode_resize        "#[bg={c["yellow"]},fg={c["accent_text_yellow"]}] \\u{{2764}} RESIZE#[bg={c["soft_bg"]},fg={c["yellow"]}]\\u{{e0b4}}"
                mode_rename_tab    "#[bg={c["yellow"]},fg={c["accent_text_yellow"]}] \\u{{2764}} RENAME-TAB#[bg={c["soft_bg"]},fg={c["yellow"]}]\\u{{e0b4}}"
                mode_rename_pane   "#[bg={c["yellow"]},fg={c["accent_text_yellow"]}] \\u{{2764}} RENAME-PANE#[bg={c["soft_bg"]},fg={c["yellow"]}]\\u{{e0b4}}"
                mode_move          "#[bg={c["yellow"]},fg={c["accent_text_yellow"]}] \\u{{2764}} MOVE#[bg={c["soft_bg"]},fg={c["yellow"]}]\\u{{e0b4}}"
                mode_session       "#[bg={c["magenta"]},fg={c["accent_text_magenta"]}] \\u{{2764}} SESSION#[bg={c["soft_bg"]},fg={c["magenta"]}]\\u{{e0b4}}"
                mode_prompt        "#[bg={c["magenta"]},fg={c["accent_text_magenta"]}] \\u{{2764}} PROMPT#[bg={c["soft_bg"]},fg={c["magenta"]}]\\u{{e0b4}}"

                format_left   "#[bg={c["soft_bg"]},fg={c["cyan"]}]\\u{{e0b6}}#[bg={c["cyan"]},fg={c["accent_text_cyan"]}] {{session}} #[bg={c["soft_bg"]},fg={c["cyan"]}]\\u{{e0b4}} {{mode}}"
                format_center ""
                format_right  "{{pipe_zjstatus_hints}}"
                format_hide_on_overlength "true"
                format_precedence "lrc"

                format_space  "#[bg={c["soft_bg"]}]"
        """.strip(),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="Report drift without writing")
    args = parser.parse_args()

    theme = parse_ghostty_theme(GHOSTTY_THEME)
    colors = theme_colors(theme)
    blocks = generated_blocks(colors)

    changed = False

    current_theme_path = ROOT / "configs" / "zellij" / "themes" / "current.kdl"
    current_theme_text = zellij_current_theme_block(colors)
    if current_theme_path.read_text() != current_theme_text:
        if args.check:
            diff = difflib.unified_diff(
                current_theme_path.read_text().splitlines(True),
                current_theme_text.splitlines(True),
                fromfile=str(current_theme_path),
                tofile=str(current_theme_path),
            )
            sys.stdout.writelines(diff)
        else:
            current_theme_path.write_text(current_theme_text)
        changed = True

    changed |= update_file(
        ROOT / "configs" / "zellij" / "config.kdl",
        [
            (
                "        // BEGIN GENERATED: zellij-vertical-tabs-plugin-theme\n",
                "        // END GENERATED: zellij-vertical-tabs-plugin-theme",
                blocks["config_vertical_tabs"],
            )
        ],
        args.check,
    )

    changed |= update_file(
        ROOT / "configs" / "zellij" / "layouts" / "default.kdl",
        [
            (
                "            // BEGIN GENERATED: zellij-default-top-theme\n",
                "            // END GENERATED: zellij-default-top-theme",
                blocks["default_top"],
            ),
            (
                "                // BEGIN GENERATED: zellij-default-vertical-tabs-theme\n",
                "                // END GENERATED: zellij-default-vertical-tabs-theme",
                blocks["default_vertical_tabs"],
            ),
            (
                "            // BEGIN GENERATED: zellij-default-bottom-theme\n",
                "            // END GENERATED: zellij-default-bottom-theme",
                blocks["default_bottom"],
            ),
        ],
        args.check,
    )

    changed |= update_file(
        ROOT / "configs" / "zellij" / "layouts" / "classic.kdl",
        [
            (
                "                // BEGIN GENERATED: zellij-classic-top-theme\n",
                "                // END GENERATED: zellij-classic-top-theme",
                blocks["classic_top"],
            ),
            (
                "                // BEGIN GENERATED: zellij-classic-bottom-theme\n",
                "                // END GENERATED: zellij-classic-bottom-theme",
                blocks["classic_bottom"],
            ),
        ],
        args.check,
    )

    return 1 if args.check and changed else 0


if __name__ == "__main__":
    raise SystemExit(main())
