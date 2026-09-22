#!/usr/bin/env python3
"""
Validação de qualidade pós-conversão de NRs.

Gera quality_report.json por NR com warnings detectáveis automaticamente.
Pode marcar NR como revisada (reviewed: true) quando passa no gate.

Uso:
  python3 scripts/validate_quality.py --nr nr-06
  python3 scripts/validate_quality.py --all
  python3 scripts/validate_quality.py --all --mark-reviewed
"""
from __future__ import annotations

import argparse
import json
import logging
import re
import sys
from pathlib import Path
from typing import Any

from _common import CONTENT_DIR, ensure_content_dir, list_all_nrs, setup_logging
from normalize_md import DOU_NOTE

logger = logging.getLogger(__name__)

DOU_INLINE_RE = re.compile(re.escape(DOU_NOTE), re.IGNORECASE)
BROKEN_HYPHEN_RE = re.compile(r"\w- \w")
ORPHAN_PAGE_RE = re.compile(r"^\s*\d{1,3}\s*$", re.MULTILINE)
BROKEN_TABLE_RE = re.compile(r"^\|\s*---\s*\|", re.MULTILINE)
IMAGE_REF_RE = re.compile(r"!\[[^\]]*\]\([^)]+\)")
HTML_BR_RE = re.compile(r"<br\s*/?>", re.IGNORECASE)
HTML_MARK_RE = re.compile(r"</?mark\b", re.IGNORECASE)
PICTURE_TEXT_RE = re.compile(r"Start of picture text", re.IGNORECASE)

FRAGMENTED_TABLE_SEP_THRESHOLD = 10
STRUCTURE_TABLE_BLOCK_THRESHOLD = 25
PNG_HEAVY_MIN_FALLBACK = 15


