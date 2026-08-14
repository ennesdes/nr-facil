#!/usr/bin/env python3
"""
Descobre NRs a partir da página-índice do gov.br — scraping dinâmico em 2 níveis.

Level 1: Fetch índice oficial → extrair NR id, título, page_url (href real).
Level 2: Para cada page_url, fetch e extrair pdf_url (matching nr-{NN}...\.pdf).

Salva em scripts/nr_index.json (dinâmico, gerado). Se layout mudar ou rede falhar,
lança exceção (sem fallback silencioso para dados fake).

Uso:
  python3 scripts/discover_nrs.py              # scraping completo → nr_index.json
  python3 scripts/discover_nrs.py --dry-run    # simula sem gravar
  python3 scripts/discover_nrs.py --help       # ajuda
"""
from __future__ import annotations

import argparse
import json
import logging
import re
import sys
import time
from pathlib import Path
from typing import Any
from urllib.parse import urljoin

try:
    import requests
    from bs4 import BeautifulSoup
except ImportError as e:
    print(f"Erro: {e}. Instale com: pip install -r scripts/requirements.txt", file=sys.stderr)
    sys.exit(1)

from _common import SCRIPTS_DIR, setup_logging

logger = logging.getLogger(__name__)

# URL da página-índice oficial do MTE (gov.br)
INDEX_URL = "https://www.gov.br/trabalho-e-emprego/pt-br/assuntos/inspecao-do-trabalho/seguranca-e-saude-no-trabalho/ctpp-nrs/normas-regulamentadoras-nrs"

# Politeness: delay entre fetches de página (em segundos)
DELAY_BETWEEN_FETCHES = 0.5


def extract_nr_from_text(text: str) -> tuple[int | None, str, bool]:
    """
    Extrai NR número, título limpo, e flag revogada do texto de link.

    Exemplos:
      "NR-1 - DISPOSIÇÕES GERAIS..." → (1, "DISPOSIÇÕES GERAIS...", False)
      "NR-27 - TÍTULO (REVOGADA)" → (27, "TÍTULO", True)

    Retorna: (nr_num, title_clean, revogada_bool)
    """
    # Padrão: "NR-N - TÍTULO" opcionalmente com "(REVOGADA)"
    match = re.match(r'NR-(\d+)\s*-\s*(.+?)(?:\s*\(REVOGADA\))?\s*$', text, re.IGNORECASE)
    if not match:
        return None, text, False

    nr_num = int(match.group(1))
    title = match.group(2).strip()
    revogada = "(REVOGADA)" in text.upper()

    return nr_num, title, revogada


def fetch_index_page() -> dict[int, dict[str, Any]]:
    """
    Level 1: Fetch página-índice, extrai lista de NRs com id, título, page_url.

    Retorna: {
      1: {"nr_num": 1, "title": "...", "page_url": "...", "revogada": bool},
      6: {...},
      ...
    }

    Levanta exceção se fetch falhar ou nenhuma NR for encontrada (sem fallback).
    """
    logger.info(f"[L1] Buscando índice em {INDEX_URL}")

    try:
        resp = requests.get(INDEX_URL, timeout=10)
        resp.raise_for_status()
    except requests.RequestException as e:
        logger.error(f"Falha ao buscar índice: {e}")
        raise

    soup = BeautifulSoup(resp.text, "html.parser")
    nrs_by_num: dict[int, dict[str, Any]] = {}

    # Procura por links que correspondem a NRs
    links = soup.find_all("a", href=True)
    for link in links:
        text = link.get_text(strip=True)
        href = link.get("href", "").strip()

        # Padrão: texto começa com "NR-N"
        if not re.match(r'NR-\d+', text):
            continue

        nr_num, title, revogada = extract_nr_from_text(text)
        if nr_num is None:
            continue

        # Garante que href é URL absoluta
        page_url = urljoin(INDEX_URL, href)

        nrs_by_num[nr_num] = {
            "nr_num": nr_num,
            "title": title,
            "page_url": page_url,
            "revogada": revogada,
        }

    if not nrs_by_num:
        logger.error("Nenhuma NR encontrada no índice — layout pode ter mudado")
        raise ValueError("Index page parsing failed: no NRs found")

    logger.info(f"[L1] Encontradas {len(nrs_by_num)} NRs no índice")
    return nrs_by_num


