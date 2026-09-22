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


def _normalize_table_cell(cell) -> str:
    """Colapsa quebras de linha e tags HTML dentro de célula."""
    text = str(cell or "")
    text = re.sub(r"<br\s*/?>", " ", text, flags=re.IGNORECASE)
    text = re.sub(r"</?(?:mark|u)\b[^>]*>", "", text, flags=re.IGNORECASE)
    text = re.sub(r"\s+", " ", text.replace("\n", " ")).strip()
    return text.replace("|", "\\|")


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
    header = "| " + " | ".join(_normalize_table_cell(cell) for cell in header_row) + " |"

    # Linha separadora: um --- por coluna
    sep_row = "| " + " | ".join("---" for _ in header_row) + " |"

    # Dados: demais linhas
    data_lines = []
    for row in table[1:]:
        line = "| " + " | ".join(_normalize_table_cell(cell) for cell in row) + " |"
        data_lines.append(line)

    return header + "\n" + sep_row + "\n" + "\n".join(data_lines)


def _row_has_merged_cell_artifact(cells: list[str]) -> bool:
    """
    Detecta linha com célula mesclada mal extraída do PDF.

    Padrões:
    - Grade larga (8+ colunas) com 1–2 células preenchidas e o resto vazio
      (caso real: NR-05 Quadro I — cabeçalho "NÚMERO DE EMPREGADOS..." + 15 vazias)
    - Mesmo texto repetido em metade+ das colunas (Pass 1 duplicando cabeçalho mesclado)
    """
    if len(cells) < 8:
        return False

    non_empty = [c for c in cells if c]
    empty = len(cells) - len(non_empty)
    if len(non_empty) <= 2 and empty >= 6:
        return True

    if len(non_empty) >= 4:
        unique = set(non_empty)
        if len(unique) == 1 and len(non_empty) >= len(cells) * 0.5:
            return True

    return False


def _table_has_merged_cell_artifact(table: list[list]) -> bool:
    """True se qualquer linha da tabela tem artefato de célula mesclada."""
    for row in table:
        cells = [str(cell or "").strip() for cell in row]
        if _row_has_merged_cell_artifact(cells):
            return True
    return False


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
    if _table_has_merged_cell_artifact(table):
        return True

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

    if suspicious_count >= total_non_empty * 0.5:
        return True

    # Matrizes esparsas (ex.: NR-03) — muitas células vazias em grade larga
    total_cells = sum(len(row) for row in table)
    if total_cells == 0:
        return False
    empty_cells = sum(
        1 for row in table for cell in row if not str(cell or "").strip()
    )
    max_cols = max((len(row) for row in table), default=0)
    if max_cols >= 5 and empty_cells / total_cells >= 0.35:
        return True

    return False


def _markdown_table_is_fragmented(table_md: str) -> bool:
    """Detecta tabela Markdown gerada com células espalhadas/quebradas."""
    lines = [ln.strip() for ln in table_md.splitlines() if ln.strip()]
    if len(lines) < 3:
        return False

    data_rows = [ln for ln in lines if ln.startswith("|") and "---" not in ln]
    if len(data_rows) < 2:
        return False

    for ln in data_rows:
        cells = [c.strip() for c in ln.strip("|").split("|")]
        if _row_has_merged_cell_artifact(cells):
            return True

    # Linhas com no máximo 1 coluna (| x |) indicam fragmentação
    short_rows = sum(1 for ln in data_rows if ln.count("|") <= 2)
    if short_rows >= len(data_rows) * 0.4:
        return True

    # Grade esparsa: muitas células vazias no markdown gerado
    total_cells = 0
    empty_cells = 0
    for ln in data_rows:
        cells = [c.strip() for c in ln.strip("|").split("|")]
        for cell in cells:
            total_cells += 1
            if not cell:
                empty_cells += 1
    if total_cells > 0 and empty_cells / total_cells >= 0.35:
        return True

    return False


# Tabelas largas ou muito longas → PNG (evita centenas de MarkdownBody no app).
TABLE_PNG_MIN_DATA_ROWS = 18
TABLE_PNG_MIN_COLS = 6


def _table_data_row_count(table: list[list]) -> int:
    return max(0, len(table) - 1)


def _table_max_cols(table: list[list]) -> int:
    return max((len(row) for row in table), default=0)


def _table_is_large_for_png(table: list[list]) -> bool:
    return (
        _table_max_cols(table) >= TABLE_PNG_MIN_COLS
        or _table_data_row_count(table) >= TABLE_PNG_MIN_DATA_ROWS
    )


