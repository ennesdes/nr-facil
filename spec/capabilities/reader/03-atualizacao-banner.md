# Leitor — banner de atualização

> Domínio: [`../../standards/domain/content/update-detection.md`](../../standards/domain/content/update-detection.md).

## Regras

| Condição | Então |
|----------|--------|
| `hasUpdate == true` ao abrir | Banner dispensável no topo do corpo |
| CTA “Toque para ver o que mudou” | Bottom sheet com diff; `acknowledgeNrUpdate` (`sheetView`) ao exibir |
| Usuário fecha banner (X) | `acknowledgeNrUpdate` (`bannerDismiss`) |
| Sem atualização pendente | Sem banner |

## Não pode

- Marcar como revisada automaticamente só por abrir a NR.
- Concluir revisão ao tocar “Abrir norma” na tela Atualizações.
