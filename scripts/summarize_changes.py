#!/usr/bin/env python3
"""Resume, em linguagem humana, o que mudou no conteúdo normativo entre um ref git e o working tree.

Compara o markdown de cada NR alterada (content/nr-XX/nr-XX.md) item a item
(ex.: "10.4.2") e classifica cada item como novo, removido ou alterado — em vez
de só listar "arquivo X mudou". Também aponta mudanças de vigência em
meta.json (publicado_em, vigente_desde, ultima_alteracao).

Usado pelo workflow atualizar-nrs (job summary + changelog mensal).
"""
from __future__ import annotations

import argparse
import difflib
import json
import re
import subprocess
from pathlib import Path

from _common import ROOT

ITEM_MARKER_RE = re.compile(r"^\*\*(\d+(?:\.\d+)+)\*\*", re.MULTILINE)
VIGENCIA_CAMPOS = ["publicado_em", "vigente_desde", "ultima_alteracao"]
MAX_ITEMS_PER_NR = 30


def git_show(ref: str, path: str) -> str | None:
    """Conteúdo de `path` em `ref`, ou None se o arquivo não existir nesse ref."""
    result = subprocess.run(
        ["git", "show", f"{ref}:{path}"],
        cwd=ROOT, capture_output=True, text=True,
    )
    return result.stdout if result.returncode == 0 else None


def changed_files(ref: str, pathspec: str) -> list[str]:
    result = subprocess.run(
        ["git", "diff", "--name-only", ref, "--", pathspec],
        cwd=ROOT, capture_output=True, text=True, check=True,
    )
    return [line for line in result.stdout.splitlines() if line.strip()]


def parse_items(text: str) -> dict[str, str]:
    """Extrai {'10.4.2': 'texto do item'} de um markdown de NR.

    O corpo do item vai até o próximo marcador **X.Y**, e é normalizado
    (espaços/quebras de linha colapsados) para que reflow do PDF (mesma
    frase quebrada em linhas diferentes entre extrações) não seja
    confundido com uma alteração normativa real.
    """
    markers = list(ITEM_MARKER_RE.finditer(text))
    items: dict[str, str] = {}
    for i, m in enumerate(markers):
        start = m.end()
        end = markers[i + 1].start() if i + 1 < len(markers) else len(text)
        body = " ".join(text[start:end].split())
        if body:
            items[m.group(1)] = body
    return items


def truncate(text: str, limit: int = 140) -> str:
    text = " ".join(text.split())
    return text if len(text) <= limit else text[:limit].rstrip() + "…"


def diff_snippet(old: str, new: str, context: int = 6) -> tuple[str, str, int]:
    """Isola, em nível de palavra, só o trecho que mudou entre `old` e `new`.

    Evita mostrar dois prefixos de 140 caracteres praticamente idênticos quando
    a diferença real está mais adiante no item — mostra a região que de fato
    mudou, com `context` palavras de cada lado. Retorna (antes, depois,
    quantidade de outras regiões que também diferem).
    """
    old_words, new_words = old.split(), new.split()
    sm = difflib.SequenceMatcher(None, old_words, new_words, autojunk=False)
    ops = [op for op in sm.get_opcodes() if op[0] != "equal"]
    if not ops:
        return "", "", 0

    _tag, i1, i2, j1, j2 = ops[0]
    antes = " ".join(old_words[max(i1 - context, 0):min(i2 + context, len(old_words))])
    depois = " ".join(new_words[max(j1 - context, 0):min(j2 + context, len(new_words))])
    return antes, depois, len(ops) - 1


def item_sort_key(item: str) -> tuple[int, ...]:
    return tuple(int(p) for p in item.split("."))


def summarize_md(nr_id: str, old_text: str | None, new_text: str) -> list[str]:
    if old_text is None:
        return [f"### {nr_id.upper()}", "- 🆕 Conteúdo adicionado pela primeira vez."]

    old_items = parse_items(old_text)
    new_items = parse_items(new_text)

    added = sorted(set(new_items) - set(old_items), key=item_sort_key)
    removed = sorted(set(old_items) - set(new_items), key=item_sort_key)
    changed = sorted(
        (k for k in set(old_items) & set(new_items) if old_items[k] != new_items[k]),
        key=item_sort_key,
    )
    total = len(added) + len(removed) + len(changed)
    if total == 0:
        return []

    lines = [f"### {nr_id.upper()}"]
    shown = 0
    for item in added:
        if shown >= MAX_ITEMS_PER_NR:
            break
        lines.append(f"- 🆕 Novo item **{item}**: {truncate(new_items[item])}")
        shown += 1
    for item in removed:
        if shown >= MAX_ITEMS_PER_NR:
            break
        lines.append(f"- ❌ Item removido **{item}**: {truncate(old_items[item])}")
        shown += 1
    for item in changed:
        if shown >= MAX_ITEMS_PER_NR:
            break
        antes, depois, outras = diff_snippet(old_items[item], new_items[item])
        lines.append(f"- ✏️ Item alterado **{item}**")
        lines.append(f"  - antes: …{truncate(antes, 160)}…")
        lines.append(f"  - depois: …{truncate(depois, 160)}…")
        if outras:
            lines.append(f"  - (+{outras} outro(s) trecho(s) diferente(s) neste item)")
        shown += 1
    if total > shown:
        lines.append(f"- … +{total - shown} outra(s) alteração(ões) de item omitida(s) (mudança grande — ver diff completo do commit)")
    return lines


def summarize_meta(nr_id: str, ref: str, path: str) -> list[str]:
    old_raw = git_show(ref, path)
    if old_raw is None:
        return []
    try:
        old_meta = json.loads(old_raw)
        new_meta = json.loads((ROOT / path).read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return []

    diffs = []
    for campo in VIGENCIA_CAMPOS:
        antes, depois = old_meta.get(campo), new_meta.get(campo)
        if antes != depois:
            diffs.append(f"- 📅 `{campo}`: {antes!r} → {depois!r}")
    return diffs


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--ref", default="HEAD", help="Ref git para comparar (padrão: HEAD)")
    args = parser.parse_args()

    md_files = changed_files(args.ref, "content/*/nr-*.md")
    meta_files = changed_files(args.ref, "content/*/meta.json")

    blocks: dict[str, list[str]] = {}
    for path in md_files:
        nr_id = Path(path).parent.name
        full_path = ROOT / path
        old_text = git_show(args.ref, path)
        if not full_path.exists():
            if old_text is not None:
                blocks[nr_id] = [f"### {nr_id.upper()}", "- 🗑️ Conteúdo removido (NR retirada do índice)."]
            continue
        new_text = full_path.read_text(encoding="utf-8")
        lines = summarize_md(nr_id, old_text, new_text)
        if lines:
            blocks[nr_id] = lines

    for path in meta_files:
        nr_id = Path(path).parent.name
        meta_lines = summarize_meta(nr_id, args.ref, path)
        if meta_lines:
            blocks.setdefault(nr_id, [f"### {nr_id.upper()}"]).extend(meta_lines)

    if not blocks:
        print("Sem mudanças de conteúdo normativo detectadas (itens e vigência inalterados).")
        return

    for nr_id in sorted(blocks):
        print("\n".join(blocks[nr_id]))
        print()


if __name__ == "__main__":
    main()
