#!/usr/bin/env python3
"""Importa logo + pacote EasyAppIcon para assets do app (Android e iOS)."""

from __future__ import annotations

import re
import shutil
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "app"
BRANDING = APP / "assets" / "branding"
STORE = ROOT / "docs" / "store"
INPUT = ROOT / "branding-input"
DOWNLOADS = Path.home() / "Downloads"
ANDROID_RES = APP / "android" / "app" / "src" / "main" / "res"
IOS_ICON = APP / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"

LOGO_CANDIDATES = [
    INPUT / "logo.png",
    DOWNLOADS / "ChatGPT Image 5 de set. de 2026, 20_37_00.png",
    INPUT / "logo.jpg",
    INPUT / "logo.jpeg",
    INPUT / "logo.webp",
    DOWNLOADS / "logo.png",
]
try:
    LOGO_CANDIDATES += sorted(DOWNLOADS.glob("ChatGPT Image*.png"))
    LOGO_CANDIDATES += sorted(DOWNLOADS.glob("ChatGPT Image*.jpg"))
    LOGO_CANDIDATES += sorted(DOWNLOADS.glob("ChatGPT Image*.webp"))
except OSError:
    pass

EASYAPPICON_GLOBS = [
    "easyappicon-icons-*",
    "EasyAppIcon*",
]


def find_easyappicon_dir() -> Path | None:
    explicit = [
        INPUT / "easyappicon-icons-1788651440281",
        DOWNLOADS / "easyappicon-icons-1788651440281",
    ]
    for path in explicit:
        if path.is_dir():
            return path
    dirs: list[Path] = []
    for base in (INPUT, DOWNLOADS):
        if not base.is_dir():
            continue
        try:
            for pattern in EASYAPPICON_GLOBS:
                dirs.extend(p for p in base.glob(pattern) if p.is_dir())
        except OSError:
            continue
    if not dirs:
        return None
    return max(dirs, key=lambda p: p.stat().st_mtime)


def find_logo() -> Path | None:
    for path in LOGO_CANDIDATES:
        try:
            if path.is_file():
                return path
        except OSError:
            continue
    return None


def save_png(img: Image.Image, dst: Path, size: tuple[int, int] | None = None) -> None:
    out = img.convert("RGBA")
    if size is not None:
        out = out.resize(size, Image.Resampling.LANCZOS)
    dst.parent.mkdir(parents=True, exist_ok=True)
    out.save(dst, "PNG")


def remove_background_floodfill(img: Image.Image, tolerance: int = 40) -> Image.Image:
    """Remove fundo branco conectado às bordas; preserva branco interno (livro, check)."""
    out = img.convert("RGBA")
    w, h = out.size
    for xy in ((0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)):
        ImageDraw.floodfill(out, xy, (0, 0, 0, 0), thresh=tolerance)
    return out


