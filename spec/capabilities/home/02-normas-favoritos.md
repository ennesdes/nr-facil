# Home — Normas e Favoritos

> **SSOT:** listagem de NRs, badges e favoritos.

## Normas

| Condição | Então |
|----------|--------|
| NR vigente | Tile normal; download/sync conforme manifest |
| NR revogada | Badge "Revogada", visual esmaecido; toque → `RevokedNrPage` (PDF MTE + sucessora se houver) |
| Revogadas | **Não** indexadas em busca global |

## Favoritos

| Condição | Então |
|----------|--------|
| Toggle favorito | Persiste em `StorageKeys.favoriteNrs` |
| NR revogada favoritada | Lista esmaecida com aviso |
| Lista vazia | Estado vazio dedicado |

## Revogada — ações

- "Ver PDF oficial (histórico)" — link externo MTE, sem cache local.
- "Ver NR vigente" — só se `substitui_por` no índice dinâmico (`discover_nrs.py`).
