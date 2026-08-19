#!/usr/bin/env python3
"""
Gera manifest.json na raiz do repositório.

Agrega dados de content/nr-XX/meta.json, nr_index.json e arquivo .md
para criar o índice remoto central de todas as NRs.

Schema esperado (conforme docs/architecture.md):
{
  "generated_at": "2026-08-13T12:00:00Z",
  "version": 1,
  "nrs": [
    {
      "id": "nr-06",
      "title": "EPI",
      "version": "2026-01-17",
      "hash": "abc123...",
      "pdf_hash": "def456...",
      "updated_at": "2026-01-17T00:00:00Z",
      "portaria": "Portaria MTE nº 57/2025",
      "publicado_em": "2018-04-12",
      "vigente_desde": "2026-01-17",
      "url": "https://raw.githubusercontent.com/USER/nr-facil/main/content/nr-06/nr-06.md",
      "reviewed": false
    }
  ]
}

Uso:
  python3 scripts/build_manifest.py              # gera manifest.json
  python3 scripts/build_manifest.py --dry-run    # simula
  python3 scripts/build_manifest.py --help       # ajuda
"""
from __future__ import annotations

import argparse
import hashlib
import json
import logging
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from _common import ROOT, list_all_nrs, merge_nr_data, setup_logging

logger = logging.getLogger(__name__)

MANIFEST_FILE = ROOT / "manifest.json"
GITHUB_RAW_URL_TEMPLATE = "https://raw.githubusercontent.com/{owner}/{repo}/{branch}/content/{nr_id}/{nr_id}.md"


def get_github_remote() -> tuple[str, str, str]:
    """
    Extrai owner/repo/branch do git remote origin.

    Retorna (owner, repo, branch) ou fallbacks se não conseguir.
    Suporta SSH (git@github.com:owner/repo.git) e HTTPS (https://github.com/owner/repo.git).
    """
    try:
        import subprocess
        # git remote get-url origin
        result = subprocess.run(
            ["git", "remote", "get-url", "origin"],
            cwd=str(ROOT),
            capture_output=True,
            text=True,
            timeout=5
        )
        if result.returncode == 0:
            origin = result.stdout.strip()
            # Parse: https://github.com/owner/repo.git ou git@github.com:owner/repo.git
            if "github.com" in origin:
                origin_clean = origin.replace(".git", "")

                # Detecta formato SSH vs HTTPS
                if ":" in origin_clean and not origin_clean.startswith("https"):
                    # SSH: git@github.com:owner/repo
                    parts = origin_clean.split(":")
                    repo_path = parts[-1]  # owner/repo
                    path_parts = repo_path.split("/")
                    owner = path_parts[-2] if len(path_parts) >= 2 else "USER"
                    repo = path_parts[-1] if path_parts else "nr-facil"
                else:
                    # HTTPS: https://github.com/owner/repo
                    parts = origin_clean.split("/")
                    owner = parts[-2] if len(parts) >= 2 else "USER"
                    repo = parts[-1] if parts else "nr-facil"
            else:
                owner, repo = "USER", "nr-facil"
        else:
            owner, repo = "USER", "nr-facil"

        # Branch
        result = subprocess.run(
            ["git", "rev-parse", "--abbrev-ref", "HEAD"],
            cwd=str(ROOT),
            capture_output=True,
            text=True,
            timeout=5
        )
        branch = result.stdout.strip() if result.returncode == 0 else "main"

        return owner, repo, branch

    except Exception as e:
        logger.warning(f"Erro ao extrair git remote: {e}. Usando fallback.")
        return "USER", "nr-facil", "main"


def calculate_md_hash(md_file: Path) -> str:
    """Calcula SHA-256 do conteúdo do .md."""
    try:
        text = md_file.read_text(encoding="utf-8")
        return hashlib.sha256(text.encode()).hexdigest()
    except Exception as e:
        logger.warning(f"Erro ao calcular hash de {md_file}: {e}")
        return ""


