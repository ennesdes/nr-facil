#!/usr/bin/env python3
"""
Gera app_meta.json — feed de atualizações + versão mínima do app.

Lê manifest.json, compara com o app_meta.json anterior (se existir) e
acrescenta uma entrada em "updates" para cada NR cujo pdf_hash mudou.
Sem backend: o arquivo é commitado no repo pela própria Action, junto com
manifest.json, e o app lê via GitHub raw.

Uso:
  python3 scripts/build_app_meta.py
  python3 scripts/build_app_meta.py --dry-run   # simula sem gravar
"""
from __future__ import annotations

import argparse
import json
import logging
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from _common import ROOT, setup_logging

logger = logging.getLogger(__name__)

MANIFEST_FILE = ROOT / "manifest.json"
APP_META_FILE = ROOT / "app_meta.json"

MAX_UPDATES = 200
DEFAULT_MIN_APP_VERSION = "0.0.0"


def load_json(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        logger.error(f"Erro ao parsear {path.name}: {e}")
        return {}


def generate_summary(old_entry: dict | None, new_entry: dict) -> str:
    """Gera resumo sem IA de uma mudança."""
    if not old_entry:
        return f"Primeira versão ({new_entry.get('publicado_em', '?')})"

    if old_entry.get("pdf_hash") != new_entry.get("pdf_hash"):
        return f"Atualizado em {new_entry.get('vigente_desde', '?')}"

    return "Sem mudança significativa"


def build_app_meta(dry_run: bool = False) -> int:
    """
    Processa manifest.json e gera app_meta.json.

    Lógica:
    1. Para cada NR no manifest.json
    2. Compara pdf_hash com a última entrada conhecida em app_meta.json
    3. Se mudou, acrescenta nova entrada em "updates" (gera summary sem IA)
    4. Mantém só as MAX_UPDATES entradas mais recentes

    Retorna 0 sempre — não há chamada de rede, então não há como falhar
    de forma parcial (diferente dos scripts de scraping/conversão).
    """
    manifest = load_json(MANIFEST_FILE)
    if not manifest:
        logger.error(f"manifest.json não encontrado ou vazio: {MANIFEST_FILE}")
        return 1

    nrs = manifest.get("nrs", [])
    if not nrs:
        logger.warning("Nenhuma NR no manifest")
        return 0

    previous = load_json(APP_META_FILE)
    previous_updates = previous.get("updates", [])
    last_hash_by_nr = {u["nr_id"]: u.get("pdf_hash") for u in previous_updates if "nr_id" in u}

    new_entries = []
    for nr in nrs:
        nr_id = nr.get("id")
        if not nr_id:
            continue

        new_hash = nr.get("pdf_hash")
        old_hash = last_hash_by_nr.get(nr_id)

        if old_hash and old_hash == new_hash:
            continue

        old_entry = {"pdf_hash": old_hash} if old_hash else None
        summary = generate_summary(old_entry, nr)

        new_entries.append({
            "nr_id": nr_id,
            "title": nr.get("title"),
            "portaria": nr.get("portaria"),
            "pdf_hash": new_hash,
            "summary": summary,
            "created_at": datetime.now(timezone.utc).isoformat(),
        })
        logger.info(f"  {nr_id}: {summary}")

    updates = (previous_updates + new_entries)[-MAX_UPDATES:]

    app_meta = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "min_app_version": previous.get("min_app_version", DEFAULT_MIN_APP_VERSION),
        "updates": updates,
    }

    if dry_run:
        logger.info(f"[DRY-RUN] {len(new_entries)} nova(s) entrada(s), {len(updates)} no total")
        return 0

    APP_META_FILE.write_text(
        json.dumps(app_meta, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    logger.info(f"app_meta.json gerado com {len(new_entries)} nova(s) entrada(s)")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Gera app_meta.json (feed de atualizações + versão mínima, sem backend)"
    )
    parser.add_argument("--dry-run", action="store_true", help="Simula sem gravar")
    parser.add_argument("--verbose", "-v", action="store_true", help="Logging detalhado")
    args = parser.parse_args()

    setup_logging(args.verbose)

    logger.info("=== build_app_meta.py ===")
    logger.info(f"Modo: {'DRY-RUN' if args.dry_run else 'NORMAL'}")

    return build_app_meta(dry_run=args.dry_run)


if __name__ == "__main__":
    sys.exit(main())
