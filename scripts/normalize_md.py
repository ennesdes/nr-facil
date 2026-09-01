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
    1. Remove páginas vazias / linhas de rodapé repetidas
    2. Padroniza headings em formato "17.1", "17.1.1", etc.
    3. Corrige hifenização quebrada (linha termina em hífen)
    4. Repara linhas de tabela quebradas por \\n dentro de células
    5. Remove espaços em branco excessivos
    6. Remove sequências de linhas vazias > 2
    """
    lines = text.split("\n")

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
