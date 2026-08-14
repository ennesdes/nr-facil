#!/usr/bin/env python3
"""
Detecção de mudanças e disparo de conversão.

Para cada NR:
1. Baixa o PDF atual (usando pdf_url de nr_index.json + overrides de nr_sources.json)
2. Calcula SHA-256
3. Compara com pdf_hash anterior (salvo em content/nr-XX/meta.json)
4. Se mudou, dispara conversão (convert_nr.py)

Isolamento de erro por NR: falha numa NR não interrompe as demais.
Exit code != 0 ao final se houver erros (para falhar a Action do GitHub).

Uso:
  python3 scripts/update_nrs.py              # processa todas NRs
  python3 scripts/update_nrs.py --dry-run    # simula
  python3 scripts/update_nrs.py --help       # ajuda
"""
from __future__ import annotations

import argparse
import hashlib
import json
import logging
import subprocess
import sys
from pathlib import Path
from typing import Any

try:
    import requests
except ImportError as e:
    print(f"Erro: {e}. Instale com: pip install -r scripts/requirements.txt", file=sys.stderr)
    sys.exit(1)

from _common import merge_nr_data, list_all_nrs, ensure_content_dir, setup_logging

logger = logging.getLogger(__name__)


def download_and_hash_pdf(pdf_url: str, nr_id: str, dry_run: bool = False) -> tuple[str, int]:
    """
    Baixa PDF e calcula hash.

    Retorna (hash_hexadecimal, tamanho_bytes) ou ("", 0) se falhar.
    """
    logger.info(f"Baixando PDF de {nr_id}")

    try:
        resp = requests.get(pdf_url, timeout=30)
        resp.raise_for_status()
        pdf_bytes = resp.content

        pdf_hash = hashlib.sha256(pdf_bytes).hexdigest()
        size = len(pdf_bytes)

        logger.debug(f"  Hash: {pdf_hash[:16]}..., Tamanho: {size} bytes")
        return pdf_hash, size

    except Exception as e:
        logger.error(f"  Falha ao baixar: {e}")
        return "", 0


def get_previous_pdf_hash(nr_id: str) -> str:
    """Lê pdf_hash anterior de content/nr-XX/meta.json."""
    nr_dir = ensure_content_dir(nr_id)
    meta_file = nr_dir / "meta.json"

    if meta_file.exists():
        try:
            meta = json.loads(meta_file.read_text(encoding="utf-8"))
            return meta.get("pdf_hash", "")
        except Exception as e:
            logger.debug(f"Erro ao ler meta.json de {nr_id}: {e}")
            return ""

    return ""


def run_conversion(nr_id: str, dry_run: bool = False) -> bool:
    """Dispara convert_nr.py --nr nr-XX."""
    if dry_run:
        logger.info(f"[DRY-RUN] dispararia convert_nr.py --nr {nr_id}")
        return True

    logger.info(f"Disparando conversão de {nr_id}")

    try:
        result = subprocess.run(
            [sys.executable, "scripts/convert_nr.py", "--nr", nr_id],
            cwd=str(Path(__file__).parent.parent),
            timeout=300,  # 5 min por NR
            capture_output=True,
            text=True
        )

        if result.returncode == 0:
            logger.info(f"  ✓ Conversão bem-sucedida")
            return True
        else:
            logger.error(f"  ✗ Conversão falhou (exit code {result.returncode})")
            if result.stderr:
                logger.error(f"    Stderr: {result.stderr[:200]}")
            return False

    except subprocess.TimeoutExpired:
        logger.error(f"  ✗ Timeout na conversão (>300s)")
        return False
    except Exception as e:
        logger.error(f"  ✗ Erro ao disparar conversão: {e}")
        return False


def process_nr(nr_id: str, dry_run: bool = False) -> tuple[bool, str]:
    """
    Processa uma NR. Retorna (sucesso: bool, motivo: str).

    Motivos: "sem mudança", "pdf atualizado", "primeira vez", "erro: ..."
    """
    logger.info(f"\n{nr_id}:")

    # Merge de dados
    nr_data = merge_nr_data(nr_id)
    pdf_url = nr_data.get("pdf_url")

    if not pdf_url:
        return False, "pdf_url não encontrada"

    # Download e hash
    new_hash, size = download_and_hash_pdf(pdf_url, nr_id, dry_run=dry_run)

    if not new_hash:
        return False, "falha ao baixar PDF"

    # Hash anterior
    prev_hash = get_previous_pdf_hash(nr_id)

    # Comparação
    if prev_hash and new_hash == prev_hash:
        logger.info(f"  ✓ Sem mudança (hash idêntico)")
        return True, "sem mudança"

    if not prev_hash:
        logger.info(f"  • Primeira conversão (hash novo)")
        reason = "primeira vez"
    else:
        logger.info(f"  ✓ PDF atualizado (hash mudou)")
        reason = "pdf atualizado"

    # Dispara conversão
    if not run_conversion(nr_id, dry_run=dry_run):
        return False, f"conversão falhou ({reason})"

    return True, reason


def main() -> int:
    """Processa atualizações de PDFs."""
    parser = argparse.ArgumentParser(
        description="Detecta mudanças de PDF e dispara conversão"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Simula sem baixar/converter"
    )
    parser.add_argument(
        "--verbose", "-v",
        action="store_true",
        help="Logging detalhado"
    )
    args = parser.parse_args()

    setup_logging(args.verbose)

    logger.info("=== update_nrs.py ===")
    logger.info(f"Modo: {'DRY-RUN' if args.dry_run else 'NORMAL'}")

    # Lista NRs
    nrs_to_process = list_all_nrs()

    if not nrs_to_process:
        logger.error("Nenhuma NR encontrada em nr_index.json")
        return 1

    logger.info(f"Processando {len(nrs_to_process)} NR(s)")

    # Processamento isolado por NR
    errors: list[tuple[str, str]] = []
    results = {
        "sem_mudanca": [],
        "atualizado": [],
        "primeira_vez": [],
        "erro": [],
    }

    for nr_id in nrs_to_process:
        try:
            success, reason = process_nr(nr_id, dry_run=args.dry_run)

            if success:
                if reason == "sem mudança":
                    results["sem_mudanca"].append(nr_id)
                elif reason == "pdf atualizado":
                    results["atualizado"].append(nr_id)
                elif reason == "primeira vez":
                    results["primeira_vez"].append(nr_id)
            else:
                results["erro"].append(nr_id)
                errors.append((nr_id, reason))

        except Exception as e:
            err_msg = str(e)
            logger.error(f"✗ {nr_id}: {err_msg}")
            results["erro"].append(nr_id)
            errors.append((nr_id, err_msg))
            continue

    # Relatório final
    logger.info(f"\n{'='*60}")
    logger.info("Resumo:")
    logger.info(f"  Sem mudança: {len(results['sem_mudanca'])}")
    logger.info(f"  Atualizados: {len(results['atualizado'])}")
    logger.info(f"  Primeira vez: {len(results['primeira_vez'])}")
    logger.info(f"  Erros: {len(results['erro'])}")

    if errors:
        logger.error(f"\nErros em {len(errors)} NR(s):")
        for nr_id, reason in errors:
            logger.error(f"  {nr_id}: {reason}")
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
