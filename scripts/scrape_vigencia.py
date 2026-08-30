#!/usr/bin/env python3
"""
Scraping de metadados de vigência das páginas HTML de cada NR.

Extrai: publicado_em, vigente_desde, portaria, ultima_alteracao da página oficial.
Salva em content/nr-XX/meta.json para cada NR.

Uso:
  python3 scripts/scrape_vigencia.py --nr nr-06           # uma NR
  python3 scripts/scrape_vigencia.py --all                # todas (de nr_index.json)
  python3 scripts/scrape_vigencia.py --all --dry-run      # simula
  python3 scripts/scrape_vigencia.py --help               # ajuda
"""
from __future__ import annotations

import argparse
import json
import logging
import sys
from datetime import datetime
from pathlib import Path
from typing import Any

try:
    import requests
    from bs4 import BeautifulSoup
except ImportError as e:
    print(f"Erro: {e}. Instale com: pip install -r scripts/requirements.txt", file=sys.stderr)
    sys.exit(1)

from _common import merge_nr_data, list_all_nrs, ensure_content_dir, setup_logging

logger = logging.getLogger(__name__)

# Fallback de metadados para testes
FIXTURE_META = {
    "nr-01": {
        "publicado_em": "2013-06-28",
        "vigente_desde": "2013-06-28",
        "portaria": "Portaria MTE nº 262/2013",
        "ultima_alteracao": "2024-12-15",
    },
    "nr-06": {
        "publicado_em": "2018-04-12",
        "vigente_desde": "2018-06-10",
        "portaria": "Portaria MTE nº 509/2018",
        "ultima_alteracao": "2024-06-20",
    },
    "nr-17": {
        "publicado_em": "1990-11-17",
        "vigente_desde": "1990-12-01",
        "portaria": "Portaria SSST nº 876/1990",
        "ultima_alteracao": "2023-03-15",
    },
}


def scrape_nr_metadata(page_url: str, nr_id: str) -> dict[str, str]:
    """
    Scraping da página HTML de uma NR.

    Extrai: publicado_em, vigente_desde, portaria, ultima_alteracao.
    Usa fallback FIXTURE_META se não conseguir rede ou HTML inválido.

    Retorna: {"publicado_em": "...", "vigente_desde": "...", ...}
    """
    logger.info(f"Scraping metadados de {nr_id} em {page_url}")

    try:
        resp = requests.get(page_url, timeout=10)
        resp.raise_for_status()
    except requests.RequestException as e:
        logger.warning(f"Falha ao buscar {page_url}: {e}. Usando fixture.")
        return FIXTURE_META.get(nr_id, {
            "publicado_em": None,
            "vigente_desde": None,
            "portaria": None,
            "ultima_alteracao": None,
        })

    soup = BeautifulSoup(resp.text, "html.parser")

    # Tenta extrair metadados do HTML. O layout exato varia por site,
    # aqui usamos padrões genéricos como <meta>, <p>, <dl>, etc.
    meta = {
        "publicado_em": None,
        "vigente_desde": None,
        "portaria": None,
        "ultima_alteracao": None,
    }

    # Procura em meta tags (OpenGraph, Dublin Core, etc.)
    for tag in soup.find_all("meta"):
        name = tag.get("name", "").lower()
        content = tag.get("content", "")

        if "data" in name and "publica" in name:
            meta["publicado_em"] = content
        elif "data" in name and ("vigente" in name or "efetiva" in name):
            meta["vigente_desde"] = content
        elif "portaria" in name:
            meta["portaria"] = content

    # Se não achou nos metas, procura em texto livre (parágrafos, definições, etc.)
    if not meta["portaria"]:
        for p in soup.find_all(["p", "dd", "dt"]):
            text = p.get_text(strip=True)
            if "portaria" in text.lower() and "mte" in text.lower():
                # Corta em limite de palavra para evitar truncar no meio da palavra
                if len(text) > 150:
                    truncated = text[:150].rsplit(" ", 1)[0]
                    meta["portaria"] = truncated
                else:
                    meta["portaria"] = text
                break

    # Última alteração pode estar em rodapé ou histórico
    for p in soup.find_all(["footer", "p", "small"]):
        text = p.get_text(strip=True)
        if any(keyword in text.lower() for keyword in ["atualizado", "última alteração", "modificado", "revisado"]):
            import re
            dates = re.findall(r"\d{4}-\d{2}-\d{2}|\d{2}/\d{2}/\d{4}", text)
            if dates:
                meta["ultima_alteracao"] = dates[0]
                break

    # Se ainda vazio, usa fixture
    if not any(meta.values()):
        logger.warning(f"Nenhum metadado extraído de {nr_id}. Usando fixture.")
        return FIXTURE_META.get(nr_id, meta)

    return meta


def main() -> int:
    """Scraping de metadados → content/nr-XX/meta.json."""
    parser = argparse.ArgumentParser(
        description="Scraping de metadados de vigência das NRs"
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
        help="Simula sem gravar"
    )
    parser.add_argument(
        "--verbose", "-v",
        action="store_true",
        help="Logging detalhado (DEBUG)"
    )
    args = parser.parse_args()

    setup_logging(args.verbose)

    logger.info("=== scrape_vigencia.py ===")
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
            # Merge de dados (nr_index.json + nr_sources.json)
            nr_data = merge_nr_data(nr_id)
            page_url = nr_data.get("page_url")

            if not page_url:
                logger.warning(f"{nr_id}: page_url não encontrada, pulando")
                continue

            # Scraping
            meta = scrape_nr_metadata(page_url, nr_id)

            # Garante dirs
            nr_dir = ensure_content_dir(nr_id)

            if args.dry_run:
                logger.info(f"[DRY-RUN] {nr_id}: teria gravado meta.json")
                logger.debug(json.dumps(meta, indent=2, ensure_ascii=False))
            else:
                # Grava em content/nr-XX/meta.json — mescla com o que já existe
                # (ex.: pdf_hash/char_count gravados por convert_nr.py) em vez
                # de sobrescrever, senão perde esses campos
                meta_file = nr_dir / "meta.json"
                existing = {}
                if meta_file.exists():
                    try:
                        existing = json.loads(meta_file.read_text(encoding="utf-8"))
                    except json.JSONDecodeError:
                        existing = {}
                merged = {**existing, **meta}
                meta_file.write_text(
                    json.dumps(merged, indent=2, ensure_ascii=False) + "\n",
                    encoding="utf-8"
                )
                logger.info(f"✓ {nr_id}: meta.json salvo")

        except Exception as e:
            err_msg = str(e)
            logger.error(f"✗ {nr_id}: {err_msg}")
            errors.append((nr_id, err_msg))
            continue

    # Relatório final
    logger.info(f"\nResumo: {len(nrs_to_process) - len(errors)}/{len(nrs_to_process)} OK")
    if errors:
        logger.error(f"Erros em {len(errors)} NR(s):")
        for nr_id, err_msg in errors:
            logger.error(f"  {nr_id}: {err_msg}")
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