def _count_structure_table_blocks(nr_dir: Path) -> int:
    structure_file = nr_dir / "structure.json"
    if not structure_file.exists():
        return 0
    try:
        data = json.loads(structure_file.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return 0

    count = 0
    preamble = data.get("preamble") or {}
    for block in preamble.get("blocks") or []:
        if isinstance(block, dict) and block.get("type") == "table":
            count += 1
    for section in data.get("sections") or []:
        if not isinstance(section, dict):
            continue
        for block in section.get("blocks") or []:
            if isinstance(block, dict) and block.get("type") == "table":
                count += 1
    return count


def analyze_nr_quality(nr_id: str) -> dict[str, Any]:
    """Analisa qualidade do Markdown convertido de uma NR."""
    nr_dir = CONTENT_DIR / nr_id
    md_file = nr_dir / f"{nr_id}.md"
    pdf_file = nr_dir / f"{nr_id}.pdf"
    meta_file = nr_dir / "meta.json"

    warnings: list[str] = []
    pages_fallback_png = 0

    if not md_file.exists():
        return {
            "nr_id": nr_id,
            "ok": False,
            "warnings": ["arquivo .md não encontrado"],
            "char_ratio": None,
            "pages_fallback_png": 0,
        }

    text = md_file.read_text(encoding="utf-8")

    if DOU_INLINE_RE.search(text):
        count = len(DOU_INLINE_RE.findall(text))
        warnings.append(f"dou_footer_inline: {count} ocorrência(s)")

    if BROKEN_HYPHEN_RE.search(text):
        warnings.append("broken_hyphenation: hifenização residual detectada")

    if ORPHAN_PAGE_RE.search(text):
        warnings.append("orphan_page_numbers: números de página soltos no texto")

    # Tabelas com separador órfão no meio do documento (heurística)
    table_seps = BROKEN_TABLE_RE.findall(text)
    fragmented_table_count = len(table_seps)
    if fragmented_table_count > 3:
        warnings.append(
            f"fragmented_tables: {fragmented_table_count} separadores de tabela"
        )

    structure_table_blocks = _count_structure_table_blocks(nr_dir)
    if structure_table_blocks > STRUCTURE_TABLE_BLOCK_THRESHOLD:
        warnings.append(
            f"too_many_table_blocks: {structure_table_blocks} blocos table no structure.json"
        )

    if HTML_BR_RE.search(text):
        count = len(HTML_BR_RE.findall(text))
        warnings.append(f"html_br_tags: {count} ocorrência(s)")

    if HTML_MARK_RE.search(text):
        count = len(HTML_MARK_RE.findall(text))
        warnings.append(f"html_mark_tags: {count} ocorrência(s)")

    if PICTURE_TEXT_RE.search(text):
        warnings.append("picture_text_ocr: blocos OCR de diagrama não removidos")

    pages_dir = nr_dir / "assets" / "pages"
    if pages_dir.exists():
        pages_fallback_png = len(list(pages_dir.glob("*.png")))

    image_refs = IMAGE_REF_RE.findall(text)
    if image_refs:
        pages_fallback_png = max(pages_fallback_png, len(image_refs))

    md_chars = len(text)
    pdf_chars = None
    char_ratio = None
    if pdf_file.exists():
        try:
            import fitz  # pymupdf

            doc = fitz.open(pdf_file)
            pdf_chars = sum(len(page.get_text()) for page in doc)
            doc.close()
            if pdf_chars > 0:
                char_ratio = round(md_chars / pdf_chars, 3)
                if char_ratio < 0.5:
                    if pages_fallback_png >= PNG_HEAVY_MIN_FALLBACK:
                        warnings.append(
                            f"png_heavy_char_ratio: {char_ratio} "
                            f"({pages_fallback_png} PNGs — texto normativo em imagens)"
                        )
                    else:
                        warnings.append(
                            f"low_char_ratio: {char_ratio} (possível perda de conteúdo)"
                        )
        except Exception:
            logger.debug(f"{nr_id}: não foi possível calcular char_ratio do PDF")

    critical = [
        w
        for w in warnings
        if w.startswith(("dou_footer", "low_char_ratio"))
    ]

    prefer_png_tables = (
        fragmented_table_count > FRAGMENTED_TABLE_SEP_THRESHOLD
        or structure_table_blocks > STRUCTURE_TABLE_BLOCK_THRESHOLD
    )
    if prefer_png_tables:
        critical.append("prefer_png_tables: reconverter com heurística PNG por página")

    report: dict[str, Any] = {
        "nr_id": nr_id,
        "ok": len(critical) == 0,
        "warnings": warnings,
        "char_ratio": char_ratio,
        "md_chars": md_chars,
        "pdf_chars": pdf_chars,
        "pages_fallback_png": pages_fallback_png,
        "structure_table_blocks": structure_table_blocks,
        "fragmented_table_separators": fragmented_table_count,
    }

    if prefer_png_tables:
        report["recommended_action"] = "reconvert_tables_as_png"

    if meta_file.exists():
        try:
            meta = json.loads(meta_file.read_text(encoding="utf-8"))
            report["reviewed"] = meta.get("reviewed", False)
        except json.JSONDecodeError:
            report["reviewed"] = False

    return report


def save_quality_report(nr_id: str, report: dict[str, Any]) -> None:
    """Salva quality_report.json na pasta da NR."""
    nr_dir = ensure_content_dir(nr_id)
    report_file = nr_dir / "quality_report.json"
    report_file.write_text(
        json.dumps(report, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )


def mark_reviewed(nr_id: str, reviewed: bool = True) -> None:
    """Atualiza campo reviewed em meta.json."""
    nr_dir = ensure_content_dir(nr_id)
    meta_file = nr_dir / "meta.json"
    meta: dict[str, Any] = {}
    if meta_file.exists():
        try:
            meta = json.loads(meta_file.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            meta = {}
    meta["reviewed"] = reviewed
    meta_file.write_text(
        json.dumps(meta, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )


def main() -> int:
    parser = argparse.ArgumentParser(description="Valida qualidade da conversão de NRs")
    parser.add_argument("--nr", type=str, help="Uma NR (ex.: nr-06)")
    parser.add_argument("--all", action="store_true", help="Todas as NRs em content/")
    parser.add_argument(
        "--mark-reviewed",
        action="store_true",
        help="Marca reviewed=true em NRs que passam no gate de qualidade",
    )
    parser.add_argument("--verbose", "-v", action="store_true")
    args = parser.parse_args()

    setup_logging(args.verbose)
    logger.info("=== validate_quality.py ===")

    if args.nr:
        nr_ids = [args.nr]
    elif args.all:
        nr_ids = [
            d.name
            for d in CONTENT_DIR.iterdir()
            if d.is_dir() and (d / f"{d.name}.md").exists()
        ]
        if not nr_ids:
            nr_ids = list_all_nrs()
    else:
        parser.print_help()
        return 1

    failures = []
    for nr_id in sorted(nr_ids):
        report = analyze_nr_quality(nr_id)
        save_quality_report(nr_id, report)

        if args.mark_reviewed and report["ok"]:
            mark_reviewed(nr_id, True)
            logger.info(f"✓ {nr_id}: revisada (reviewed=true)")
        elif report["ok"]:
            logger.info(f"✓ {nr_id}: OK")
        else:
            logger.warning(f"⚠ {nr_id}: {len(report['warnings'])} warning(s)")
            for w in report["warnings"]:
                logger.warning(f"    - {w}")
            failures.append(nr_id)

    logger.info(f"\nResumo: {len(nr_ids) - len(failures)}/{len(nr_ids)} passaram no gate")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
