# Home — sync e download

> **SSOT:** interação com `ContentService` nas listas.

## Regras

| Condição | Então |
|----------|--------|
| Primeiro uso / manifest novo | Sync incremental por hash |
| Download por NR | Baixa `.md`, assets, índices para cache local |
| Offline | Listas usam cache; mensagens compreensíveis se faltar arquivo |
| Card atualizações pendentes (home) | Pode ser dispensado; snapshot em `StorageKeys.pendingUpdatesCardDismissedSnapshot` |

## Verificar atualizações

Ação em Ajustes refetch manifest — ver [`../settings/01-ajustes.md`](../settings/01-ajustes.md).

Domínio: [`../../standards/domain/content_sync.md`](../../standards/domain/content_sync.md).
