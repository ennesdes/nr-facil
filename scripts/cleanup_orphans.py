#!/usr/bin/env python3
"""
Remove diretórios órfãos em content/ — NRs que saíram de nr_index.json e
nr_sources.json (ex.: renumeradas, unificadas, removidas do índice do gov.br).

Sem isso, content/nr-XX/ (markdown, PDF, assets/pages/*.png, índices) fica
para sempre no repositório mesmo depois de a NR desaparecer da fonte —
lixo que só cresce a cada execução da Action.

Uso:
  python3 scripts/cleanup_orphans.py              # remove órfãos
  python3 scripts/cleanup_orphans.py --dry-run    # lista sem remover
  python3 scripts/cleanup_orphans.py --help       # ajuda
"""
from __future__ import annotations

import argparse
import logging
import shutil
import sys

from _common import CONTENT_DIR, list_all_nrs, setup_logging

logger = logging.getLogger(__name__)


def find_orphan_dirs() -> list[str]:
    """
    Lista subdiretórios de content/ que não existem mais em nr_index.json
    nem em nr_sources.json (união via list_all_nrs()).

    Retorna lista de nr_id ordenada. Vazio se content/ não existir (Fase 0)
    ou se não houver órfãos.
    """
    if not CONTENT_DIR.exists():
        return []

    known = set(list_all_nrs())
    on_disk = {d.name for d in CONTENT_DIR.iterdir() if d.is_dir()}

    return sorted(on_disk - known)


def remove_orphan(nr_id: str, dry_run: bool = False) -> bool:
    """Remove content/nr-XX/ inteiro. Retorna True se sucesso."""
    nr_dir = CONTENT_DIR / nr_id

    if dry_run:
        logger.info(f"[DRY-RUN] removeria {nr_dir}")
        return True

    try:
        shutil.rmtree(nr_dir)
        logger.info(f"✓ removido {nr_dir}")
        return True
    except Exception as e:
        logger.error(f"✗ falha ao remover {nr_dir}: {e}")
        return False


def main() -> int:
    """Remove diretórios de content/ que não correspondem a nenhuma NR conhecida."""
    parser = argparse.ArgumentParser(
        description="Remove content/nr-XX/ órfãos (NRs fora de nr_index.json e nr_sources.json)"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Lista órfãos sem remover"
    )
    parser.add_argument(
        "--verbose", "-v",
        action="store_true",
        help="Logging detalhado"
    )
    args = parser.parse_args()

    setup_logging(args.verbose)

    logger.info("=== cleanup_orphans.py ===")
    logger.info(f"Modo: {'DRY-RUN' if args.dry_run else 'NORMAL'}")

    orphans = find_orphan_dirs()

    if not orphans:
        logger.info("Nenhum órfão encontrado")
        return 0

    logger.info(f"{len(orphans)} órfão(s) encontrado(s): {', '.join(orphans)}")

    errors: list[str] = []
    for nr_id in orphans:
        if not remove_orphan(nr_id, dry_run=args.dry_run):
            errors.append(nr_id)

    if errors:
        logger.error(f"Erros ao remover {len(errors)} órfão(s): {', '.join(errors)}")
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
