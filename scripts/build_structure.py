#!/usr/bin/env python3
"""
Gera structure.json a partir de Markdown convertido.

Produz estrutura semântica para o leitor nativo do app:
  - preamble: publicação, alterações, sumário (colapsável no app)
  - sections: seções normativas com blocos tipados (item, list, table, image, note, paragraph)

Uso:
  python3 scripts/build_structure.py --nr nr-06
  python3 scripts/build_structure.py --all
  python3 scripts/build_structure.py --nr nr-06 --dry-run
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

logger = logging.getLogger(__name__)

HEADING_RE = re.compile(r"^#+\s+(.+)$")
BOLD_TITLE_RE = re.compile(r"^\*\*(NR\s+\d+[^*]+)\*\*\s*$", re.IGNORECASE)
ITEM_RE = re.compile(r"^\*\*(\d+(?:\.\d+)+)\*?\*?\.?\s*(.*)$")
# Seção implícita sem heading #: **12.1** Princípios Gerais.
IMPLICIT_SECTION_RE = re.compile(
    r"^\*\*(\d+\.\d+)\*?\*?\.?\s+(.+)$",
)
LIST_ITEM_RE = re.compile(r"^-\s*([a-z])\)\s*(.+)$", re.IGNORECASE)
LIST_ITEM_BARE_RE = re.compile(r"^([a-z])\)\s*(.+)$", re.IGNORECASE)
LIST_ITEM_BOLD_RE = re.compile(r"^-\s*\*\*(\d+(?:\.\d+)+)\*?\*?\.?\s*(.+)$")
IMAGE_RE = re.compile(r"^!\[([^\]]*)\]\(([^)]+)\)\s*$")
NOTE_RE = re.compile(r"^_\(.+_\)\s*$")
DOU_NOTE = "Este texto não substitui o publicado no DOU"

PREAMBLE_HEADINGS = frozenset({
    "publicação",
    "publicacao",
    "d.o.u.",
    "dou",
    "sumário",
    "sumario",
})

NORMATIVE_SECTION_RE = re.compile(
    r"^(\d+\.\d+(?:\s|$)|anexo\s|glossário|glossario)",
    re.IGNORECASE,
)


def slugify(text: str) -> str:
    """Gera ID de âncora estável (mesma lógica de build_index.py)."""
    clean = re.sub(r"\*\*", "", text)
    clean = re.sub(r"<[^>]+>", "", clean)
    heading_id = re.sub(r"[^\w\s-]", "", clean.lower())
    return re.sub(r"\s+", "-", heading_id).strip("-")


def strip_markdown_inline(text: str) -> str:
    """Remove marcação inline comum sem alterar o significado."""
    result = re.sub(r"\*\*([^*]+)\*\*", r"\1", text)
    result = re.sub(r"<[^>]+>", "", result)
    return result.strip()


def parse_section_heading(raw: str) -> tuple[str, str]:
    """
    Extrai número e título de um heading de seção.

    Exemplos:
      "**6.1 Objetivo**" -> ("6.1", "Objetivo")
      "**ANEXO I LISTA DE EPI**" -> ("ANEXO I", "LISTA DE EPI")
    """
    clean = strip_markdown_inline(raw)

    # Seção numerada: 6.1 Objetivo
    match = re.match(r"^(\d+\.\d+)\s+(.+)$", clean, re.IGNORECASE)
    if match:
        return match.group(1), match.group(2).strip()

    # Anexo: ANEXO I - título ou ANEXO I da NR 17
    match = re.match(r"^(ANEXO\s+[IVXLC\d]+(?:\s+da\s+NR\s+\d+)?)\s*(.*)$", clean, re.IGNORECASE)
    if match:
        number = match.group(1).strip()
        title = match.group(2).strip().lstrip("- ").strip()
        return number.upper(), title or number.upper()

    # Glossário
    if clean.lower().startswith("glossário") or clean.lower().startswith("glossario"):
        return "Glossário", clean

    # Fallback: número vazio, título inteiro
    return "", clean


def is_preamble_heading(text: str) -> bool:
    clean = strip_markdown_inline(text).lower()
    first_word = clean.split()[0] if clean else ""
    if first_word in PREAMBLE_HEADINGS:
        return True
    if clean in PREAMBLE_HEADINGS:
        return True
    # Título da NR no topo
    if clean.startswith("nr "):
        return True
    return False


def is_normative_section_heading(text: str) -> bool:
    clean = strip_markdown_inline(text)
    if is_preamble_heading(text):
        return False
    return bool(NORMATIVE_SECTION_RE.match(clean))


def item_depth(number: str) -> int:
    """Profundidade do item: 6.1 -> 1, 6.1.1 -> 2, 6.1.1.1 -> 3."""
    parts = number.split(".")
    return max(1, len(parts) - 1)


def parse_blocks(lines: list[str]) -> list[dict[str, Any]]:
    """Classifica linhas em blocos tipados dentro de uma seção ou preâmbulo."""
    blocks: list[dict[str, Any]] = []
    i = 0

    while i < len(lines):
        line = lines[i]
        stripped = line.strip()

        if not stripped:
            i += 1
            continue

        # Tabela markdown (linhas consecutivas com |)
        if stripped.startswith("|"):
            table_lines = []
            while i < len(lines) and lines[i].strip().startswith("|"):
                table_lines.append(lines[i].strip())
                i += 1
            blocks.append({"type": "table", "markdown": "\n".join(table_lines)})
            continue

        # Imagem
        img_match = IMAGE_RE.match(stripped)
        if img_match:
            blocks.append({
                "type": "image",
                "alt": img_match.group(1),
                "src": img_match.group(2),
            })
            i += 1
            continue

        # Nota editorial
        if NOTE_RE.match(stripped) or DOU_NOTE in stripped:
            blocks.append({"type": "note", "text": stripped})
            i += 1
            continue

        # Item numerado **6.1.1** texto
        item_match = ITEM_RE.match(stripped)
        if item_match:
            number = item_match.group(1)
            text = item_match.group(2).strip()
            blocks.append({
                "type": "item",
                "number": number,
                "depth": item_depth(number),
                "text": text,
            })
            i += 1
            continue

        # Lista com bullet: - a) texto ou - **6.5.1** texto
        bold_list = LIST_ITEM_BOLD_RE.match(stripped)
        if bold_list:
            number = bold_list.group(1)
            text = bold_list.group(2).strip()
            blocks.append({
                "type": "item",
                "number": number,
                "depth": item_depth(number),
                "text": text,
            })
            i += 1
            continue

        list_match = LIST_ITEM_RE.match(stripped) or LIST_ITEM_BARE_RE.match(stripped)
        if list_match:
            list_items = []
            while i < len(lines):
                current = lines[i].strip()
                lm = LIST_ITEM_RE.match(current) or LIST_ITEM_BARE_RE.match(current)
                if not lm:
                    break
                list_items.append({"label": lm.group(1).lower(), "text": lm.group(2).strip()})
                i += 1
            blocks.append({"type": "list", "items": list_items})
            continue

        # Parágrafo: acumula linhas até próximo bloco reconhecível
        para_lines = [stripped]
        i += 1
        while i < len(lines):
            next_line = lines[i].strip()
            if not next_line:
                break
            if (
                next_line.startswith("|")
                or IMAGE_RE.match(next_line)
                or ITEM_RE.match(next_line)
                or LIST_ITEM_RE.match(next_line)
                or LIST_ITEM_BARE_RE.match(next_line)
                or LIST_ITEM_BOLD_RE.match(next_line)
                or NOTE_RE.match(next_line)
                or DOU_NOTE in next_line
            ):
                break
            para_lines.append(next_line)
            i += 1

        blocks.append({"type": "paragraph", "text": " ".join(para_lines)})

    return blocks


def extract_title(lines: list[str]) -> str:
    """Extrai título da NR das primeiras linhas."""
    for line in lines[:5]:
        stripped = line.strip()
        bold_match = BOLD_TITLE_RE.match(stripped)
        if bold_match:
            return strip_markdown_inline(bold_match.group(1))
        heading_match = HEADING_RE.match(stripped)
        if heading_match:
            inner = heading_match.group(1)
            if inner.lower().startswith("nr "):
                return strip_markdown_inline(inner)
    return ""


def is_implicit_section_line(stripped: str) -> re.Match[str] | None:
    """Detecta **N.N** título como início de seção (ex.: **12.1** Princípios)."""
    match = IMPLICIT_SECTION_RE.match(stripped)
    if not match:
        return None
    number = match.group(1)
    # Apenas N.N (duas partes), não N.N.N
    if number.count(".") != 1:
        return None
    return match


def build_structure(md_text: str) -> dict[str, Any]:
    """Constrói structure.json a partir do texto Markdown."""
    lines = md_text.split("\n")
    title = extract_title(lines)

    preamble_lines: list[str] = []
    sections: list[dict[str, Any]] = []

    current_section: dict[str, Any] | None = None
    current_lines: list[str] = []
    in_preamble = True
    title_consumed = False

    def flush_section() -> None:
        nonlocal current_section, current_lines
        if current_section is not None:
            current_section["blocks"] = parse_blocks(current_lines)
            sections.append(current_section)
            current_section = None
            current_lines = []

    def flush_preamble_line(line: str) -> None:
        preamble_lines.append(line)

    i = 0
    while i < len(lines):
        line = lines[i]
        stripped = line.strip()

        # Título no topo — vai pro preâmbulo como contexto
        if not title_consumed and stripped:
            if BOLD_TITLE_RE.match(stripped) or (
                HEADING_RE.match(stripped)
                and strip_markdown_inline(HEADING_RE.match(stripped).group(1)).lower().startswith("nr ")
            ):
                flush_preamble_line(stripped)
                title_consumed = True
                i += 1
                continue

        heading_match = HEADING_RE.match(stripped)
        if heading_match:
            raw_heading = heading_match.group(1).strip()

            if in_preamble and is_normative_section_heading(raw_heading):
                # Fecha preâmbulo e abre primeira seção normativa
                in_preamble = False
                flush_section()
                number, section_title = parse_section_heading(raw_heading)
                current_section = {
                    "id": slugify(raw_heading),
                    "number": number,
                    "title": section_title,
                    "blocks": [],
                }
                current_lines = []
            elif in_preamble:
                flush_preamble_line(stripped)
            else:
                # Nova seção normativa
                flush_section()
                number, section_title = parse_section_heading(raw_heading)
                current_section = {
                    "id": slugify(raw_heading),
                    "number": number,
                    "title": section_title,
                    "blocks": [],
                }
                current_lines = []
        elif in_preamble:
            if stripped:
                flush_preamble_line(stripped)
        else:
            # Seção implícita sem heading # (comum em NR-12)
            implicit = is_implicit_section_line(stripped)
            if implicit:
                number = implicit.group(1)
                section_title = implicit.group(2).strip().rstrip(".")
                if current_section is None or current_section.get("number") != number:
                    flush_section()
                    current_section = {
                        "id": slugify(f"{number} {section_title}"),
                        "number": number,
                        "title": section_title,
                        "blocks": [],
                    }
                    current_lines = []
                    i += 1
                    continue
            if current_section is not None:
                current_lines.append(line)
            elif stripped:
                # Conteúdo antes da primeira seção — vai pro preâmbulo
                flush_preamble_line(stripped)

        i += 1

    flush_section()

    preamble_blocks = parse_blocks(preamble_lines) if preamble_lines else []

    return {
        "title": title,
        "preamble": {"blocks": preamble_blocks},
        "sections": sections,
    }


def build_nr_structure(nr_id: str, dry_run: bool = False) -> bool:
    """Gera structure.json para uma NR. Retorna True se sucesso."""
    logger.info(f"Gerando structure.json para {nr_id}")

    nr_dir = ensure_content_dir(nr_id)
    md_file = nr_dir / f"{nr_id}.md"

    if not md_file.exists():
        logger.warning(f"{nr_id}: arquivo .md não encontrado")
        return False

    try:
        md_text = md_file.read_text(encoding="utf-8")
        structure_data = build_structure(md_text)

        if dry_run:
            n_sections = len(structure_data["sections"])
            n_preamble = len(structure_data["preamble"]["blocks"])
            logger.info(
                f"[DRY-RUN] {nr_id}: {n_sections} seções, "
                f"{n_preamble} blocos no preâmbulo"
            )
        else:
            structure_file = nr_dir / "structure.json"
            structure_file.write_text(
                json.dumps(structure_data, indent=2, ensure_ascii=False) + "\n",
                encoding="utf-8",
            )
            logger.info(
                f"  ✓ structure.json: {len(structure_data['sections'])} seções"
            )

        return True

    except Exception as e:
        logger.error(f"✗ {nr_id}: {e}")
        return False


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Gera structure.json (leitor estruturado) a partir do Markdown"
    )
    parser.add_argument("--nr", type=str, help="Uma NR específica (ex.: nr-06)")
    parser.add_argument("--all", action="store_true", help="Todas as NRs com .md")
    parser.add_argument("--dry-run", action="store_true", help="Simula sem gravar")
    parser.add_argument("--verbose", "-v", action="store_true", help="Logging detalhado")
    args = parser.parse_args()

    setup_logging(args.verbose)
    logger.info("=== build_structure.py ===")
    logger.info(f"Modo: {'DRY-RUN' if args.dry_run else 'NORMAL'}")

    if args.nr:
        nrs_to_process = [args.nr]
    elif args.all:
        nrs_to_process = [
            d.name for d in CONTENT_DIR.iterdir()
            if d.is_dir() and (d / f"{d.name}.md").exists()
        ]
    else:
        parser.print_help()
        return 1

    if not nrs_to_process:
        logger.error("Nenhuma NR encontrada")
        return 1

    logger.info(f"Gerando structure.json para {len(nrs_to_process)} NR(s)")

    errors = []
    for nr_id in sorted(nrs_to_process):
        if not build_nr_structure(nr_id, dry_run=args.dry_run):
            errors.append(nr_id)

    logger.info(f"\nResumo: {len(nrs_to_process) - len(errors)}/{len(nrs_to_process)} OK")
    if errors:
        logger.error(f"Erros em {len(errors)} NR(s): {', '.join(errors)}")
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
