# Action — isolamento de erro

Workflow: `update-nrs.yml` (cron dias úteis 09:00 UTC + `workflow_dispatch`).

## Ordem

1. discover → 2. update_nrs → 3. scrape_vigencia → 4. convert_nr → 5. build_manifest → 6. build_app_meta → commit

## Por NR

| Condição | Então |
|----------|--------|
| Falha em uma NR | Não atualiza essa NR; mantém versão anterior em `content/` |
| Fim do job com `errors[]` | Exit code ≠ 0 — job vermelho; commit inclui NRs bem-sucedidas |

App nunca depende de uma NR específica ter sucesso na última rodada.
