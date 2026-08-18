#!/usr/bin/env python3
"""
Conversão de PDF de NR para Markdown estruturado.

Executa 3 passes sempre (sem exceção, mesmo para NRs "simples"):
1. Pass texto: pymupdf4llm → corpo normativo em Markdown (por página)
2. Pass tabelas: pdfplumber → Markdown inline (ou PNG se ilegível)
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
import re
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


# ============================================================================
# Fase 2 — Funções auxiliares puras (testáveis)
# ============================================================================


def _table_to_markdown(table: list[list]) -> str:
    """
    Converte uma tabela (lista de listas) para Markdown.
    Escapa pipes literais dentro de células como \|.
    Retorna string com formato Markdown (cabeçalho + separador + linhas).
    """
    if not table:
        return ""

    # Cabeçalho: primeira linha
    header_row = table[0]
    header = "| " + " | ".join(str(cell or "").replace("|", "\\|") for cell in header_row) + " |"

    # Linha separadora: um --- por coluna
    sep_row = "| " + " | ".join("---" for _ in header_row) + " |"

    # Dados: demais linhas
    data_lines = []
    for row in table[1:]:
        line = "| " + " | ".join(str(cell or "").replace("|", "\\|") for cell in row) + " |"
        data_lines.append(line)

    return header + "\n" + sep_row + "\n" + "\n".join(data_lines)


def _is_probably_illegible(table: list[list]) -> bool:
    """
    Heurística para detectar tabelas com texto vertical quebrado (caractere a caractere).

    Uma célula é suspeita se:
    - Tem 3+ quebras de linha (\n)
    - E a maior "palavra" entre quebras tem 1–2 caracteres (sinal de char-by-char)

    Uma única célula muito suspeita (5+ quebras, todas com 1–2 chars) já basta pra
    marcar a tabela inteira como ilegível — esse padrão é raro o bastante (não
    acontece em texto tabular normal, mesmo em células curtas tipo "N"/"S") que
    não precisa de maioria: cabeçalhos verticais tipicamente corrompem só 1 célula
    entre dezenas de células de dados legítimas (caso real: NR-03 TABELA 3.4, onde
    1 de 144 células não-vazias vem com texto vertical quebrado).
    Como fallback, também conta como ilegível se >= 50% das células não-vazias
    (incluindo header) forem ao menos moderadamente suspeitas (3+ quebras).
    """
    suspicious_count = 0
    total_non_empty = 0

    for row in table:
        for cell in row:
            cell_text = str(cell or "").strip()
            if not cell_text:
                continue

            total_non_empty += 1

            lines = cell_text.split("\n")
            if len(lines) < 3:
                continue

            max_word_len = max((len(word.strip()) for word in lines if word.strip()), default=0)
            if max_word_len > 2:
                continue

            suspicious_count += 1
            if len(lines) >= 5:
                return True

    if total_non_empty == 0:
        return False

    return suspicious_count >= total_non_empty * 0.5


def _strip_duplicate_markdown_table(page_text: str) -> str:
    """
    Remove do texto da página qualquer bloco que já seja uma tentativa de tabela
    do Pass 1 (pymupdf4llm) — pra dar lugar à versão do Pass 2 (pdfplumber).

    Um "bloco de tabela" é 2+ linhas consecutivas que começam e terminam com "|"
    (com ou sem linha separadora `|---|` — tabelas malformadas, como as que saem
    de PDFs com cabeçalho rotacionado, às vezes nem têm separador). Um parágrafo
    comum não tem 2 linhas seguidas nesse formato, então o critério é conservador.
    """
    lines = page_text.split("\n")
    is_pipe_line = [bool(re.match(r"^\s*\|.*\|\s*$", line)) for line in lines]

    result_lines = []
    i = 0
    while i < len(lines):
        if is_pipe_line[i] and i + 1 < len(lines) and is_pipe_line[i + 1]:
            # início de um bloco de 2+ linhas em formato de tabela — pula o bloco inteiro
            while i < len(lines) and is_pipe_line[i]:
                i += 1
            continue
        result_lines.append(lines[i])
        i += 1

    return "\n".join(result_lines)


# ============================================================================
# Fase 1, 2 e 3 — Extração de passes
# ============================================================================


def download_pdf(pdf_url: str, nr_id: str, dry_run: bool = False) -> tuple[Path | None, str]:
    """
    Download do PDF (usado apenas quando convert_nr.py roda sozinho, sem
    PDF já baixado por update_nrs.py).

    Retorna (caminho_arquivo, pdf_hash) ou (None, "") se falhar.
    """
    logger.info(f"Baixando PDF de {nr_id} de {pdf_url}")

    if dry_run:
        nr_dir = ensure_content_dir(nr_id)
        pdf_file = nr_dir / f"{nr_id}.pdf"
        logger.info(f"[DRY-RUN] teria baixado para {pdf_file}")
        return None, ""

    try:
        resp = requests.get(pdf_url, timeout=30)
        resp.raise_for_status()
        return save_pdf(resp.content, nr_id)

    except Exception as e:
        logger.error(f"✗ Falha ao baixar PDF: {e}")
        return None, ""


def save_pdf(pdf_bytes: bytes, nr_id: str) -> tuple[Path, str]:
    """
    Grava bytes de PDF já obtidos (ex.: por update_nrs.py, evitando um
    segundo download) e calcula o hash.

    Retorna (caminho_arquivo, pdf_hash).
    """
    nr_dir = ensure_content_dir(nr_id)
    pdf_file = nr_dir / f"{nr_id}.pdf"

    pdf_hash = hashlib.sha256(pdf_bytes).hexdigest()
    pdf_file.write_bytes(pdf_bytes)
    logger.info(f"✓ PDF salvo ({len(pdf_bytes)} bytes, hash={pdf_hash[:16]}...)")

    return pdf_file, pdf_hash


def extract_text_pass(pdf_file: Path, nr_id: str) -> list[str]:
    """
    Pass 1: Extração de texto com pymupdf4llm, por página.

    Retorna lista de strings (uma por página).
    """
    logger.info(f"{nr_id}: Pass 1 — Extração de texto (por página)")

    try:
        # pymupdf4llm com page_chunks=True retorna lista de dicts com "text" por página
        chunks = pymupdf4llm.to_markdown(str(pdf_file), page_chunks=True)
        pages_text = [chunk.get("text", "") for chunk in chunks]
        total_chars = sum(len(p) for p in pages_text)
        logger.info(f"  {len(pages_text)} páginas, {total_chars} chars extraídos")
        return pages_text
    except Exception as e:
        logger.error(f"  Falha na pass de texto: {e}")
        return []


def extract_tables_pass(
    pdf_file: Path, nr_id: str, pages_text: list[str]
) -> dict[str, Any]:
    """
    Pass 2: Extração de tabelas com pdfplumber → Markdown inline.

    Recebe as páginas de texto do Pass 1 (pra fazer dedupe).
    Retorna dicionário com:
    - 'pages_text': lista de textos de página (com duplicatas de tabelas Markdown removidas)
    - 'tables_by_page': dict {page_num: [tabelas Markdown pronto, ou {'illegible_page': True}]}

    Filtra falso-positivos (tabelas de 1 coluna) e detecta ilegibilidade (texto vertical).
    """
    logger.info(f"{nr_id}: Pass 2 — Extração e normalização de tabelas")

    tables_by_page: dict[int, list[str | dict]] = {}
    pages_text_cleaned = list(pages_text)

    try:
        with pdfplumber.open(str(pdf_file)) as pdf:
            table_count = 0
            illegible_count = 0

            for page_num, page in enumerate(pdf.pages):
                tables = page.extract_tables()
                if not tables:
                    continue

                page_tables: list[str | dict] = []

                for table_idx, table in enumerate(tables):
                    # Filtro de falso-positivo: tabela de 1 coluna (caixa de texto com borda)
                    max_cols = max((len(row) for row in table), default=0)
                    if max_cols <= 1:
                        logger.debug(f"  Page {page_num + 1}: tabela {table_idx} descartada (1 coluna)")
                        continue

                    # Detecta ilegibilidade (texto vertical quebrado)
                    if _is_probably_illegible(table):
                        logger.debug(f"  Page {page_num + 1}: tabela {table_idx} marcada como ilegível")
                        page_tables.append({"illegible_page": True})
                        illegible_count += 1
                    else:
                        # Converte para Markdown
                        table_md = _table_to_markdown(table)
                        page_tables.append(table_md)
                        table_count += 1
                        logger.debug(f"  Page {page_num + 1}: tabela {table_idx} convertida para Markdown")

                if page_tables:
                    tables_by_page[page_num] = page_tables

                    # Remove duplicatas de tabelas Markdown já presentes no texto da página
                    if page_num < len(pages_text_cleaned):
                        pages_text_cleaned[page_num] = _strip_duplicate_markdown_table(
                            pages_text_cleaned[page_num]
                        )

        logger.info(f"  {table_count} tabelas Markdown + {illegible_count} ilegíveis extraídas")
        return {
            "pages_text": pages_text_cleaned,
            "tables_by_page": tables_by_page,
        }

    except Exception as e:
        logger.error(f"  Falha na pass de tabelas: {e}")
        return {
            "pages_text": pages_text,
            "tables_by_page": {},
        }


def _render_page_png(doc: fitz.Document, page_num: int, pages_dir: Path) -> Path:
    """
    Renderiza uma página específica como PNG com zoom 2x.

    page_num é 0-based (índice do fitz.open).
    Retorna caminho do arquivo PNG.
    """
    page = doc[page_num]
    pix = page.get_pixmap(matrix=fitz.Matrix(2, 2))
    img_file = pages_dir / f"page-{page_num + 1:03d}.png"
    pix.save(str(img_file))
    return img_file


def extract_images_pass(
    pdf_file: Path, nr_id: str, tables_by_page: dict[int, list[str | dict]]
) -> dict[str, Any]:
    """
    Pass 3: Identifica páginas que precisam de PNG (com imagem embutida ou tabela ilegível).

    Retorna dicionário com:
    - 'pages_to_render': set de índices de páginas (0-based) que precisam PNG
    - 'page_png_paths': dict vazio por enquanto (preenchido pelo merge após render)

    Tabelas ilegíveis da Fase 2 (Pass 2) são renderizadas junto com páginas
    que já tinham imagem embutida, evitando renderizar a mesma página duas vezes.
    """
    logger.info(f"{nr_id}: Pass 3 — Identificação de páginas para PNG")

    pages_with_images = set()
    pages_with_illegible_tables = set()

    # Páginas com tabelas ilegíveis (marcadas como {"illegible_page": True})
    for page_num, tables in tables_by_page.items():
        for item in tables:
            if isinstance(item, dict) and item.get("illegible_page"):
                pages_with_illegible_tables.add(page_num)
                break

    try:
        doc = fitz.open(str(pdf_file))

        # Páginas com imagem embutida
        for page_num, page in enumerate(doc):
            if page.get_images(full=True):
                pages_with_images.add(page_num)

        # União: páginas que precisam PNG são aquelas com imagem + aquelas com tabela ilegível
        pages_to_render = pages_with_images | pages_with_illegible_tables

        logger.info(
            f"  {len(pages_with_images)} com imagem + "
            f"{len(pages_with_illegible_tables)} com tabela ilegível = "
            f"{len(pages_to_render)} páginas para renderizar"
        )

        doc.close()

        return {
            "pages_to_render": pages_to_render,
            "page_png_paths": {},  # será preenchido no merge
        }

    except Exception as e:
        logger.error(f"  Falha ao identificar páginas para PNG: {e}")
        return {
            "pages_to_render": set(),
            "page_png_paths": {},
        }


def merge_passes(
    pdf_file: Path,
    nr_id: str,
    pages_text: list[str],
    tables_by_page: dict[int, list[str | dict]],
    pages_to_render: set[int],
) -> str:
    """
    Merge dos 3 passes em um único markdown.

    Concatena página por página:
    - Texto da página (Pass 1, já sem duplicatas de tabelas Markdown)
    - Tabelas da página (Pass 2, Markdown pronto ou PNG se ilegível)

    Renderiza PNGs sob demanda (tabelas ilegíveis + páginas com imagem embutida).
    """
    logger.info(f"{nr_id}: Merge dos 3 passes (inline por página)")

    pages_dir = ensure_assets_dir(nr_id, "pages")

    # Limpa PNGs de uma conversão anterior
    for old_png in pages_dir.glob("page-*.png"):
        old_png.unlink()

    # Renderiza páginas necessárias
    try:
        doc = fitz.open(str(pdf_file))
        for page_num in pages_to_render:
            if page_num < len(doc):
                _render_page_png(doc, page_num, pages_dir)
                logger.debug(f"  Page {page_num + 1} renderizada")
        doc.close()
    except Exception as e:
        logger.error(f"  Falha ao renderizar PNGs: {e}")

    # Concatena página por página
    merged_parts = []
    for page_num, page_text in enumerate(pages_text):
        merged_parts.append(page_text)

        # Adiciona tabelas/imagens desta página (se houver)
        if page_num in tables_by_page:
            for table_item in tables_by_page[page_num]:
                if isinstance(table_item, dict) and table_item.get("illegible_page"):
                    # Tabela ilegível → referencia a PNG
                    merged_parts.append(f"\n![Tabela da página {page_num + 1}](../assets/pages/page-{page_num + 1:03d}.png)\n")
                elif isinstance(table_item, str):
                    # Tabela Markdown pronto
                    merged_parts.append("\n" + table_item + "\n")

    return "\n".join(merged_parts)


def save_metadata(nr_id: str, pdf_hash: str, char_count: int) -> None:
    """Salva pdf_hash/char_count em content/nr-XX/meta.json, mesclando com
    o que já existir (ex.: campos de vigência gravados por scrape_vigencia.py)."""
    nr_dir = ensure_content_dir(nr_id)
    meta_file = nr_dir / "meta.json"

    existing = {}
    if meta_file.exists():
        try:
            existing = json.loads(meta_file.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            existing = {}

    merged = {
        **existing,
        "pdf_hash": pdf_hash,
        "char_count": char_count,
    }

    meta_file.write_text(json.dumps(merged, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def convert_nr(nr_id: str, dry_run: bool = False, pdf_bytes: bytes | None = None) -> bool:
    """
    Converte uma NR. Retorna True se sucesso.

    Se `pdf_bytes` for passado (ex.: já baixado por update_nrs.py ao
    detectar mudança), reaproveita em vez de baixar o PDF de novo.

    Executa 3 passes em sequência:
    1. Pass 1: extração de texto por página (pymupdf4llm)
    2. Pass 2: extração de tabelas (pdfplumber) com filtro e dedupe
    3. Pass 3: identificação de páginas pra PNG (imagem + tabelas ilegíveis)
    """
    logger.info(f"\n{'='*60}")
    logger.info(f"Convertendo {nr_id}")
    logger.info(f"{'='*60}")

    # Merge de dados (nr_index.json + nr_sources.json)
    nr_data = merge_nr_data(nr_id)
    pdf_url = nr_data.get("pdf_url")

    if not pdf_url:
        logger.error(f"{nr_id}: pdf_url não encontrada, abortando")
        return False

    if dry_run:
        logger.info(f"[DRY-RUN] {nr_id}: teria feito os 3 passes e merge")
        return True

    # 1. PDF: reaproveita bytes já baixados (por update_nrs.py) ou baixa agora
    if pdf_bytes is not None:
        pdf_file, pdf_hash = save_pdf(pdf_bytes, nr_id)
    else:
        pdf_file, pdf_hash = download_pdf(pdf_url, nr_id, dry_run=dry_run)

    if not pdf_file or not pdf_hash:
        logger.error(f"{nr_id}: não foi possível baixar/hashear PDF")
        return False

    # 2. Executar os 3 passes em sequência
    # Pass 1: texto por página
    pages_text = extract_text_pass(pdf_file, nr_id)
    if not pages_text:
        logger.error(f"{nr_id}: falha na extração de texto")
        return False

    # Pass 2: tabelas (recebe páginas do Pass 1)
    tables_result = extract_tables_pass(pdf_file, nr_id, pages_text)
    pages_text_cleaned = tables_result["pages_text"]
    tables_by_page = tables_result["tables_by_page"]

    # Pass 3: identificação de páginas pra PNG (recebe tabelas do Pass 2)
    images_result = extract_images_pass(pdf_file, nr_id, tables_by_page)
    pages_to_render = images_result["pages_to_render"]

    # 3. Merge e normalização
    merged_md = merge_passes(pdf_file, nr_id, pages_text_cleaned, tables_by_page, pages_to_render)
    normalized_md = normalize_markdown(merged_md)

    # 4. Salva resultado
    nr_dir = ensure_content_dir(nr_id)
    md_file = nr_dir / f"{nr_id}.md"
    md_file.write_text(normalized_md, encoding="utf-8")
    logger.info(f"✓ {nr_id}: markdown salvo ({len(normalized_md)} chars)")

    # 5. Metadados
    save_metadata(nr_id, pdf_hash, len(normalized_md))

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
