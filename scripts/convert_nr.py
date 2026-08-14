#!/usr/bin/env python3
"""
Conversão de PDF de NR para Markdown estruturado.

Executa 3 passes sempre (sem exceção, mesmo para NRs "simples"):
1. Pass texto: pymupdf4llm → corpo normativo em Markdown
2. Pass tabelas: pdfplumber → HTML em assets/tables/
3. Pass imagens/diagramas: render de página → PNG em assets/pages/

Depois faz merge dos 3 passes num .md único padronizado.
Salva PDF original e calcula pdf_hash (SHA-256).

Uso:
  python3 scripts/convert_nr.py --nr nr-06           # uma NR
  python3 scripts/convert_nr.py --all                # todas (de nr_index.json)
  python3 scripts/convert_nr.py --nr nr-06 --dry-run # simula
  python3 scripts/convert_nr.py --help               # ajuda
"""
from __future__ import annotations

import argparse
import hashlib
import json
import logging
import sys
from pathlib import Path
from typing import Any

try:
    import pymupdf4llm
    import pdfplumber
    import pymupdf as fitz
    import requests
except ImportError as e:
    print(f"Erro: {e}. Instale com: pip install -r scripts/requirements.txt", file=sys.stderr)
    sys.exit(1)

from _common import merge_nr_data, list_all_nrs, ensure_content_dir, ensure_assets_dir, setup_logging
from normalize_md import normalize_markdown

logger = logging.getLogger(__name__)


def download_pdf(pdf_url: str, nr_id: str, dry_run: bool = False) -> tuple[Path | None, str]:
    """
    Download do PDF.

    Retorna (caminho_arquivo, pdf_hash) ou (None, "") se falhar.
    """
    nr_dir = ensure_content_dir(nr_id)
    pdf_file = nr_dir / f"{nr_id}.pdf"

    logger.info(f"Baixando PDF de {nr_id} de {pdf_url}")

    if dry_run:
        logger.info(f"[DRY-RUN] teria baixado para {pdf_file}")
        return None, ""

    try:
        resp = requests.get(pdf_url, timeout=30)
        resp.raise_for_status()
        pdf_bytes = resp.content

        # Calcula SHA-256
        pdf_hash = hashlib.sha256(pdf_bytes).hexdigest()

        # Grava PDF
        pdf_file.write_bytes(pdf_bytes)
        logger.info(f"✓ PDF salvo ({len(pdf_bytes)} bytes, hash={pdf_hash[:16]}...)")

        return pdf_file, pdf_hash

    except Exception as e:
        logger.error(f"✗ Falha ao baixar PDF: {e}")
        return None, ""


def extract_text_pass(pdf_file: Path, nr_id: str) -> str:
    """Pass 1: Extração de texto com pymupdf4llm."""
    logger.info(f"{nr_id}: Pass 1 — Extração de texto")

    try:
        # pymupdf4llm extrai texto em Markdown
        md_text = pymupdf4llm.to_markdown(str(pdf_file))
        logger.info(f"  {len(md_text)} chars extraídos")
        return md_text
    except Exception as e:
        logger.error(f"  Falha na pass de texto: {e}")
        return ""


def extract_tables_pass(pdf_file: Path, nr_id: str) -> str:
    """Pass 2: Extração de tabelas com pdfplumber → HTML."""
    logger.info(f"{nr_id}: Pass 2 — Extração de tabelas")

    tables_dir = ensure_assets_dir(nr_id, "tables")
    tables_markdown = ""

    try:
        with pdfplumber.open(str(pdf_file)) as pdf:
            table_count = 0
            for page_num, page in enumerate(pdf.pages, start=1):
                tables = page.extract_tables()
                if tables:
                    for table_idx, table in enumerate(tables):
                        table_count += 1
                        table_id = f"page_{page_num:03d}_table_{table_idx:02d}"
                        table_file = tables_dir / f"{table_id}.html"

                        # Converte table (lista de listas) para HTML simples
                        html = "<table>\n"
                        for row in table:
                            html += "  <tr>\n"
                            for cell in row:
                                html += f"    <td>{cell or ''}</td>\n"
                            html += "  </tr>\n"
                        html += "</table>"

                        table_file.write_text(html, encoding="utf-8")
                        logger.debug(f"  Tabela {table_id} salva")

                        # Referencia no markdown
                        tables_markdown += f"\n> [Tabela {table_count}: page {page_num}](../assets/tables/{table_id}.html)\n"

        logger.info(f"  {table_count} tabelas extraídas")
        return tables_markdown

    except Exception as e:
        logger.error(f"  Falha na pass de tabelas: {e}")
        return ""


def extract_images_pass(pdf_file: Path, nr_id: str) -> str:
    """Pass 3: Render de páginas → PNG em assets/pages/."""
    logger.info(f"{nr_id}: Pass 3 — Render de páginas")

    pages_dir = ensure_assets_dir(nr_id, "pages")
    images_markdown = ""

    try:
        doc = fitz.open(str(pdf_file))
        for page_num, page in enumerate(doc, start=1):
            # Render com zoom 2x para melhor qualidade
            pix = page.get_pixmap(matrix=fitz.Matrix(2, 2))
            img_file = pages_dir / f"page-{page_num:03d}.png"
            pix.save(str(img_file))
            logger.debug(f"  Page {page_num} renderizada")

            # Referencia no markdown (entre páginas de capítulos, se houver)
            images_markdown += f"\n> ![Page {page_num}](../assets/pages/page-{page_num:03d}.png)\n"

        logger.info(f"  {len(doc)} páginas renderizadas")
        doc.close()
        return images_markdown

    except Exception as e:
        logger.error(f"  Falha na pass de imagens: {e}")
        return ""


