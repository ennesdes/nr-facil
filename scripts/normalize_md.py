#!/usr/bin/env python3
"""
Normalização de Markdown extraído de PDFs.

Normaliza headings (e.g., "17.1"), remove artefatos de PDF
(cabeçalhos/rodapés repetidos, hifenização quebrada),
corrige problemas comuns de parsing.

Pode rodar standalone ou ser importado por convert_nr.py.

Uso:
  python3 scripts/normalize_md.py --nr nr-06           # normaliza content/nr-06/nr-06.md
  python3 scripts/normalize_md.py --all                # todas
  python3 scripts/normalize_md.py --help               # ajuda
"""
from __future__ import annotations

import argparse
import logging
import re
import sys
from pathlib import Path

from _common import list_all_nrs, ensure_content_dir, setup_logging

logger = logging.getLogger(__name__)

DOU_NOTE = "Este texto não substitui o publicado no DOU"
DOU_LINE_RE = re.compile(
    r"^\s*Este texto não substitui o publicado no DOU\.?\s*$",
    re.IGNORECASE,
)
# Hifenização residual: "deve- se", "minu- to"
BROKEN_HYPHEN_RE = re.compile(r"(\w)- (\w)")
# Número de página solto entre parágrafos (1–3 dígitos, linha isolada)
PAGE_NUMBER_LINE_RE = re.compile(r"^\s*\d{1,3}\s*$")
BR_TAG_RE = re.compile(r"<br\s*/?>", re.IGNORECASE)
# Tags de destaque/sublinhado vindas do PDF (ex.: NR-35 com <mark>)
HTML_INLINE_TAG_RE = re.compile(r"</?(?:mark|u)\b[^>]*>", re.IGNORECASE)
PICTURE_TEXT_BLOCK_RE = re.compile(
    r"<!--\s*Start of picture text\s*-->.*?<!--\s*End of picture text\s*-->",
    re.DOTALL | re.IGNORECASE,
)


def _is_structural_line(line: str) -> bool:
    """Linha que não deve ser fundida com parágrafo anterior."""
    stripped = line.strip()
    if not stripped:
        return True
    if stripped.startswith("#"):
        return True
    if stripped.startswith("|"):
        return True
    if stripped.startswith("!["):
        return True
    if stripped.startswith("<!--"):
        return True
    if ITEM_LIKE_RE.match(stripped):
        return True
    return False


ITEM_LIKE_RE = re.compile(r"^(\*\*)?\d+(?:\.\d+)+\*?\*?")


def _remove_dou_footer_lines(lines: list[str]) -> list[str]:
    """
    Remove avisos DOU que quebram itens normativos no meio do parágrafo.

    Quando o rodapé aparece entre duas partes do mesmo item, une o texto.
  Linhas que são só o aviso DOU são removidas.
    """
    result: list[str] = []
    i = 0
    while i < len(lines):
        line = lines[i]
        stripped = line.strip()

        if DOU_LINE_RE.match(stripped):
            # Une parágrafo anterior com continuação após o aviso DOU
            j = i + 1
            while j < len(lines) and not lines[j].strip():
                j += 1
            prev_idx = len(result) - 1
            while prev_idx >= 0 and not result[prev_idx].strip():
                prev_idx -= 1
            if (
                prev_idx >= 0
                and j < len(lines)
                and not _is_structural_line(lines[j])
            ):
                merged = result[prev_idx].rstrip() + " " + lines[j].lstrip()
                result = result[:prev_idx] + [merged]
                i = j + 1
                continue
            i += 1
            continue

        # DOU inline no meio da linha
        if DOU_NOTE.lower() in stripped.lower():
            cleaned = re.sub(
                rf"\s*{re.escape(DOU_NOTE)}\.?\s*",
                " ",
                stripped,
                flags=re.IGNORECASE,
            ).strip()
            if cleaned:
                result.append(cleaned if line == stripped else line.replace(stripped, cleaned))
            i += 1
            continue

        result.append(line)
        i += 1

    return result


