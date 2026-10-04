# Tela de atualizações (sino)

## Escopo

**Inbox** de normas com diff pendente de revisão; badge no sino = contagem de `hasUpdate`. Sem histórico rolante quando a fila está vazia.

## Regras

| Condição | Então |
|----------|--------|
| Lista | Só NRs com `hasUpdate` (não revogadas) |
| Item alterado na lista | `acknowledgeNrUpdate` + abre leitor no trecho |
| “Abrir norma” | Leitor **sem** concluir revisão |
| Só `summary` | Botão “Marcar como revisada” |
| Vazio | “Nada para revisar” + última verificação (`lastSyncedAt`) quando disponível |
| “Verificar atualizações” | `syncMetadata` nesta tela |

## Cenários de aceite (Maestro `04_atualizacoes`)

1. Após sync com novidade: badge + card na home.
2. “Abrir norma” e voltar: badge **permanece**.
3. Abrir sheet pelo card da home e voltar: badge **some**.
4. Tela do sino em estado vazio.

## Grátis vs Pro (futuro)

Fase 6 (IAP): diff textual completo — hoje grátis mostra seções/itens alterados via `summary`/`items`.