def build_nr_entry(nr_id: str, owner: str, repo: str, branch: str) -> dict[str, Any] | None:
    """
    Constrói entrada de uma NR para o manifest.

    Merge: nr_index.json + meta.json (se existir) + arquivo .md
    """
    from _common import CONTENT_DIR

    nr_dir = CONTENT_DIR / nr_id
    meta_file = nr_dir / "meta.json"
    md_file = nr_dir / f"{nr_id}.md"

    # Dados de nr_index.json
    nr_data = merge_nr_data(nr_id)

    # Se não tem título, não processa (NR desconhecida)
    title = nr_data.get("title", "").strip()
    if not title:
        logger.warning(f"{nr_id}: título não encontrado em nr_index.json")
        return None

    # Lê meta.json se existir
    meta = {}
    if meta_file.exists():
        try:
            meta = json.loads(meta_file.read_text(encoding="utf-8"))
        except Exception as e:
            logger.warning(f"{nr_id}: erro ao ler meta.json: {e}")

    # Hash do conteúdo Markdown (versão do "compilado")
    md_hash = calculate_md_hash(md_file) if md_file.exists() else ""

    # PDF hash (do meta.json, salvo durante convert_nr.py)
    pdf_hash = meta.get("pdf_hash", "")

    # Metadados de vigência (do meta.json, preenchidos por scrape_vigencia.py)
    publicado_em = meta.get("publicado_em") or nr_data.get("publicado_em")
    vigente_desde = meta.get("vigente_desde") or nr_data.get("vigente_desde")
    portaria = meta.get("portaria") or nr_data.get("portaria")
    ultima_alteracao = meta.get("ultima_alteracao")

    # Versão = última alteração ou data do vigente_desde
    version = ultima_alteracao or vigente_desde or publicado_em or datetime.now(timezone.utc).isoformat()

    # URL do raw do GitHub
    url = GITHUB_RAW_URL_TEMPLATE.format(
        owner=owner,
        repo=repo,
        branch=branch,
        nr_id=nr_id
    )

    # Campo "reviewed" indica se foi revisado manualmente (qualidade ok)
    # Por padrão False até alguém marcar como revisado
    reviewed = meta.get("reviewed", False)

    entry = {
        "id": nr_id,
        "title": title,
        "version": version,
        "hash": md_hash,
        "pdf_hash": pdf_hash,
        "updated_at": datetime.now(timezone.utc).isoformat(),
        "portaria": portaria,
        "publicado_em": publicado_em,
        "vigente_desde": vigente_desde,
        "url": url,
        "reviewed": reviewed,
    }

    return entry


def main() -> int:
    """Gera manifest.json na raiz."""
    parser = argparse.ArgumentParser(
        description="Gera manifest.json (índice remoto de todas NRs)"
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

    logger.info("=== build_manifest.py ===")
    logger.info(f"Modo: {'DRY-RUN' if args.dry_run else 'NORMAL'}")

    # Extrai git info
    owner, repo, branch = get_github_remote()
    logger.info(f"GitHub: {owner}/{repo} @ {branch}")

    # Lista NRs a processar (todas com .md em content/)
    from _common import CONTENT_DIR
    nrs_to_process = [
        d.name for d in CONTENT_DIR.iterdir()
        if d.is_dir() and (d / f"{d.name}.md").exists()
    ]

    if not nrs_to_process:
        logger.warning("Nenhuma NR encontrada em content/")
        nrs_to_process = list_all_nrs()  # Tenta nr_index.json como fallback

    if not nrs_to_process:
        logger.error("Nenhuma NR encontrada")
        return 1

    logger.info(f"Processando {len(nrs_to_process)} NR(s)")

    # Constrói manifest
    manifest_data = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "version": 1,
        "nrs": [],
    }

    errors = []
    for nr_id in nrs_to_process:
        try:
            entry = build_nr_entry(nr_id, owner, repo, branch)
            if entry:
                manifest_data["nrs"].append(entry)
                logger.info(f"  ✓ {nr_id}")
            else:
                logger.warning(f"  ⊘ {nr_id}: skipped (dados incompletos)")
        except Exception as e:
            logger.error(f"  ✗ {nr_id}: {e}")
            errors.append(nr_id)

    logger.info(f"\nResumo: {len(manifest_data['nrs'])}/{len(nrs_to_process)} NRs no manifest")

    if args.dry_run:
        logger.info("[DRY-RUN] Teria gravado em manifest.json:")
        logger.info(json.dumps(manifest_data, indent=2, ensure_ascii=False)[:500] + "...")
        return 0

    # Grava manifest.json
    try:
        MANIFEST_FILE.write_text(
            json.dumps(manifest_data, indent=2, ensure_ascii=False) + "\n",
            encoding="utf-8"
        )
        logger.info(f"✓ Manifest salvo em {MANIFEST_FILE}")
    except Exception as e:
        logger.error(f"Erro ao gravar manifest: {e}")
        return 1

    if errors:
        logger.warning(f"Erros em {len(errors)} NR(s): {', '.join(errors)}")
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
