#!/usr/bin/env python3
"""Exporta assets de marca para app e Play Store (fallback com Pillow).

Para assets de produção, prefira geração por IA + scripts/postprocess_branding.py
(ver docs/store/README.md). Este script desenha PNGs programaticamente — qualidade
inferior, útil só para prototipagem rápida.

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BRANDING_DIR = ROOT / "app" / "assets" / "branding"
STORE_DIR = ROOT / "docs" / "store"

PRIMARY = (15, 92, 78)  # #0F5C4E
WHITE = (255, 255, 255)
SURFACE = (250, 251, 252)  # #FAFBFC
ON_SURFACE = (26, 28, 30)  # #1A1C1E
ON_SURFACE_VARIANT = (92, 102, 112)  # #5C6670


def _load_font(size: int, bold: bool = True):
    from PIL import ImageFont

    candidates = [
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
        "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/Library/Fonts/Arial Bold.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf",
    ]
    if not bold:
        candidates = [
            "/System/Library/Fonts/Supplemental/Arial.ttf",
            "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
            "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf",
        ] + candidates

    for path in candidates:
        if Path(path).exists():
            return ImageFont.truetype(path, size)

    return ImageFont.load_default()


def _draw_mark(
    draw,
    cx: int,
    cy: int,
    nr_size: int,
    line_width: int,
    line_lengths: tuple[int, int, int],
    line_gap: int,
    color=WHITE,
    line_opacity: int = 153,
):
    from PIL import ImageColor, ImageDraw

    font = _load_font(nr_size, bold=True)
    text = "NR"
    bbox = draw.textbbox((0, 0), text, font=font)
    text_w = bbox[2] - bbox[0]
    text_h = bbox[3] - bbox[1]
    text_x = cx - text_w // 2
    text_y = cy - text_h // 2 - int(nr_size * 0.15)
    draw.text((text_x, text_y), text, fill=color, font=font)

    line_y = text_y + text_h + int(nr_size * 0.12)
    line_color = (*color[:3], line_opacity) if len(color) == 3 else color
    overlay = ImageDraw.Draw(draw._image, "RGBA")
    for length in line_lengths:
        x0 = cx - length // 2
        x1 = cx + length // 2
        overlay.line((x0, line_y, x1, line_y), fill=line_color, width=line_width)
        line_y += line_gap


def _rounded_rect(draw, xy, radius, fill):
    draw.rounded_rectangle(xy, radius=radius, fill=fill)


def generate_app_icon(path: Path, size: int) -> None:
    from PIL import Image, ImageDraw

    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    radius = max(12, size // 21)
    _rounded_rect(draw, (0, 0, size, size), radius, PRIMARY)

    scale = size / 1024
    _draw_mark(
        draw,
        size // 2,
        int(size * 0.46),
        int(240 * scale),
        max(2, int(28 * scale)),
        (int(360 * scale), int(280 * scale), int(200 * scale)),
        max(4, int(62 * scale)),
    )
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path, "PNG")


def generate_foreground(path: Path, size: int) -> None:
    from PIL import Image, ImageDraw

    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    scale = size / 1024
    _draw_mark(
        draw,
        size // 2,
        int(size * 0.46),
        int(200 * scale),
        max(2, int(24 * scale)),
        (int(320 * scale), int(260 * scale), int(200 * scale)),
        max(4, int(52 * scale)),
    )
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path, "PNG")


def generate_splash_mark(path: Path, size: int) -> None:
    from PIL import Image, ImageDraw

    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    scale = size / 512
    _draw_mark(
        draw,
        size // 2,
        int(size * 0.42),
        int(120 * scale),
        max(2, int(14 * scale)),
        (int(180 * scale), int(140 * scale), int(100 * scale)),
        max(3, int(31 * scale)),
    )
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path, "PNG")


def generate_feature_graphic(path: Path) -> None:
    from PIL import Image, ImageDraw

    width, height = 1024, 500
    img = Image.new("RGB", (width, height), SURFACE)
    draw = ImageDraw.Draw(img)

    icon_size = 320
    icon_x, icon_y = 80, 90
    _rounded_rect(draw, (icon_x, icon_y, icon_x + icon_size, icon_y + icon_size), 24, PRIMARY)
    icon_draw = ImageDraw.Draw(img)
    _draw_mark(
        icon_draw,
        icon_x + icon_size // 2,
        icon_y + int(icon_size * 0.43),
        76,
        9,
        (128, 104, 80),
        20,
    )

    title_bold = _load_font(64, bold=True)
    title_regular = _load_font(64, bold=False)
    subtitle = _load_font(28, bold=False)

    draw.text((440, 150), "NR", fill=ON_SURFACE, font=title_bold)
    nr_bbox = draw.textbbox((440, 150), "NR", font=title_bold)
    draw.text((nr_bbox[2] + 8, 150), "Fácil", fill=ON_SURFACE, font=title_regular)
    draw.text(
        (440, 250),
        "Consulte NRs oficiais offline,",
        fill=ON_SURFACE_VARIANT,
        font=subtitle,
    )
    draw.text(
        (440, 290),
        "com busca rápida",
        fill=ON_SURFACE_VARIANT,
        font=subtitle,
    )

    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path, "PNG")


def main() -> int:
    try:
        from PIL import Image, ImageDraw  # noqa: F401
    except ImportError:
        print(
            "Erro: Pillow não instalado.\n"
            "Execute: pip install -r scripts/requirements-dev.txt",
            file=sys.stderr,
        )
        return 1

    STORE_DIR.mkdir(parents=True, exist_ok=True)

    outputs = [
        ("app_icon.png", lambda p: generate_app_icon(p, 1024)),
        ("app_icon_foreground.png", lambda p: generate_foreground(p, 1024)),
        ("splash_mark.png", lambda p: generate_splash_mark(p, 512)),
        ("play_store_icon_512.png", lambda p: generate_app_icon(p, 512)),
        ("feature_graphic_1024x500.png", lambda p: generate_feature_graphic(p)),
    ]

    for name, generator in outputs:
        if name.startswith("play_store") or name.startswith("feature_graphic"):
            out = STORE_DIR / name
        else:
            out = BRANDING_DIR / name
        generator(out)
        print(f"✓ {out.relative_to(ROOT)}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