def build_splash_canvas(
    logo_img: Image.Image,
    canvas_size: int = 1152,
    logo_fraction: float = 0.58,
) -> Image.Image:
    """Logo centralizado em canvas transparente."""
    logo = logo_img.convert("RGBA")
    target = int(canvas_size * logo_fraction)
    scaled = logo.copy()
    scaled.thumbnail((target, target), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    x = (canvas_size - scaled.width) // 2
    y = (canvas_size - scaled.height) // 2
    canvas.paste(scaled, (x, y), scaled)
    return canvas


def build_splash_android12(logo_img: Image.Image) -> Image.Image:
    """Android 12+ mascara o ícone em círculo (768px em canvas 1152px)."""
    return build_splash_canvas(logo_img, canvas_size=1152, logo_fraction=0.47)


def read_adaptive_background(easy_dir: Path) -> str | None:
    xml_path = easy_dir / "android" / "values" / "ic_launcher_background.xml"
    if not xml_path.is_file():
        return None
    text = xml_path.read_text(encoding="utf-8")
    match = re.search(r"#([0-9A-Fa-f]{6,8})", text)
    return f"#{match.group(1)[:6].upper()}" if match else None


def copy_tree(src: Path, dst: Path) -> None:
    if dst.exists():
        shutil.rmtree(dst)
    shutil.copytree(src, dst)


def copy_android_icons(easy_dir: Path) -> None:
    src_android = easy_dir / "android"
    for folder in src_android.iterdir():
        name = folder.name
        if not folder.is_dir():
            continue
        if name.startswith("mipmap-"):
            dst = ANDROID_RES / name
            if dst.exists():
                shutil.rmtree(dst)
            shutil.copytree(folder, dst)


def copy_ios_icons(easy_dir: Path) -> None:
    src_set = easy_dir / "ios" / "AppIcon.appiconset"
    if not src_set.is_dir():
        print("  ⚠ Pacote iOS não encontrado no EasyAppIcon — pulando.")
        return
    if not (APP / "ios").is_dir():
        print("  → Criando plataforma iOS…")
        subprocess.run(
            ["fvm", "flutter", "create", "--platforms=ios", "."],
            cwd=APP,
            check=True,
        )
    copy_tree(src_set, IOS_ICON)


def build_branding_assets(logo: Path, easy_dir: Path) -> str | None:
    logo_img = Image.open(logo).convert("RGBA")
    save_png(logo_img, BRANDING / "app_icon.png", (1024, 1024))

    fg_src = easy_dir / "android" / "mipmap-xxxhdpi" / "ic_launcher_foreground.png"
    if not fg_src.is_file():
        fg_src = easy_dir / "android" / "playstore-icon.png"
    fg_img = Image.open(fg_src).convert("RGBA")
    save_png(fg_img, BRANDING / "app_icon_foreground.png", (1024, 1024))

    logo_transparent = remove_background_floodfill(logo_img)
    save_png(build_splash_canvas(logo_transparent), BRANDING / "splash_mark.png")
    save_png(build_splash_android12(logo_transparent), BRANDING / "splash_android12.png")

    store_src = easy_dir / "android" / "playstore-icon.png"
    if store_src.is_file():
        save_png(Image.open(store_src).convert("RGBA"), STORE / "play_store_icon_512.png", (512, 512))
    else:
        save_png(logo_img, STORE / "play_store_icon_512.png", (512, 512))

    if logo.parent.resolve() != INPUT.resolve():
        try:
            shutil.copy2(logo, INPUT / "logo.png")
        except OSError:
            pass
    return read_adaptive_background(easy_dir)


def update_android_launcher_color(hex_color: str | None) -> None:
    if not hex_color:
        return
    colors_xml = ANDROID_RES / "values" / "colors.xml"
    text = colors_xml.read_text(encoding="utf-8")
    updated = re.sub(
        r'(<color name="ic_launcher_background">)#[0-9A-Fa-f]{6}(</color>)',
        rf"\g<1>{hex_color}\2",
        text,
    )
    if updated == text and "ic_launcher_background" not in text:
        updated = text.replace(
            "</resources>",
            f'    <color name="ic_launcher_background">{hex_color}</color>\n</resources>',
        )
    if updated != text:
        colors_xml.write_text(updated, encoding="utf-8")
        print(f"  ✓ colors.xml → ic_launcher_background {hex_color}")


def update_pubspec_color(hex_color: str | None) -> None:
    if not hex_color:
        return
    pubspec = APP / "pubspec.yaml"
    text = pubspec.read_text(encoding="utf-8")
    updated = re.sub(
        r'(adaptive_icon_background:\s*")#[0-9A-Fa-f]{6}(")',
        rf"\g<1>{hex_color}\2",
        text,
    )
    updated = re.sub(
        r'(flutter_native_splash:\s*\n\s*color:\s*")#[0-9A-Fa-f]{6}(")',
        rf"\g<1>{hex_color}\2",
        updated,
    )
    updated = re.sub(
        r'(android_12:\s*\n\s*color:\s*")#[0-9A-Fa-f]{6}(")',
        rf"\g<1>{hex_color}\2",
        updated,
    )
    updated = re.sub(
        r'(icon_background_color:\s*")#[0-9A-Fa-f]{6}(")',
        rf"\g<1>{hex_color}\2",
        updated,
    )
    if updated != text:
        pubspec.write_text(updated, encoding="utf-8")
        print(f"  ✓ pubspec.yaml → cor {hex_color}")


def enable_ios_launcher_icons() -> None:
    pubspec = APP / "pubspec.yaml"
    text = pubspec.read_text(encoding="utf-8")
    if "ios: true" in text:
        return
    updated = text.replace("  ios: false", "  ios: true", 1)
    if updated != text:
        pubspec.write_text(updated, encoding="utf-8")
        print("  ✓ pubspec.yaml → ios: true")


def regenerate_splash() -> None:
    subprocess.run(["fvm", "dart", "run", "flutter_native_splash:create"], cwd=APP, check=True)
    strip_android12_icon_background()


def strip_android12_icon_background() -> None:
    """Remove disco quadrado atrás do ícone no Android 12+ (gerado pelo pacote)."""
    for rel in ("values-v31/styles.xml", "values-night-v31/styles.xml"):
        path = ANDROID_RES / rel
        if not path.is_file():
            continue
        text = path.read_text(encoding="utf-8")
        updated = re.sub(
            r"\s*<item name=\"android:windowSplashScreenIconBackgroundColor\">[^<]+</item>\n?",
            "",
            text,
        )
        if updated != text:
            path.write_text(updated, encoding="utf-8")
            print(f"  ✓ {rel} → sem icon background")


def main() -> int:
    logo = find_logo()
    easy_dir = find_easyappicon_dir()
    if logo is None or easy_dir is None:
        print("Erro: arquivos de branding não encontrados.\n", file=sys.stderr)
        print("Esperado:", file=sys.stderr)
        print("  • Logo: branding-input/logo.png  OU  ~/Downloads/ChatGPT Image*.png", file=sys.stderr)
        print("  • Ícones: branding-input/easyappicon-icons-*  OU  ~/Downloads/easyappicon-icons-*", file=sys.stderr)
        print("\nRode no Terminal (fora do sandbox do Cursor):", file=sys.stderr)
        print("  ./scripts/import_branding.sh", file=sys.stderr)
        return 1

    INPUT.mkdir(parents=True, exist_ok=True)
    print(f"Logo: {logo}")
    print(f"EasyAppIcon: {easy_dir.name}")

    bg = build_branding_assets(logo, easy_dir)
    copy_android_icons(easy_dir)
    print("  ✓ Android mipmaps copiados")
    copy_ios_icons(easy_dir)
    print("  ✓ iOS AppIcon.appiconset copiado")
    update_pubspec_color(bg)
    update_android_launcher_color(bg)
    enable_ios_launcher_icons()
    print("  → Regenerando splash…")
    regenerate_splash()
    print("\n✓ Branding importado com sucesso.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
