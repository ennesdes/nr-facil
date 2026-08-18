#!/usr/bin/env python3
"""Utilitários compartilhados para scripts da pipeline."""
from __future__ import annotations

import json
import logging
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parent.parent
SCRIPTS_DIR = ROOT / "scripts"
CONTENT_DIR = ROOT / "content"
NR_INDEX_FILE = SCRIPTS_DIR / "nr_index.json"
NR_SOURCES_FILE = SCRIPTS_DIR / "nr_sources.json"

logger = logging.getLogger(__name__)


def get_nr_index() -> dict[str, Any]:
    """Lê nr_index.json gerado dinamicamente. Fallback vazio se não existir."""
    if NR_INDEX_FILE.exists():
        try:
            return json.loads(NR_INDEX_FILE.read_text(encoding="utf-8"))
        except json.JSONDecodeError as e:
            logger.error(f"Erro ao parsear nr_index.json: {e}")
            return {}
    return {}


def get_nr_sources() -> dict[str, dict[str, Any]]:
    """Lê nr_sources.json (overrides manuais). Fallback vazio se não existir."""
    if NR_SOURCES_FILE.exists():
        try:
            return json.loads(NR_SOURCES_FILE.read_text(encoding="utf-8"))
        except json.JSONDecodeError as e:
            logger.error(f"Erro ao parsear nr_sources.json: {e}")
            return {}
    return {}


def merge_nr_data(nr_id: str) -> dict[str, Any]:
    """
    Merge: nr_index.json (dinâmico, base) + nr_sources.json (overrides pontuais).
    Retorna dicionário com dados consolidados de uma NR.

    Ordem de precedência:
    1. nr_sources.json[nr_id] (override manual)
    2. nr_index.json[nr_id] (scraping dinâmico)
    3. fallback vazio
    """
    index = get_nr_index()
    sources = get_nr_sources()

    # Base vem de nr_index.json
    base = index.get(nr_id, {})
    # Sobrescreve com nr_sources.json
    override = sources.get(nr_id, {})

    # Merge: override por cima de base
    merged = {**base, **override}
    return merged


def list_all_nrs() -> list[str]:
    """
    Lista todas as NRs conhecidas (de nr_index.json + nr_sources.json).
    Retorna lista de IDs como ['nr-01', 'nr-06', ...].
    """
    index = get_nr_index()
    sources = get_nr_sources()

    # Union dos dois dicts — chaves começando com "_" são metadados do
    # arquivo (ex.: "_comment", "_exemplo" em nr_sources.json), não NRs
    all_ids = {k for k in (set(index.keys()) | set(sources.keys())) if not k.startswith("_")}
    return sorted(all_ids)


def ensure_content_dir(nr_id: str) -> Path:
    """Cria e retorna o diretório content/nr-XX/."""
    nr_dir = CONTENT_DIR / nr_id
    nr_dir.mkdir(parents=True, exist_ok=True)
    return nr_dir


def ensure_assets_dir(nr_id: str, asset_type: str = "pages") -> Path:
    """Cria e retorna content/nr-XX/assets/{asset_type}/."""
    assets_dir = CONTENT_DIR / nr_id / "assets" / asset_type
    assets_dir.mkdir(parents=True, exist_ok=True)
    return assets_dir


def setup_logging(verbose: bool = False) -> None:
    """Configura logging com nível INFO ou DEBUG."""
    level = logging.DEBUG if verbose else logging.INFO
    logging.basicConfig(
        level=level,
        format="%(levelname)s: %(message)s"
    )