def find_pdf_on_page(nr_num: int, page_url: str, session: requests.Session) -> str | None:
    """
    Level 2: Fetch page_url, procura por PDF matching nr-{NN}...\.pdf.

    Se múltiplos PDFs forem encontrados (diferentes versões), escolhe o de maior ano,
    depois maior i-N counter (ex: nr-01-atualizada-2025-i-3.pdf vs nr-01-atualizada-2024-i-1.pdf).

    Retorna: url do PDF ou None se não encontrado.
    """
    logger.debug(f"[L2] Buscando PDF na página NR-{nr_num}: {page_url}")

    try:
        resp = session.get(page_url, timeout=10)
        resp.raise_for_status()
    except requests.RequestException as e:
        logger.warning(f"[L2] Falha ao buscar página NR-{nr_num}: {e}")
        return None

    soup = BeautifulSoup(resp.text, "html.parser")

    # Procura por links de PDF
    pdf_links = []
    for link in soup.find_all("a", href=True):
        href = link.get("href", "").lower()

        # Verifica se é um PDF
        if not href.endswith(".pdf"):
            continue

        # Extrai filename para verificar padrão nr-{NN}
        filename = href.split("/")[-1]
        match = re.match(r'nr-(\d+)', filename, re.IGNORECASE)
        if not match:
            continue

        pdf_nr = int(match.group(1))
        if pdf_nr != nr_num:
            # PDF é de outra NR, pula (ex: FAQs, guias que mencionam múltiplas NRs)
            continue

        # PDF é desta NR, salva com score de versão
        full_url = urljoin(page_url, href)

        # Extrai ano e i-N counter para scoring
        year_match = re.search(r'(\d{4})', filename)
        year = int(year_match.group(1)) if year_match else 0

        counter_match = re.search(r'-i-(\d+)', filename, re.IGNORECASE)
        counter = int(counter_match.group(1)) if counter_match else 0

        pdf_links.append({
            "url": full_url,
            "filename": filename,
            "year": year,
            "counter": counter,
            "score": (year, counter),  # tupla para ordenação
        })

    if not pdf_links:
        logger.warning(f"[L2] Nenhum PDF encontrado na página NR-{nr_num}")
        return None

    # Ordena por score descendente (maior ano, maior counter)
    pdf_links.sort(key=lambda x: x["score"], reverse=True)
    best = pdf_links[0]

    if len(pdf_links) > 1:
        logger.debug(f"[L2] NR-{nr_num}: múltiplos PDFs, escolhido '{best['filename']}'")

    return best["url"]


def scrape_all_nrs() -> dict[str, dict[str, Any]]:
    """
    Scraping completo em 2 níveis → dicionário nr_index.json final.

    Retorna: {
      "nr-01": {"id": "nr-01", "title": "...", "pdf_url": "...", "page_url": "...",
                "revogada": bool, "substitui_por": None},
      ...
    }
    """
    # Level 1: Fetch índice
    nrs_by_num = fetch_index_page()

    # Level 2: Para cada NR, fetch sua página e acha PDF
    result: dict[str, dict[str, Any]] = {}
    session = requests.Session()

    for nr_num in sorted(nrs_by_num.keys()):
        nr_info = nrs_by_num[nr_num]
        nr_id = f"nr-{nr_num:02d}"  # zero-padded: nr-01, nr-06, etc.

        logger.info(f"Processando {nr_id} ({nr_info['title'][:50]}...)")

        # Acha PDF na página
        pdf_url = find_pdf_on_page(nr_num, nr_info["page_url"], session)

        if not pdf_url:
            logger.warning(f"Aviso: {nr_id} não tem PDF encontrado na página")
            pdf_url = ""  # string vazia em vez de None para JSON

        result[nr_id] = {
            "id": nr_id,
            "title": nr_info["title"],
            "pdf_url": pdf_url,
            "page_url": nr_info["page_url"],
            "revogada": nr_info["revogada"],
            "substitui_por": None,
        }

        # Politeness: pequeno delay entre fetches
        time.sleep(DELAY_BETWEEN_FETCHES)

    return result


def main() -> int:
    """Scraping completo → nr_index.json."""
    parser = argparse.ArgumentParser(
        description="Descobre NRs do gov.br (2 níveis de scraping) → scripts/nr_index.json"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Simula sem gravar arquivo"
    )
    parser.add_argument(
        "--verbose", "-v",
        action="store_true",
        help="Logging detalhado (DEBUG)"
    )
    args = parser.parse_args()

    setup_logging(args.verbose)

    logger.info("=== discover_nrs.py (two-level scraper) ===")
    logger.info(f"Modo: {'DRY-RUN' if args.dry_run else 'NORMAL'}")

    # Scraping completo
    try:
        nrs = scrape_all_nrs()
    except Exception as e:
        logger.error(f"Scraping falhou — sem fallback para dados fake. Erro: {e}")
        return 1

    logger.info(f"✓ Scraping completo: {len(nrs)} NRs encontradas")

    # Contagem de revogadas
    revogadas_count = sum(1 for nr in nrs.values() if nr.get("revogada", False))
    logger.info(f"  - Revogadas: {revogadas_count}")
    logger.info(f"  - Vigentes: {len(nrs) - revogadas_count}")

    output_file = SCRIPTS_DIR / "nr_index.json"

    if args.dry_run:
        logger.info(f"[DRY-RUN] Teria gravado em {output_file}")
        # Mostra primeiras 2 e contagem
        logger.info("Amostra (primeiras 2 NRs):")
        for nr_id in sorted(nrs.keys())[:2]:
            logger.info(f"  {nr_id}: {json.dumps(nrs[nr_id], ensure_ascii=False)}")
        return 0

    # Grava
    try:
        output_file.write_text(
            json.dumps(nrs, indent=2, ensure_ascii=False) + "\n",
            encoding="utf-8"
        )
        logger.info(f"✓ Salvo em {output_file}")
        return 0
    except Exception as e:
        logger.error(f"Erro ao gravar: {e}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
