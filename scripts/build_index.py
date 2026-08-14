#!/usr/bin/env python3
"""
Gera índices de navegação e busca a partir de Markdown convertido.

Produz:
  - index.json: estrutura de headings para navegação (sidebar do leitor)
  - search_index.json: chunks para busca full-text (ex.: parágrafos de 200-300 chars)

Uso:
  python3 scripts/build_index.py --nr nr-06           # uma NR
  python3 scripts/build_index.py --all                # todas
  python3 scripts/build_index.py --nr nr-06 --dry-run # simula
"""
from __future__ import annotations

import argparse
import json
import logging
import re
import sys
from pathlib import Path
from typing import Any

from _common import list_all_nrs, ensure_content_dir, setup_logging

logger = logging.getLogger(__name__)


def extract_headings(md_text: str) -> list[dict[str, Any]]:
    """
    Extrai estrutura de headings do Markdown.

    Retorna lista de:
    {
      "level": 2,  # número de #
      "text": "Artigo 17",
      "id": "artigo-17",  # para âncora
    }
    """
    headings = []
    for line in md_text.split("\n"):
        match = re.match(r"^(#+)\s+(.+)$", line)
        if match:
            level = len(match.group(1))
            text = match.group(2).strip()
            # ID: texto em minúsculas, sem caracteres especiais, hífens
            heading_id = re.sub(r"[^\w\s-]", "", text.lower())
            heading_id = re.sub(r"\s+", "-", heading_id)

            headings.append({
                "level": level,
                "text": text,
                "id": heading_id,
            })

    return headings


def build_index_json(md_text: str) -> dict[str, Any]:
    """Estrutura hierárquica de headings para navegação."""
    headings = extract_headings(md_text)

    # Constrói árvore (simplificado: lista com nível, sem nesting aninhado)
    return {
        "headings": headings,
    }


def chunk_text_for_search(md_text: str, chunk_size: int = 250) -> list[dict[str, Any]]:
    """
    Divide o texto em chunks para busca full-text.

    Cada chunk tem ~250 characters (ajustável), com contexto de heading.

    Retorna lista de:
    {
      "id": "chunk-0",
      "text": "...",
      "heading": "Artigo 17",
      "char_offset": 1234,  # posição no original
    }
    """
    chunks = []
    chunk_id = 0
    current_heading = "Introdução"

    # Processa o texto linha a linha
    lines = md_text.split("\n")
    current_chunk = ""
    char_offset = 0

    for line in lines:
        # Detecta heading
        heading_match = re.match(r"^#+\s+(.+)$", line)
        if heading_match:
            current_heading = heading_match.group(1).strip()
            # Salva chunk anterior se houver
            if current_chunk.strip():
                chunks.append({
                    "id": f"chunk-{chunk_id}",
                    "text": current_chunk.strip(),
                    "heading": current_heading,
                    "char_offset": char_offset,
                })
                chunk_id += 1
                current_chunk = ""
            continue

        # Ignora linhas vazias e comentários
        if not line.strip() or line.strip().startswith("<!--"):
            char_offset += len(line) + 1
            continue

        # Acumula linha ao chunk
        current_chunk += line + "\n"
        char_offset += len(line) + 1

        # Se chunk ficou grande, salva e começa novo
        if len(current_chunk) >= chunk_size:
            text = current_chunk.strip()
            if text:
                chunks.append({
                    "id": f"chunk-{chunk_id}",
                    "text": text,
                    "heading": current_heading,
                    "char_offset": char_offset - len(current_chunk),
                })
                chunk_id += 1
            current_chunk = ""

    # Salva último chunk
    if current_chunk.strip():
        chunks.append({
            "id": f"chunk-{chunk_id}",
            "text": current_chunk.strip(),
            "heading": current_heading,
            "char_offset": char_offset - len(current_chunk),
        })

    return chunks


def build_nr_indices(nr_id: str, dry_run: bool = False) -> bool:
    """Gera índices para uma NR. Retorna True se sucesso."""
    logger.info(f"Gerando índices para {nr_id}")

    nr_dir = ensure_content_dir(nr_id)
    md_file = nr_dir / f"{nr_id}.md"

    if not md_file.exists():
        logger.warning(f"{nr_id}: arquivo .md não encontrado")
        return False

    try:
        md_text = md_file.read_text(encoding="utf-8")

        # Gera índices
        index_data = build_index_json(md_text)
        search_chunks = chunk_text_for_search(md_text)

        if dry_run:
            logger.info(f"[DRY-RUN] {nr_id}: teria gerado {len(index_data['headings'])} headings, {len(search_chunks)} chunks")
        else:
            # Salva index.json
            index_file = nr_dir / "index.json"
            index_file.write_text(
                json.dumps(index_data, indent=2, ensure_ascii=False) + "\n",
                encoding="utf-8"
            )
            logger.info(f"  ✓ index.json: {len(index_data['headings'])} headings")

            # Salva search_index.json
            search_file = nr_dir / "search_index.json"
            search_file.write_text(
                json.dumps(search_chunks, indent=2, ensure_ascii=False) + "\n",
                encoding="utf-8"
            )
            logger.info(f"  ✓ search_index.json: {len(search_chunks)} chunks")

        return True

    except Exception as e:
        logger.error(f"✗ {nr_id}: {e}")
        return False


def main() -> int:
    """Gera índices para navegação e busca."""
    parser = argparse.ArgumentParser(
        description="Gera index.json (navegação) e search_index.json (busca full-text)"
    )
    parser.add_argument(
        "--nr",
        type=str,
        help="Uma NR específica (ex.: nr-06)"
    )
    parser.add_argument(
        "--all",
        action="store_true",
        help="Todas as NRs com .md em content/"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Simula sem gravar"
    )
    parser.add_argument(
        "--verbose", "-v",
        action="store_true",
        help="Logging detalhado"
    )
    args = parser.parse_args()

    setup_logging(args.verbose)

    logger.info("=== build_index.py ===")
    logger.info(f"Modo: {'DRY-RUN' if args.dry_run else 'NORMAL'}")

    # Determina quais NRs processar
    if args.nr:
        nrs_to_process = [args.nr]
    elif args.all:
        from _common import CONTENT_DIR
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

    logger.info(f"Gerando índices para {len(nrs_to_process)} NR(s)")

    errors = []
    for nr_id in nrs_to_process:
        if not build_nr_indices(nr_id, dry_run=args.dry_run):
            errors.append(nr_id)

    logger.info(f"\nResumo: {len(nrs_to_process) - len(errors)}/{len(nrs_to_process)} OK")
    if errors:
        logger.error(f"Erros em {len(errors)} NR(s): {', '.join(errors)}")
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