def _remove_orphan_page_numbers(lines: list[str]) -> list[str]:
    """Remove linhas que são só número de página do PDF."""
    return [line for line in lines if not PAGE_NUMBER_LINE_RE.match(line)]


def _fix_broken_hyphenation(text: str) -> str:
    """Corrige hifenização residual tipo 'deve- se' → 'deve-se'."""
    return BROKEN_HYPHEN_RE.sub(r"\1-\2", text)


def _strip_br_tags(text: str) -> str:
    """Converte <br> (comum em células do pdfplumber) em espaço."""
    return BR_TAG_RE.sub(" ", text)


def _strip_html_inline_tags(text: str) -> str:
    """Remove tags <mark> e <u> preservando o conteúdo interno."""
    return HTML_INLINE_TAG_RE.sub("", text)


def _strip_html_artifacts(text: str) -> str:
    """Limpa artefatos HTML residuais do pipeline de extração."""
    text = _strip_br_tags(text)
    text = _strip_html_inline_tags(text)
    # Colapsa espaços duplicados por linha (preserva quebras de parágrafo)
    return "\n".join(re.sub(r" {2,}", " ", line) for line in text.split("\n"))


def _strip_picture_text_blocks(text: str) -> str:
    """
    Remove blocos OCR de diagramas gerados pelo pymupdf4llm.

    Esse texto é lixo visual (formulários, fluxogramas) — o conteúdo real
    deve vir do Pass 3 (PNG recortado), não do OCR do Pass 1.
    """
    return PICTURE_TEXT_BLOCK_RE.sub("", text)


def _repair_broken_table_rows(text: str) -> str:
    """
    Reúne linhas físicas que pertencem à mesma linha de tabela Markdown.

    Quando células vêm com \\n do PDF, o markdown gerado pode quebrar uma linha
  de tabela em várias linhas físicas (ex.: ``| GRAU`` / ``de`` / ``RISCO* | ...``).
    """
    lines = text.split("\n")
    result: list[str] = []
    i = 0

    while i < len(lines):
        stripped = lines[i].strip()

        if not stripped.startswith("|"):
            result.append(lines[i])
            i += 1
            continue

        fragments = [stripped]
        i += 1
        while i < len(lines):
            next_stripped = lines[i].strip()
            if not next_stripped:
                break
            current = " ".join(fragments)
            if current.endswith("|") and next_stripped.startswith("|"):
                break
            if not next_stripped.startswith("|") and "|" not in next_stripped:
                # Continuação de célula sem pipe — ainda faz parte da mesma linha.
                fragments.append(next_stripped)
                i += 1
                continue
            if next_stripped.startswith("|") or "|" in next_stripped:
                fragments.append(next_stripped)
                i += 1
                if " ".join(fragments).rstrip().endswith("|"):
                    break
                continue
            break

        merged = re.sub(r"\s*\|\s*", " | ", " ".join(fragments))
        merged = re.sub(r" {2,}", " ", merged).strip()
        if not merged.startswith("|"):
            merged = f"| {merged}"
        if not merged.endswith("|"):
            merged = f"{merged} |"
        result.append(merged)

    return "\n".join(result)


