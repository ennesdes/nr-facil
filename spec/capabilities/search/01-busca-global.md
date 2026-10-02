# Busca global

> **SSOT:** aba **Buscar** na bottom nav.

## Regras

| Condição | Então |
|----------|--------|
| Fonte | Chunks de `search_index.json` por NR baixada |
| Performance alvo | Resposta < 1s em dispositivo típico |
| Resultado | Tile com highlight; abre leitor na âncora quando aplicável |
| Chip "Só favoritos" | Filtra às NRs favoritadas |
| NR revogada | Fora do índice de busca |

## Estados

| Estado | Comportamento |
|--------|---------------|
| Vazio | Orientar a baixar NRs ou ampliar termo |
| Offline | Busca no cache local já sincronizado |
| Erro | Mensagem via `user_messages` |
