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
    """Colapsa quebras de linha dentro de célula (artefato comum do PDF)."""
    text = re.sub(r"\s+", " ", str(cell or "").replace("\n", " ")).strip()
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

    short_rows = sum(1 for ln in data_rows if ln.count("|") <= 3)
    return short_rows >= len(data_rows) * 0.4


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

                for table_idx, table_obj in enumerate(tables_found):
                    # Extrai dados da tabela
                    table = table_obj.extract()

                    # Filtro de falso-positivo: tabela de 1 coluna (caixa de texto com borda)
                    max_cols = max((len(row) for row in table), default=0)
                    if max_cols <= 1:
                        logger.debug(f"  Page {page_num + 1}: tabela {table_idx} descartada (1 coluna)")
                        continue

                    # Detecta ilegibilidade (texto vertical quebrado)
                    if _is_probably_illegible(table):
                        logger.debug(f"  Page {page_num + 1}: tabela {table_idx} marcada como ilegível")
                        # Captura bbox da tabela (tupla: x0, top, x1, bottom)
                        bbox = table_obj.bbox
                        page_tables.append({"illegible_page": True, "bbox": bbox})
                        illegible_count += 1
                    else:
                        table_md = _table_to_markdown(table)
                        if _markdown_table_is_fragmented(table_md):
                            logger.debug(
                                f"  Page {page_num + 1}: tabela {table_idx} "
                                "fragmentada → fallback PNG"
                            )
                            bbox = table_obj.bbox
                            page_tables.append({"illegible_page": True, "bbox": bbox})
                            illegible_count += 1
                        else:
                            page_tables.append(table_md)
                            table_count += 1
                            logger.debug(
                                f"  Page {page_num + 1}: tabela {table_idx} "
                                "convertida para Markdown"
                            )

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
) -> dict[int, list[dict]]:
    """
    Combina bboxes de imagem (fitz.Rect) e tabela ilegível (tupla pdfplumber) por página.

    Retorna dicionário:
    {page_num: [{"bbox": fitz.Rect, "kind": "image"|"table", "table_index": int (só pra tabela)}]}
    ordenado por y0.

    Normaliza ambos os formatos para fitz.Rect para renderização posterior.
    """
    combined = {}

    for page_num in set(images_by_page.keys()) | set(tables_by_page.keys()):
        items = []

        # Adiciona imagens (já são fitz.Rect)
        if page_num in images_by_page:
            for rect in images_by_page[page_num]:
                items.append({
                    "bbox": rect,
                    "kind": "image",
                })

        # Adiciona tabelas ilegíveis
        if page_num in tables_by_page:
            table_item_idx = 0  # índice da tabela ilegível dentro da página
            for table_data in tables_by_page[page_num]:
                if isinstance(table_data, dict) and table_data.get("illegible_page"):
                    bbox_tuple = table_data.get("bbox")
                    if bbox_tuple:
                        # Converte tupla (x0, top, x1, bottom) para fitz.Rect
                        x0, top, x1, bottom = bbox_tuple
                        rect = fitz.Rect(x0, top, x1, bottom)
                        items.append({
                            "bbox": rect,
                            "kind": "table",
                            "table_index": table_item_idx,
                        })
                    else:
                        logger.warning(f"  Page {page_num + 1}: tabela ilegível sem bbox capturado, pulando")
                    table_item_idx += 1

        # Ordena por y0 (topo do item)
        items.sort(key=lambda item: item["bbox"].y0)

        if items:
            combined[page_num] = items

    return combined


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

    # Combina e ordena bboxes de imagem + tabelas ilegíveis por página
    combined_items = _combine_and_sort_bboxes(images_by_page, tables_by_page)

    # Renderiza cada item (imagem ou tabela ilegível) com recorte de bbox
    try:
        doc = fitz.open(str(pdf_file))
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

    # Concatena página por página, adicionando tabelas Markdown + referências de imagem/tabela PNG
    merged_parts = []
    image_counters: dict[int, int] = {}  # contador de imagens por página
    table_counters: dict[int, int] = {}  # contador de tabelas ilegíveis por página

    for page_num, page_text in enumerate(pages_text):
        merged_parts.append(page_text)

        # Adiciona tabelas/imagens desta página (se houver)
        if page_num in combined_items:
            for item in combined_items[page_num]:
                bbox = item["bbox"]
                kind = item["kind"]

                if kind == "image":
                    # Contador de imagens por página
                    if page_num not in image_counters:
                        image_counters[page_num] = 0
                    img_idx = image_counters[page_num]
                    image_counters[page_num] += 1

                    merged_parts.append(
                        f"\n![Página {page_num + 1} — imagem {img_idx}](../assets/pages/page-{page_num + 1:03d}-image-{img_idx:02d}.png)\n"
                    )

                elif kind == "table":
                    # Contador de tabelas ilegíveis por página
                    if page_num not in table_counters:
                        table_counters[page_num] = 0
                    tbl_idx = table_counters[page_num]
                    table_counters[page_num] += 1

                    merged_parts.append(
                        f"\n![Tabela da página {page_num + 1}](../assets/pages/page-{page_num + 1:03d}-table-{tbl_idx:02d}.png)\n"
                    )

        # Adiciona tabelas Markdown pronto (não PNG) desta página
        if page_num in tables_by_page:
            for table_item in tables_by_page[page_num]:
                if isinstance(table_item, str):
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
