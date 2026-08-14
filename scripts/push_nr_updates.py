#!/usr/bin/env python3
"""
Insere atualizações em Supabase nr_updates table.

Lê manifest.json e compara com última entrada conhecida, gera summary,
e insere nova linha em nr_updates para cada NR que mudou.

⚠️  AVISO: Este script deve rodar APENAS na GitHub Action com credencial service_role.
Nunca chame localmente — a App não tem permissão de escrita, só leitura.

Uso:
  python3 scripts/push_nr_updates.py --supabase-url=... --service-key=...
  python3 scripts/push_nr_updates.py --dry-run (simula)

Variables de ambiente esperadas (via GitHub Secrets na Action):
  - SUPABASE_URL
  - SUPABASE_SERVICE_ROLE_KEY
"""
from __future__ import annotations

import argparse
import json
import logging
import os
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

try:
    from supabase import create_client
except ImportError as e:
    print(f"Erro: {e}. Instale com: pip install -r scripts/requirements.txt", file=sys.stderr)
    sys.exit(1)

from _common import ROOT, setup_logging

logger = logging.getLogger(__name__)

MANIFEST_FILE = ROOT / "manifest.json"


def load_manifest() -> dict[str, Any]:
    """Lê manifest.json."""
    if not MANIFEST_FILE.exists():
        logger.error(f"manifest.json não encontrado: {MANIFEST_FILE}")
        return {}

    try:
        return json.loads(MANIFEST_FILE.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        logger.error(f"Erro ao parsear manifest.json: {e}")
        return {}


def generate_summary(nr_id: str, old_entry: dict | None, new_entry: dict) -> str:
    """
    Gera resumo sem IA de uma mudança.

    Exemplo: "Seções alteradas: 6.3, 6.9" (gerado analisando diff de headings)
    Para MVP, um resumo simples: "Atualizado [data]"
    """
    if not old_entry:
        return f"Primeira versão ({new_entry.get('publicado_em', '?')})"

    # Comparação de versão
    if old_entry.get("pdf_hash") != new_entry.get("pdf_hash"):
        return f"Atualizado em {new_entry.get('vigente_desde', '?')}"

    return "Sem mudança significativa"


def push_nr_updates(
    supabase_url: str,
    service_key: str,
    dry_run: bool = False
) -> int:
    """
    Processa manifest.json e insere em Supabase.

    Lógica:
    1. Para cada NR no manifest.json
    2. Busca última entrada em nr_updates (se houver)
    3. Se pdf_hash mudou, insere nova linha
    4. Gera summary sem IA (ex.: "Atualizado em ...")

    Retorna 0 se sucesso, 1 se erro.
    """
    manifest = load_manifest()

    if not manifest:
        logger.error("Manifest vazio")
        return 1

    nrs = manifest.get("nrs", [])
    if not nrs:
        logger.warning("Nenhuma NR no manifest")
        return 0

    if dry_run:
        logger.info("[DRY-RUN] Teria inserido em nr_updates:")
        for nr in nrs:
            logger.info(f"  {nr['id']}: {nr.get('portaria', '?')}")
        return 0

    # Conecta ao Supabase
    try:
        client = create_client(supabase_url, service_key)
    except Exception as e:
        logger.error(f"Erro ao conectar ao Supabase: {e}")
        return 1

    # Processa cada NR
    errors = []

    for nr in nrs:
        nr_id = nr.get("id")
        if not nr_id:
            continue

        logger.info(f"Processando {nr_id}")

        try:
            # Busca última entrada
            response = client.table("nr_updates").select("*").eq("nr_id", nr_id).order("created_at", desc=True).limit(1).execute()
            last_entry = response.data[0] if response.data else None

            # Compara hash
            last_hash = last_entry.get("pdf_hash") if last_entry else None
            new_hash = nr.get("pdf_hash")

            if last_hash and last_hash == new_hash:
                logger.info(f"  ⊘ Sem mudança (hash idêntico)")
                continue

            # Gera summary
            summary = generate_summary(nr_id, last_entry, nr)

            # Monta novo record
            new_record = {
                "nr_id": nr_id,
                "title": nr.get("title"),
                "portaria": nr.get("portaria"),
                "pdf_hash": new_hash,
                "summary": summary,
                "created_at": datetime.now(timezone.utc).isoformat(),
            }

            # Insere
            client.table("nr_updates").insert(new_record).execute()
            logger.info(f"  ✓ Inserido em nr_updates")

        except Exception as e:
            logger.error(f"  ✗ Erro: {e}")
            errors.append(nr_id)
            continue

    if errors:
        logger.error(f"\nErros em {len(errors)} NR(s): {', '.join(errors)}")
        return 1

    return 0


def main() -> int:
    """Insere atualizações no Supabase."""
    parser = argparse.ArgumentParser(
        description="Insere atualizações em Supabase nr_updates (Action only)"
    )
    parser.add_argument(
        "--supabase-url",
        type=str,
        default=os.environ.get("SUPABASE_URL", ""),
        help="URL do Supabase (ou var SUPABASE_URL)"
    )
    parser.add_argument(
        "--service-key",
        type=str,
        default=os.environ.get("SUPABASE_SERVICE_ROLE_KEY", ""),
        help="Service role key (ou var SUPABASE_SERVICE_ROLE_KEY)"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Simula sem inserir"
    )
    parser.add_argument(
        "--verbose", "-v",
        action="store_true",
        help="Logging detalhado"
    )
    args = parser.parse_args()

    setup_logging(args.verbose)

    logger.info("=== push_nr_updates.py ===")
    logger.info(f"Modo: {'DRY-RUN' if args.dry_run else 'NORMAL'}")

    if not args.supabase_url or not args.service_key:
        if not args.dry_run:
            logger.error("Credenciais do Supabase não encontradas")
            logger.error("Use --supabase-url e --service-key ou vars SUPABASE_URL/SUPABASE_SERVICE_ROLE_KEY")
            return 1
        logger.warning("Credenciais não configuradas, mas --dry-run está ativo")

    return push_nr_updates(args.supabase_url, args.service_key, dry_run=args.dry_run)


if __name__ == "__main__":
    sys.exit(main())
