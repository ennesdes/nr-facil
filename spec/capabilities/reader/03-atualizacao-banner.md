# Leitor — banner de atualização

> Domínio: [`../../standards/domain/content/update-detection.md`](../../standards/domain/content/update-detection.md).

## Regras

| Condição | Então |
|----------|--------|
| `hasUpdate == true` ao abrir | Banner dispensável no topo do corpo |
| CTA "Ver o que mudou" | Bottom sheet com `items[]` de `app_meta.json` ou `summary` se vazio |
| Usuário fecha banner (X) ou abre CTA | `markNrAsSeen` — grava `last_seen_hash` |
| Sem atualização pendente | Sem banner |

## Não pode

- Marcar como vista automaticamente ao abrir a NR.
- Marcar como vista ao navegar a partir do sino antes da intenção do usuário.
