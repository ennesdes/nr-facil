#!/usr/bin/env python3
"""
Gera app_meta.json — feed de atualizações + versão mínima do app.

Lê manifest.json, compara com o app_meta.json anterior (se existir) e
acrescenta uma entrada em "updates" para cada NR cujo hash (md) mudou.
Reaproveita o diff granular de summarize_changes.py para gerar items[].
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
import re
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from _common import ROOT, setup_logging
from summarize_changes import summarize_md, git_show

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


def parse_summary_items(lines: list[str]) -> list[dict[str, str]]:
    """
    Parse itens de output de summarize_md para schema {item, tipo, resumo}.

    Formatos esperados:
    - "- 🆕 Novo item **6.3**: descrição..."
    - "- ❌ Item removido **6.3**: descrição..."
    - "- ✏️ Item alterado **6.3**" seguido de sub-linhas indentadas
      "  - antes: ..." / "  - depois: ..." (montadas em um único resumo)
    """
    items = []
    i, n = 0, len(lines)
    while i < n:
        line = lines[i]

        if line.startswith("- 🆕"):
            match = re.search(r"\*\*([^*]+)\*\*:\s*(.*)", line)
            if match:
                items.append({"item": match.group(1), "tipo": "novo", "resumo": match.group(2)})
            i += 1

        elif line.startswith("- ❌"):
            match = re.search(r"\*\*([^*]+)\*\*:\s*(.*)", line)
            if match:
                items.append({"item": match.group(1), "tipo": "removido", "resumo": match.group(2)})
            i += 1

        elif line.startswith("- ✏️"):
            match = re.search(r"\*\*([^*]+)\*\*", line)
            item_num = match.group(1) if match else "?"

            # Consome as sub-linhas indentadas (antes/depois) deste item
            antes, depois = "", ""
            j = i + 1
            while j < n and lines[j].startswith("  "):
                sub = lines[j].strip("- ").strip()
                if sub.startswith("antes:"):
                    antes = sub[len("antes:"):].strip()
                elif sub.startswith("depois:"):
                    depois = sub[len("depois:"):].strip()
                j += 1

            resumo = f"antes: {antes} → depois: {depois}" if (antes or depois) else ""
            items.append({"item": item_num, "tipo": "alterado", "resumo": resumo})
            i = j

        else:
            i += 1

    return items


def generate_summary(items: list[dict[str, str]]) -> str:
    """
    Gera resumo curto de uma mudança a partir dos items estruturados.

    Evita interpolar valores que podem ser None.
    Retorna um resumo genérico quando não houver items (diff indisponível).
    """
    if not items:
        return "Atualização disponível"

    # Contagem de tipos
    novos = len([i for i in items if i.get("tipo") == "novo"])
    removidos = len([i for i in items if i.get("tipo") == "removido"])
    alterados = len([i for i in items if i.get("tipo") == "alterado"])

    total = novos + removidos + alterados

    # Resumo genérico baseado no total
    if total == 1:
        # Se há só um item alterado, mostre detalhes
        item = items[0]
        tipo_text = {
            "novo": "novo item adicionado",
            "removido": "item removido",
            "alterado": "item alterado",
        }.get(item.get("tipo"), "alteração")
        return f"{tipo_text}: {item.get('item', '?')}"
    else:
        return f"{total} itens alterados"


def build_app_meta(dry_run: bool = False) -> int:
    """
    Processa manifest.json e gera app_meta.json.

    Lógica:
    1. Para cada NR no manifest.json
    2. Compara hash (md) com a última entrada conhecida em app_meta.json
    3. Se mudou, acrescenta nova entrada em "updates"
    4. Gera items[] granulares usando summarize_md (se git_show disponível)
    5. Gera summary curto a partir dos items
    6. Mantém só as MAX_UPDATES entradas mais recentes

    Retorna 0 sempre — não há chamada de rede nessa etapa.
    Falhas isoladas (git_show indisponível) não interrompem o processamento.
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
    # Construir índice das últimas versões: nr_id -> hash (md)
    last_hash_by_nr = {u["nr_id"]: u.get("hash") for u in previous_updates if "nr_id" in u}
    # NRs que já tiveram QUALQUER entrada no feed antes (mesmo sob o schema antigo,
    # que só gravava pdf_hash) — usado para não rotular como "Primeira versão" uma
    # NR que só está sem `hash` por causa da migração de critério (D1: pdf_hash → hash).
    seen_nr_ids = {u["nr_id"] for u in previous_updates if "nr_id" in u}

    new_entries = []
    for nr in nrs:
        nr_id = nr.get("id")
        if not nr_id:
            continue

        # Comparar por hash (md), não pdf_hash
        new_hash = nr.get("hash")
        old_hash = last_hash_by_nr.get(nr_id)

        # Se hash não mudou, pula
        if old_hash and old_hash == new_hash:
            continue

        if nr_id not in seen_nr_ids:
            # Nunca apareceu no feed antes — primeira vez de verdade.
            # Nunca interpolar publicado_em diretamente: pode ser None.
            publicado_em = nr.get("publicado_em") or "?"
            items = []
            summary = f"Primeira versão ({publicado_em})"
        else:
            # Há versão anterior — tenta gerar items granulares a partir do diff
            items = []
            try:
                content_file = ROOT / "content" / nr_id / f"{nr_id}.md"
                if content_file.exists():
                    new_text = content_file.read_text(encoding="utf-8")
                    old_text = git_show("HEAD", str(content_file.relative_to(ROOT)))

                    if old_text is not None:
                        # summarize_md retorna lista de linhas (markdown)
                        summary_lines = summarize_md(nr_id, old_text, new_text)
                        # Parse das linhas para extrair itens estruturados
                        items = parse_summary_items(summary_lines)
                        logger.debug(f"  {nr_id}: {len(items)} items extraídos do diff")
                    else:
                        logger.debug(f"  {nr_id}: git_show falhou, ignorando diff granular")
                else:
                    logger.debug(f"  {nr_id}: arquivo .md não encontrado em disco")
            except Exception as e:
                logger.warning(f"  {nr_id}: erro ao gerar diff granular: {e}")
                # items continua vazio, cai para summary genérico

            # Gera summary a partir dos items
            summary = generate_summary(items)

        new_entries.append({
            "nr_id": nr_id,
            "title": nr.get("title"),
            "portaria": nr.get("portaria"),
            "hash": new_hash,  # novo: md hash (para detectar mudança real de conteúdo)
            "pdf_hash": nr.get("pdf_hash"),  # preserva para compatibilidade/auditoria
            "summary": summary,
            "items": items,  # novo: diff granular
            "created_at": datetime.now(timezone.utc).isoformat(),
        })
        logger.info(f"  {nr_id}: {summary} ({len(items)} items)")

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
