#!/usr/bin/env python3
"""Importa feature graphic da Play Store a partir de ~/Downloads/capa.*."""

from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
DOWNLOADS = Path.home() / "Downloads"
STORE_DIR = ROOT / "docs" / "store"
OUTPUT = STORE_DIR / "feature_graphic_1024x500.png"

CANDIDATES = [
    STORE_DIR / "capa.png",
    DOWNLOADS / "capa.png",
    DOWNLOADS / "capa.jpg",
    DOWNLOADS / "capa.jpeg",
    DOWNLOADS / "capa.webp",
    DOWNLOADS / "Capa.png",
]


def find_source() -> Path | None:
    for path in CANDIDATES:
        if path.is_file():
            return path
    return None


def resize_feature(src: Path, dst: Path) -> None:
    img = Image.open(src).convert("RGB")
    target_w, target_h = 1024, 500
    w, h = img.size
    target_ratio = target_w / target_h
    current_ratio = w / h
    if current_ratio > target_ratio:
        new_w = int(h * target_ratio)
        left = (w - new_w) // 2
        img = img.crop((left, 0, left + new_w, h))
    else:
        new_h = int(w / target_ratio)
        top = (h - new_h) // 2
        img = img.crop((0, top, w, top + new_h))
    img = img.resize((target_w, target_h), Image.Resampling.LANCZOS)
    dst.parent.mkdir(parents=True, exist_ok=True)
    img.save(dst, "PNG")


def main() -> int:
    src = find_source()
    if src is None:
        print(
            "Erro: arquivo não encontrado em ~/Downloads/\n"
            "  Esperado: capa.png (ou .jpg / .jpeg / .webp)",
            file=sys.stderr,
        )
        return 1

    resize_feature(src, OUTPUT)
    print(f"✓ {OUTPUT.relative_to(ROOT)} (fonte: {src.name})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
