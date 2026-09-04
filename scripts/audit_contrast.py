#!/usr/bin/env python3
"""Auditoria WCAG 2.1 de contraste para pares críticos do design system."""

from __future__ import annotations

import re
import sys
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
APP_COLORS = ROOT / "app" / "lib" / "core" / "theme" / "app_colors.dart"

MIN_NORMAL = 4.5
MIN_LARGE = 3.0


@dataclass(frozen=True)
class ContrastPair:
    name: str
    foreground: str
    background: str
    min_ratio: float = MIN_NORMAL


# Pares críticos — foreground sobre background.
CRITICAL_PAIRS: list[ContrastPair] = [
    # Light
    ContrastPair("light onSurface/surface", "onSurface", "surface"),
    ContrastPair("light onSurfaceVariant/surface", "onSurfaceVariant", "surface"),
    ContrastPair(
        "light onSurfaceVariant/surfaceContainer",
        "onSurfaceVariant",
        "surfaceContainer",
    ),
    ContrastPair(
        "light onWarningContainer/warningContainer",
        "onWarningContainer",
        "warningContainer",
    ),
    ContrastPair(
        "light onInfoContainer/infoContainer",
        "onInfoContainer",
        "infoContainer",
    ),
    ContrastPair(
        "light onSearchHighlight/searchHighlight",
        "onSearchHighlight",
        "searchHighlight",
    ),
    ContrastPair("light primary/surface", "primary", "surface"),
    ContrastPair(
        "light revoked/surfaceContainerHigh",
        "revoked",
        "surfaceContainerHigh",
    ),
    ContrastPair("light muted/surface", "muted", "surface"),
    # Dark
    ContrastPair("dark onSurfaceDark/surfaceDark", "onSurfaceDark", "surfaceDark"),
    ContrastPair(
        "dark onSurfaceVariantDark/surfaceDark",
        "onSurfaceVariantDark",
        "surfaceDark",
    ),
    ContrastPair(
        "dark onSurfaceVariantDark/surfaceContainerDark",
        "onSurfaceVariantDark",
        "surfaceContainerDark",
    ),
    ContrastPair(
        "dark onWarningContainerDark/warningContainerDark",
        "onWarningContainerDark",
        "warningContainerDark",
    ),
    ContrastPair(
        "dark onInfoContainerDark/infoContainerDark",
        "onInfoContainerDark",
        "infoContainerDark",
    ),
    ContrastPair(
        "dark onSearchHighlightDark/searchHighlightDark",
        "onSearchHighlightDark",
        "searchHighlightDark",
    ),
    ContrastPair("dark primaryDark/surfaceDark", "primaryDark", "surfaceDark"),
    ContrastPair(
        "dark revokedDark/surfaceContainerHighDark",
        "revokedDark",
        "surfaceContainerHighDark",
    ),
    ContrastPair("dark mutedDark/surfaceDark", "mutedDark", "surfaceDark"),
]


def _linearize(channel: float) -> float:
    if channel <= 0.03928:
        return channel / 12.92
    return ((channel + 0.055) / 1.055) ** 2.4


def hex_to_rgb(hex_color: str) -> tuple[float, float, float]:
    value = hex_color.lstrip("#")
    r = int(value[0:2], 16) / 255
    g = int(value[2:4], 16) / 255
    b = int(value[4:6], 16) / 255
    return r, g, b


def relative_luminance(hex_color: str) -> float:
    r, g, b = hex_to_rgb(hex_color)
    return (
        0.2126 * _linearize(r)
        + 0.7152 * _linearize(g)
        + 0.0722 * _linearize(b)
    )


def contrast_ratio(foreground: str, background: str) -> float:
    l1 = relative_luminance(foreground)
    l2 = relative_luminance(background)
    lighter = max(l1, l2)
    darker = min(l1, l2)
    return (lighter + 0.05) / (darker + 0.05)


def parse_app_colors(path: Path) -> dict[str, str]:
    text = path.read_text(encoding="utf-8")
    colors: dict[str, str] = {}
    pattern = re.compile(
        r"static const (\w+) = Color\(0x([0-9A-Fa-f]{8})\);",
    )
    for match in pattern.finditer(text):
        name, argb = match.group(1), match.group(2)
        colors[name] = f"#{argb[2:].upper()}"
    return colors


def audit(colors: dict[str, str]) -> list[str]:
    failures: list[str] = []
    for pair in CRITICAL_PAIRS:
        fg = colors.get(pair.foreground)
        bg = colors.get(pair.background)
        if fg is None:
            failures.append(f"{pair.name}: cor '{pair.foreground}' não encontrada")
            continue
        if bg is None:
            failures.append(f"{pair.name}: cor '{pair.background}' não encontrada")
            continue
        ratio = contrast_ratio(fg, bg)
        if ratio < pair.min_ratio:
            failures.append(
                f"{pair.name}: {ratio:.2f}:1 < {pair.min_ratio}:1 "
                f"({fg} sobre {bg})"
            )
    return failures


def main() -> int:
    if not APP_COLORS.is_file():
        print(f"✗ Arquivo não encontrado: {APP_COLORS}", file=sys.stderr)
        return 1

    colors = parse_app_colors(APP_COLORS)
    failures = audit(colors)

    if failures:
        print("✗ Auditoria de contraste falhou:", file=sys.stderr)
        for failure in failures:
            print(f"  - {failure}", file=sys.stderr)
        return 1

    print(f"✓ {len(CRITICAL_PAIRS)} pares críticos passaram WCAG AA")
    return 0


if __name__ == "__main__":
    sys.exit(main())
