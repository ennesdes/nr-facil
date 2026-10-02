# Agent Roles — NR Fácil

## Classificar antes de codar

| Escopo | Sinais | Abordagem |
|--------|--------|-----------|
| **Fix** | ≤ 3 arquivos, bug claro, sem regra nova | Implementar direto + spec se regra durável mudou |
| **Feature** | Tela, módulo, integração | Demanda em `spec/demands/active/` ou atualizar capability |
| **Pipeline** | `scripts/`, `content/`, manifest | `python-pipeline` + `spec/capabilities/pipeline/` |
| **Arquitetura** | Novo padrão amplo | Decisão em `.claude/decisions/` + `spec/INDEX.md` |

## Fluxo de produto

Ver `spec/standards/core/product_flow.md`. SSOT: `spec/INDEX.md`.

## Subagentes (Cursor)

| Agente | Quando |
|--------|--------|
| flutter-senior | UI/controllers em `app/` |
| python-pipeline | Scripts de conteúdo |
| flutter-reviewer | Gate antes de commit não trivial |
| qa-engineer | Cobertura de testes |
| tech-lead | manifest, app_meta, monetização, CI |

## Checklist antes de declarar "pronto"

- [ ] `./scripts/check.sh`
- [ ] Spec atualizada se regra de produto mudou
- [ ] Strings em pt_BR revisadas (`copy_voice.md`)
- [ ] Tela nova: `validation/ui_ux.md`

## O que a IA não deve fazer sem pedir

- Commit ou push
- Alterar versão em `app/pubspec.yaml` sem pedido
- Adicionar backend (projeto é GitHub raw only)