def merge_passes(text_md: str, tables_md: str, images_md: str, nr_id: str) -> str:
    """Merge dos 3 passes em um único markdown."""
    # Estrutura: Texto principal + referências de tabelas + imagens (opcional, com comentário)
    merged = text_md

    if tables_md:
        merged += "\n\n## Tabelas\n" + tables_md

    # Imagens só incluídas como referência oculta (comentário) para não poluir o leitor
    if images_md:
        merged += "\n\n<!-- Imagens das páginas (para fallback): \n" + images_md + "\n-->"

    return merged


def save_metadata(nr_id: str, pdf_hash: str, md_text: str) -> None:
    """Salva metadata básica em content/nr-XX/meta.json (se não existir)."""
    nr_dir = ensure_content_dir(nr_id)
    meta_file = nr_dir / "meta.json"

    # Se já existe, não sobrescreve (scrape_vigencia.py preenche depois)
    if meta_file.exists():
        return

    meta = {
        "pdf_hash": pdf_hash,
        "char_count": len(md_text),
        "extracted_at": None,  # será preenchido por scrape_vigencia.py
    }

    meta_file.write_text(json.dumps(meta, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def convert_nr(nr_id: str, dry_run: bool = False) -> bool:
    """Converte uma NR. Retorna True se sucesso."""
    logger.info(f"\n{'='*60}")
    logger.info(f"Convertendo {nr_id}")
    logger.info(f"{'='*60}")

    # Merge de dados (nr_index.json + nr_sources.json)
    nr_data = merge_nr_data(nr_id)
    pdf_url = nr_data.get("pdf_url")

    if not pdf_url:
        logger.error(f"{nr_id}: pdf_url não encontrada, abortando")
        return False

    # 1. Download PDF
    pdf_file, pdf_hash = download_pdf(pdf_url, nr_id, dry_run=dry_run)
    if not pdf_file or not pdf_hash:
        logger.error(f"{nr_id}: não foi possível baixar/hashear PDF")
        return False

    if dry_run:
        logger.info(f"[DRY-RUN] {nr_id}: teria feito os 3 passes e merge")
        return True

    # 2. Executar os 3 passes
    text_md = extract_text_pass(pdf_file, nr_id)
    if not text_md:
        logger.error(f"{nr_id}: falha na extração de texto")
        return False

    tables_md = extract_tables_pass(pdf_file, nr_id)
    images_md = extract_images_pass(pdf_file, nr_id)

    # 3. Merge e normalização
    merged_md = merge_passes(text_md, tables_md, images_md, nr_id)
    normalized_md = normalize_markdown(merged_md)

    # 4. Salva resultado
    nr_dir = ensure_content_dir(nr_id)
    md_file = nr_dir / f"{nr_id}.md"
    md_file.write_text(normalized_md, encoding="utf-8")
    logger.info(f"✓ {nr_id}: markdown salvo ({len(normalized_md)} chars)")

    # 5. Metadados
    save_metadata(nr_id, pdf_hash, normalized_md)

    return True


def main() -> int:
    """Converte PDF(s) em Markdown."""
    parser = argparse.ArgumentParser(
        description="Converte PDF de NR em Markdown (3 passes: texto, tabelas, imagens)"
    )
    parser.add_argument(
        "--nr",
        type=str,
        help="Uma NR específica (ex.: nr-06)"
    )
    parser.add_argument(
        "--all",
        action="store_true",
        help="Todas as NRs (de nr_index.json)"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Simula sem gravar/baixar"
    )
    parser.add_argument(
        "--verbose", "-v",
        action="store_true",
        help="Logging detalhado"
    )
    args = parser.parse_args()

    setup_logging(args.verbose)

    logger.info("=== convert_nr.py ===")
    logger.info(f"Modo: {'DRY-RUN' if args.dry_run else 'NORMAL'}")

    # Determina quais NRs processar
    if args.nr:
        nrs_to_process = [args.nr]
    elif args.all:
        nrs_to_process = list_all_nrs()
    else:
        parser.print_help()
        return 1

    if not nrs_to_process:
        logger.error("Nenhuma NR encontrada em nr_index.json")
        return 1

    logger.info(f"Processando {len(nrs_to_process)} NR(s)")

    errors: list[tuple[str, str]] = []

    for nr_id in nrs_to_process:
        try:
            if not convert_nr(nr_id, dry_run=args.dry_run):
                errors.append((nr_id, "conversão falhou"))
        except Exception as e:
            err_msg = str(e)
            logger.error(f"✗ {nr_id}: {err_msg}")
            errors.append((nr_id, err_msg))
            continue

    # Relatório final
    logger.info(f"\n{'='*60}")
    logger.info(f"Resumo: {len(nrs_to_process) - len(errors)}/{len(nrs_to_process)} OK")
    if errors:
        logger.error(f"Erros em {len(errors)} NR(s):")
        for nr_id, reason in errors:
            logger.error(f"  {nr_id}: {reason}")
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
