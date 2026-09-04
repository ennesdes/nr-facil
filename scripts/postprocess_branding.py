#!/usr/bin/env python3
"""Pós-processa PNGs gerados por IA e copia para os paths finais.

Uso:
    1. Gere os PNGs com a ferramenta de imagem (ver docs/store/README.md)
    2. Ajuste GENERATED_DIR abaixo se necessário
    3. python3 scripts/postprocess_branding.py
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
GENERATED_DIR = Path.home() / ".cursor/projects/Users-douglasennes-Documents-projects-nr-facil/assets"
BRANDING_DIR = ROOT / "app" / "assets" / "branding"
STORE_DIR = ROOT / "docs" / "store"

SOURCES = {
    "app_icon": GENERATED_DIR / "app_icon_generated.png",
    "foreground": GENERATED_DIR / "app_icon_foreground_generated.png",
    "feature": GENERATED_DIR / "feature_graphic_generated.png",
}


def resize_square(src: Path, dst: Path, size: int) -> None:
    img = Image.open(src).convert("RGBA")
    img = img.resize((size, size), Image.Resampling.LANCZOS)
    dst.parent.mkdir(parents=True, exist_ok=True)
    img.save(dst, "PNG")


def black_to_alpha(src: Path, dst: Path, size: int, threshold: int = 30) -> None:
    img = Image.open(src).convert("RGBA")
    img = img.resize((size, size), Image.Resampling.LANCZOS)
    pixels = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            if r < threshold and g < threshold and b < threshold:
                pixels[x, y] = (r, g, b, 0)
    dst.parent.mkdir(parents=True, exist_ok=True)
    img.save(dst, "PNG")


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
    for name, path in SOURCES.items():
        if not path.exists():
            print(f"Erro: arquivo não encontrado: {path}")
            print("Gere os PNGs com IA primeiro (ver docs/store/README.md)")
            return 1

    resize_square(SOURCES["app_icon"], BRANDING_DIR / "app_icon.png", 1024)
    resize_square(SOURCES["app_icon"], STORE_DIR / "play_store_icon_512.png", 512)
    black_to_alpha(SOURCES["foreground"], BRANDING_DIR / "app_icon_foreground.png", 1024)
    black_to_alpha(SOURCES["foreground"], BRANDING_DIR / "splash_mark.png", 512)
    resize_feature(SOURCES["feature"], STORE_DIR / "feature_graphic_1024x500.png")

    for path in [
        BRANDING_DIR / "app_icon.png",
        BRANDING_DIR / "app_icon_foreground.png",
        BRANDING_DIR / "splash_mark.png",
        STORE_DIR / "play_store_icon_512.png",
        STORE_DIR / "feature_graphic_1024x500.png",
    ]:
        print(f"✓ {path.relative_to(ROOT)}")

    print("\nPróximo passo:")
    print("  cd app && fvm dart run flutter_launcher_icons && fvm dart run flutter_native_splash:create")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