def _should_render_table_as_png(table: list[list], table_md: str) -> bool:
    """Decide se uma tabela isolada na página deve virar PNG recortado."""
    if _is_probably_illegible(table):
        return True
    if _markdown_table_is_fragmented(table_md):
        return True
    if _table_is_large_for_png(table):
        return True
    return False


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
    - 'tables_by_page': dict {page_num: [tabelas Markdown pronto, ou {'illegible_page': True, 'bbox': (x0, y0, x1, y1)}]}

    Filtra falso-positivos (tabelas de 1 coluna) e detecta ilegibilidade (texto vertical).
    Fase 1: Captura bbox de tabela ilegível usando pdfplumber.page.find_tables().
    """
    logger.info(f"{nr_id}: Pass 2 — Extração e normalização de tabelas")

    tables_by_page: dict[int, list[str | dict]] = {}
    pages_text_cleaned = list(pages_text)
    nr_data = merge_nr_data(nr_id)
    force_all_tables_png = nr_data.get("table_mode") == "png"

    try:
        with pdfplumber.open(str(pdf_file)) as pdf:
            table_count = 0
            illegible_count = 0

            for page_num, page in enumerate(pdf.pages):
                # find_tables() retorna objetos com .bbox e .extract()
                tables_found = page.find_tables()
                if not tables_found:
                    continue

                page_tables: list[str | dict] = []
                valid_tables: list[tuple[Any, list[list]]] = []

                for table_idx, table_obj in enumerate(tables_found):
                    table = table_obj.extract()
                    if _table_max_cols(table) <= 1:
                        logger.debug(
                            f"  Page {page_num + 1}: tabela {table_idx} descartada (1 coluna)"
                        )
                        continue
                    valid_tables.append((table_obj, table))

                if not valid_tables:
                    continue

                prefer_png_page = force_all_tables_png or len(valid_tables) >= 2
                use_full_page_png = False
                markdown_tables: list[str] = []
                png_table_markdown: list[str] = []

                for table_idx, (table_obj, table) in enumerate(valid_tables):
                    table_md = _table_to_markdown(table)
                    if prefer_png_page:
                        use_full_page_png = True
                        png_table_markdown.append(table_md)
                        continue

                    if _should_render_table_as_png(table, table_md):
                        logger.debug(
                            f"  Page {page_num + 1}: tabela {table_idx} → PNG página inteira"
                        )
                        use_full_page_png = True
                        png_table_markdown.append(table_md)
                    else:
                        markdown_tables.append(table_md)
                        table_count += 1
                        logger.debug(
                            f"  Page {page_num + 1}: tabela {table_idx} "
                            "convertida para Markdown"
                        )

                if use_full_page_png:
                    reason = "table_mode=png" if force_all_tables_png else "multi_table_page"
                    if not prefer_png_page:
                        reason = "table_png_fallback"
                    logger.debug(
                        f"  Page {page_num + 1}: tabela(s) → PNG página inteira ({reason})"
                    )
                    page_tables.append(
                        {
                            "full_page_table": True,
                            "search_text": _markdown_tables_to_search_text(
                                png_table_markdown
                            ),
                        }
                    )
                    illegible_count += 1
                else:
                    page_tables.extend(markdown_tables)

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


def _combine_and_sort_bboxes(
    images_by_page: dict[int, list[fitz.Rect]],
    tables_by_page: dict[int, list[str | dict]],
    *,
    full_table_pages: set[int] | None = None,
) -> dict[int, list[dict]]:
    """
    Combina bboxes de imagem (fitz.Rect) e tabela ilegível (tupla pdfplumber) por página.

    Retorna dicionário:
    {page_num: [{"bbox": fitz.Rect, "kind": "image"|"table", "table_index": int (só pra tabela)}]}
    ordenado por y0.

    Normaliza ambos os formatos para fitz.Rect para renderização posterior.
    """
    combined = {}
    skip_pages = full_table_pages or set()

    for page_num in set(images_by_page.keys()) | set(tables_by_page.keys()):
        if page_num in skip_pages:
            continue

        items = []

        # Adiciona imagens (já são fitz.Rect)
        if page_num in images_by_page:
            for rect in images_by_page[page_num]:
                items.append({
                    "bbox": rect,
                    "kind": "image",
                })

        # Adiciona tabelas ilegíveis (recorte por bbox — legado / tabela isolada)
        if page_num in tables_by_page:
            table_item_idx = 0
            for table_data in tables_by_page[page_num]:
                if isinstance(table_data, dict) and table_data.get("full_page_table"):
                    continue
                if isinstance(table_data, dict) and table_data.get("illegible_page"):
                    bbox_tuple = table_data.get("bbox")
                    if bbox_tuple:
                        x0, top, x1, bottom = bbox_tuple
                        rect = fitz.Rect(x0, top, x1, bottom)
                        items.append({
                            "bbox": rect,
                            "kind": "table",
                            "table_index": table_item_idx,
                        })
                    else:
                        logger.warning(
                            f"  Page {page_num + 1}: tabela ilegível sem bbox capturado, pulando"
                        )
                    table_item_idx += 1

        # Ordena por y0 (topo do item)
        items.sort(key=lambda item: item["bbox"].y0)

        if items:
            combined[page_num] = items

    return combined


def _page_has_full_table_png(tables_by_page: dict[int, list[str | dict]], page_num: int) -> bool:
    tables = tables_by_page.get(page_num) or []
    return any(isinstance(item, dict) and item.get("full_page_table") for item in tables)


def _full_table_pages(tables_by_page: dict[int, list[str | dict]]) -> set[int]:
    return {
        page_num
        for page_num, tables in tables_by_page.items()
        if any(isinstance(item, dict) and item.get("full_page_table") for item in tables)
    }


def _render_full_page_table_png(
    doc: fitz.Document, page_num: int, pages_dir: Path
) -> Path:
    """Renderiza a página inteira como PNG (tabelas densas — uma folha por vez no app)."""
    page = doc[page_num]
    pix = page.get_pixmap(matrix=fitz.Matrix(2, 2))
    img_file = pages_dir / f"page-{page_num + 1:03d}-table-full.png"
    pix.save(str(img_file))
    return img_file


def _render_bbox_png(doc: fitz.Document, page_num: int, bbox: fitz.Rect, pages_dir: Path, kind: str, idx: int) -> Path:
    """
    Renderiza um recorte de página (bbox) como PNG com zoom 2x.

    page_num é 0-based (índice do fitz.open).
    bbox é fitz.Rect com as coordenadas do recorte.
    kind é "image" ou "table".
    idx é o índice dentro do tipo (0 para primeira imagem, etc).
    Retorna caminho do arquivo PNG.
    """
    page = doc[page_num]
    # Renderiza só a área do bbox com matriz de zoom 2x
    pix = page.get_pixmap(clip=bbox, matrix=fitz.Matrix(2, 2))
    img_file = pages_dir / f"page-{page_num + 1:03d}-{kind}-{idx:02d}.png"
    pix.save(str(img_file))
    return img_file


def extract_images_pass(
    pdf_file: Path, nr_id: str, tables_by_page: dict[int, list[str | dict]]
) -> dict[str, Any]:
    """
    Pass 3: Extrai bboxes de imagens embutidas e identifica páginas com tabelas ilegíveis.

    Retorna dicionário com:
    - 'images_by_page': dict {page_num: [fitz.Rect]} — lista de bboxes de imagem por página, ordenados por y0
    - 'pages_with_illegible_tables': set de page_num com tabelas ilegíveis

    Fase 1: Captura os bboxes de imagem para recorte de PNG (não mais página inteira).
    """
    logger.info(f"{nr_id}: Pass 3 — Extração de bboxes de imagem")

    images_by_page: dict[int, list[fitz.Rect]] = {}
    pages_with_illegible_tables = set()

    # Páginas com tabelas ilegíveis (marcadas como {"illegible_page": True})
    for page_num, tables in tables_by_page.items():
        for item in tables:
            if isinstance(item, dict) and item.get("illegible_page"):
                pages_with_illegible_tables.add(page_num)
                break

    try:
        doc = fitz.open(str(pdf_file))

        # Extrai bboxes de imagem embutida por página
        for page_num, page in enumerate(doc):
            xref_list = page.get_images(full=True)
            if not xref_list:
                continue

            page_image_rects: list[fitz.Rect] = []

            for xref in xref_list:
                xref_num = xref[0]
                rects = page.get_image_rects(xref_num)

                if not rects:
                    logger.debug(f"  Page {page_num + 1}: imagem com xref {xref_num} não tem rects, pulando")
                    continue

                for rect in rects:
                    page_image_rects.append(rect)
                    logger.debug(f"  Page {page_num + 1}: bbox de imagem capturado {rect}")

            # Ordena por y0 (topo da imagem)
            page_image_rects.sort(key=lambda r: r.y0)

            if page_image_rects:
                images_by_page[page_num] = page_image_rects

        logger.info(
            f"  {sum(len(rects) for rects in images_by_page.values())} bboxes de imagem + "
            f"{len(pages_with_illegible_tables)} páginas com tabela ilegível"
        )

        doc.close()

        return {
            "images_by_page": images_by_page,
            "pages_with_illegible_tables": pages_with_illegible_tables,
        }

    except Exception as e:
        logger.error(f"  Falha ao extrair bboxes de imagem: {e}")
        return {
            "images_by_page": {},
            "pages_with_illegible_tables": pages_with_illegible_tables,
        }


def merge_passes(
    pdf_file: Path,
    nr_id: str,
    pages_text: list[str],
    tables_by_page: dict[int, list[str | dict]],
    images_by_page: dict[int, list[fitz.Rect]],
) -> str:
    """
    Merge dos 3 passes em um único markdown.

    Concatena página por página:
    - Texto da página (Pass 1, já sem duplicatas de tabelas Markdown)
    - Tabelas Markdown pronto (Pass 2)
    - Imagens/tabelas ilegíveis como PNGs recortados (Fase 2: bboxes unificados, ordenados por Y)

    Renderiza PNGs sob demanda (tabelas ilegíveis + imagens embutidas) com recorte por bbox.
    """
    logger.info(f"{nr_id}: Merge dos 3 passes (inline por página, com recorte por bbox)")

    pages_dir = ensure_assets_dir(nr_id, "pages")

    # Limpa PNGs de uma conversão anterior (inclui novos nomes com -image-, -table-)
    for old_png in pages_dir.glob("page-*.png"):
        old_png.unlink()

    full_table_pages = _full_table_pages(tables_by_page)

    # Combina bboxes (páginas com PNG de página inteira não geram recortes extras)
    combined_items = _combine_and_sort_bboxes(
        images_by_page, tables_by_page, full_table_pages=full_table_pages
    )

    try:
        doc = fitz.open(str(pdf_file))
        for page_num in sorted(full_table_pages):
            if page_num >= len(doc):
                logger.warning(f"  Page {page_num + 1} fora dos limites do PDF, pulando")
                continue
            try:
                _render_full_page_table_png(doc, page_num, pages_dir)
                logger.debug(f"  Page {page_num + 1}: PNG página inteira (tabelas)")
            except Exception as e:
                logger.error(f"  Falha ao renderizar página inteira {page_num + 1}: {e}")

        for page_num, items in combined_items.items():
            if page_num >= len(doc):
                logger.warning(f"  Page {page_num + 1} fora dos limites do PDF, pulando")
                continue

            for idx, item in enumerate(items):
                bbox = item["bbox"]
                kind = item["kind"]
                try:
                    _render_bbox_png(doc, page_num, bbox, pages_dir, kind, idx)
                    logger.debug(f"  Page {page_num + 1} {kind} {idx} renderizado (bbox)")
                except Exception as e:
                    logger.error(f"  Falha ao renderizar Page {page_num + 1} {kind} {idx}: {e}")

        doc.close()
    except Exception as e:
        logger.error(f"  Falha ao renderizar PNGs: {e}")

    merged_parts = []
    image_counters: dict[int, int] = {}
    table_counters: dict[int, int] = {}

    for page_num, page_text in enumerate(pages_text):
        merged_parts.append(page_text)

        if page_num in full_table_pages:
            merged_parts.append(
                f"\n![Página {page_num + 1} (tabelas)](../assets/pages/page-{page_num + 1:03d}-table-full.png)\n"
            )

        if page_num in combined_items:
            for item in combined_items[page_num]:
                kind = item["kind"]

                if kind == "image":
                    if page_num not in image_counters:
                        image_counters[page_num] = 0
                    img_idx = image_counters[page_num]
                    image_counters[page_num] += 1

                    merged_parts.append(
                        f"\n![Página {page_num + 1} — imagem {img_idx}](../assets/pages/page-{page_num + 1:03d}-image-{img_idx:02d}.png)\n"
                    )

                elif kind == "table":
                    if page_num not in table_counters:
                        table_counters[page_num] = 0
                    tbl_idx = table_counters[page_num]
                    table_counters[page_num] += 1

                    merged_parts.append(
                        f"\n![Tabela da página {page_num + 1}](../assets/pages/page-{page_num + 1:03d}-table-{tbl_idx:02d}.png)\n"
                    )

        if page_num in tables_by_page:
            for table_item in tables_by_page[page_num]:
                if isinstance(table_item, str):
                    merged_parts.append("\n" + table_item + "\n")

    return "\n".join(merged_parts)


PAGE_TABLE_FULL_MD_RE = re.compile(
    r"!\[[^\]]*\]\(\.\./assets/pages/page-(\d{3})-table-full\.png\)"
)

PNG_TABLE_IMAGE_MD_RE = re.compile(
    r"!\[[^\]]*\]\((\.\./assets/pages/page-(\d{3})-table(?:-full|-\d{2})\.png)\)"
)


def _markdown_table_to_plain_search(table_md: str) -> str:
    """Texto plano derivado do Markdown de tabela — usado só na busca."""
    lines: list[str] = []
    for line in table_md.split("\n"):
        stripped = line.strip()
        if not stripped:
            continue
        if "|" in stripped and re.match(r"^\|?[\s\-:|]+\|?$", stripped):
            continue
        lines.append(stripped.replace("|", " "))
    return re.sub(r"\s+", " ", " ".join(lines)).strip()


def _markdown_tables_to_search_text(table_markdowns: list[str]) -> str:
    parts = [
        _markdown_table_to_plain_search(md)
        for md in table_markdowns
        if md and md.strip()
    ]
    return "\n\n".join(parts).strip()


def extract_pdf_page_search_text(pdf_file: Path, page_num: int) -> str:
    """Texto da camada do PDF + células de tabela — só para busca, não exibido no leitor."""
    parts: list[str] = []

    try:
        doc = fitz.open(str(pdf_file))
        if 0 <= page_num < len(doc):
            parts.append(doc[page_num].get_text("text") or "")
        doc.close()
    except Exception as e:
        logger.debug(f"  Page {page_num + 1}: get_text para busca falhou: {e}")

    try:
        with pdfplumber.open(str(pdf_file)) as pdf:
            if 0 <= page_num < len(pdf.pages):
                page = pdf.pages[page_num]
                for table_obj in page.find_tables():
                    table = table_obj.extract() or []
                    for row in table:
                        for cell in row:
                            if cell:
                                parts.append(_normalize_table_cell(cell))
    except Exception as e:
        logger.debug(f"  Page {page_num + 1}: pdfplumber para busca falhou: {e}")

    text = " ".join(parts)
    return re.sub(r"\s+", " ", text).strip()


def build_image_search_index(
    md_text: str,
    tables_by_page: dict[int, list[str | dict]],
    pdf_file: Path,
) -> dict[str, Any]:
    """
    Índice de busca para tabelas renderizadas como PNG.

    Prioriza o texto já extraído na pass de tabelas (Markdown); PDF só como fallback.
    """
    images: dict[str, dict[str, Any]] = {}

    for page_num, items in tables_by_page.items():
        for item in items:
            if not isinstance(item, dict) or not item.get("full_page_table"):
                continue
            page_1based = page_num + 1
            src = f"../assets/pages/page-{page_1based:03d}-table-full.png"
            search_text = (item.get("search_text") or "").strip()
            if not search_text:
                search_text = extract_pdf_page_search_text(pdf_file, page_num)
            images[src] = {"search_text": search_text, "page": page_1based}

    for match in PNG_TABLE_IMAGE_MD_RE.finditer(md_text):
        src = match.group(1)
        if src in images:
            continue
        page_1based = int(match.group(2))
        images[src] = {
            "search_text": extract_pdf_page_search_text(pdf_file, page_1based - 1),
            "page": page_1based,
        }

    return {"images": images}


def save_image_search_index(nr_id: str, image_search: dict[str, Any]) -> None:
    nr_dir = ensure_content_dir(nr_id)
    out = nr_dir / "image_search.json"
    out.write_text(
        json.dumps(image_search, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )


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
    2. Pass 2: extração de tabelas (pdfplumber) com filtro, dedupe, e captura de bbox de tabela ilegível
    3. Pass 3: extração de bboxes de imagem embutida (pymupdf)
    Depois merge unificado com recorte de bbox (Fase 2) para imagens e tabelas ilegíveis.
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

    # Pass 3: extração de bboxes de imagem (recebe tabelas do Pass 2 para identificar páginas)
    images_result = extract_images_pass(pdf_file, nr_id, tables_by_page)
    images_by_page = images_result["images_by_page"]

    # 3. Merge e normalização (Fase 2: usa bboxes de imagem para recorte)
    merged_md = merge_passes(pdf_file, nr_id, pages_text_cleaned, tables_by_page, images_by_page)
    normalized_md = normalize_markdown(merged_md)

    # 4. Salva resultado
    nr_dir = ensure_content_dir(nr_id)
    md_file = nr_dir / f"{nr_id}.md"
    md_file.write_text(normalized_md, encoding="utf-8")
    logger.info(f"✓ {nr_id}: markdown salvo ({len(normalized_md)} chars)")

    image_search = build_image_search_index(
        normalized_md, tables_by_page, pdf_file
    )
    save_image_search_index(nr_id, image_search)
    logger.info(
        f"  image_search.json: {len(image_search.get('images', {}))} imagem(ns) indexadas"
    )

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