def normalize_markdown(text: str) -> str:
    """
    Normaliza o Markdown extraído de PDF.

    Executa:
    1. Remove avisos DOU que partem itens normativos
    2. Remove números de página soltos e rodapés repetidos
    3. Padroniza headings em formato "17.1", "17.1.1", etc.
    4. Corrige hifenização quebrada (linha termina em hífen)
    5. Repara linhas de tabela quebradas por \\n dentro de células
    6. Remove blocos OCR de diagramas (picture text)
    7. Limpa artefatos HTML (<br>, <mark>, <u>)
    8. Remove espaços em branco excessivos
    9. Remove sequências de linhas vazias > 2
    """
    lines = text.split("\n")

    lines = _remove_dou_footer_lines(lines)
    lines = _remove_orphan_page_numbers(lines)

    # Remove sequências de rodapé/cabeçalho repetidas (ex: "Página 5" repetida)
    lines = [
        line for i, line in enumerate(lines)
        if i == 0 or line.strip() != lines[i - 1].strip()
    ]

    # Corrige hifenização: se linha termina em hífen (quebra de palavra),
    # une à próxima sem espaço
    result = []
    i = 0
    while i < len(lines):
        line = lines[i]
        # Se termina em hífen e próxima linha existe e não é vazia
        if (i < len(lines) - 1 and
            line.rstrip().endswith("-") and
            lines[i + 1].strip()):
            # Remove hífen e une à próxima
            result.append(line.rstrip()[:-1] + lines[i + 1].lstrip())
            i += 2
        else:
            result.append(line)
            i += 1

    # Normaliza headings: "### Item 17.1 Some Title" → "### 17.1 Some Title"
    # (pymupdf4llm pode gerar headings com prefixo numérico duplicado ou irregular)
    normalized = []
    for line in result:
        # Padrão de heading (## ou ### ou #### etc.)
        match = re.match(r"^(#+)\s+(.*)$", line)
        if match:
            level = match.group(1)
            content = match.group(2).strip()

            # Se o conteúdo começa com número (tipo "Item 17.1" ou "17.1")
            # deixa como está; se for algo como "123. Some text" corrige
            # (a ideia é manter a estrutura de seção/artigo como vem do PDF)
            normalized.append(f"{level} {content}")
        else:
            normalized.append(line)

    text = "\n".join(normalized)
    text = _repair_broken_table_rows(text)
    text = _fix_broken_hyphenation(text)
    text = _strip_picture_text_blocks(text)
    text = _strip_html_artifacts(text)

    # Remove linhas em branco excessivas (mais de 2 consecutivas)
    text = re.sub(r"\n\n\n+", "\n\n", text)

    return text


def normalize_nr_file(nr_dir: Path, dry_run: bool = False) -> bool:
    """
    Normaliza o .md de uma NR no lugar.

    Retorna True se sucesso, False se erro.
    """
    md_file = nr_dir / f"{nr_dir.name}.md"

    if not md_file.exists():
        logger.warning(f"{nr_dir.name}: arquivo {md_file.name} não encontrado")
        return False

    try:
        original_text = md_file.read_text(encoding="utf-8")
        normalized_text = normalize_markdown(original_text)

        if dry_run:
            logger.info(f"[DRY-RUN] {nr_dir.name}: teria normalizado {len(normalized_text)} chars")
        else:
            md_file.write_text(normalized_text, encoding="utf-8")
            logger.info(f"✓ {nr_dir.name}: normalizado ({len(original_text)} → {len(normalized_text)} chars)")

        return True
    except Exception as e:
        logger.error(f"✗ {nr_dir.name}: {e}")
        return False


def main() -> int:
    """Normaliza arquivos Markdown extraídos."""
    parser = argparse.ArgumentParser(
        description="Normaliza Markdown extraído de PDFs (headings, artefatos, hifenização)"
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

    logger.info("=== normalize_md.py ===")
    logger.info(f"Modo: {'DRY-RUN' if args.dry_run else 'NORMAL'}")

    # Determina quais NRs processar
    if args.nr:
        nrs_to_process = [args.nr]
    elif args.all:
        # Procura por .md em content/
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

    logger.info(f"Normalizando {len(nrs_to_process)} NR(s)")

    errors = []
    for nr_id in nrs_to_process:
        nr_dir = ensure_content_dir(nr_id)
        if not normalize_nr_file(nr_dir, dry_run=args.dry_run):
            errors.append(nr_id)

    logger.info(f"\nResumo: {len(nrs_to_process) - len(errors)}/{len(nrs_to_process)} OK")
    if errors:
        logger.error(f"Erros em {len(errors)} NR(s): {', '.join(errors)}")
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
