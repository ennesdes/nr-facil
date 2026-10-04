# Home — sync e download

> **SSOT:** interação com `ContentService` nas listas.

## Regras

| Condição | Então |
|----------|--------|
| Primeiro uso / manifest novo | Sync incremental por hash |
| Download por NR | Baixa `.md`, assets, índices para cache local |
| Offline | Listas usam cache; mensagens compreensíveis se faltar arquivo |
| Card “Normas para revisar” (home) | Toque abre sheet de diff; “Ocultar aviso” só dispensa o card (`pendingUpdatesCardDismissedSnapshot`) — **não** conclui revisão |

## Verificar atualizações

Ação na tela do sino — ver [`../updates/01-tela-atualizacoes.md`](../updates/01-tela-atualizacoes.md).

Domínio: [`../../standards/domain/content_sync.md`](../../standards/domain/content_sync.md).
