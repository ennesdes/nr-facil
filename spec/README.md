# Spec-Driven Development (SDD) — NR Fácil

> **Canônico:** toda regra de produto, engenharia e domínio vive em `spec/`. Código em `app/lib/` e pipeline em `scripts/` implementam o contrato — não definem o contrato.

## Doc-first

1. Localizar o dono em [`INDEX.md`](INDEX.md).
2. Atualizar **spec** (capability, standard ou demanda ativa) **antes** ou **no mesmo PR** que o código.
3. Proibido: regra nova só em plano `.claude/plans/`, chat ou stub `.cursor/rules/`.

Ver também: [`standards/core/documentation.md`](standards/core/documentation.md).

## Estrutura

| Pasta | Conteúdo |
|-------|----------|
| [`INDEX.md`](INDEX.md) | Matriz SSOT — onde editar cada tipo de informação |
| [`standards/`](standards/) | Engenharia, UI, domínio (conteúdo + compliance), testes, validação |
| [`capabilities/`](capabilities/) | Regras por feature (`home`, `reader`, `pipeline`, …) |
| [`demands/active/`](demands/active/) | Contrato da entrega em curso (`spec.md` por demanda) |
| [`demands/done/`](demands/done/) | Demandas concluídas (histórico) |
| [`_templates/`](_templates/) | Modelos SDD |

## Fluxo de entrega

```
/descobrir → /decidir → spec/demands/active/<slug>/spec.md (+ /plano)
→ /fazer → atualizar spec permanente se regra durável → /revisar → demands/done/
```

- Descoberta/decisão efêmera: `.claude/discoveries/`, `.claude/decisions/`.
- Plano de execução: `.claude/plans/` — roteiro; **não** substitui `spec/` após merge.
- Backlog e histórico de fases: [`todo.md`](../todo.md) na raiz do repo.

## Cursor e agentes

O IDE carrega stubs em [`.cursor/rules/`](../.cursor/rules/index.mdc) que apontam para `spec/standards/`. Conteúdo longo: **só** em `spec/`.

## Anti-regressão (baseline de confiança)

Antes de declarar pronto ou commitar entrega não trivial:

- `./scripts/check.sh` verde
- `python3 scripts/check_feature_docs.py` e `check_spec_demand.py` sem avisos bloqueantes
- Matriz de impacto: [`standards/testing/change_impact.md`](standards/testing/change_impact.md)
- E2E Maestro: `.maestro/flows/ci/` + `scripts/check_e2e_semantics.py`

Novos testes de regressão: comentário `// spec: CA-<demand-id>-NN` ligando ao critério BDD da demanda ou capability.

## Demandas novas

Copiar [`_templates/demand.spec.md`](_templates/demand.spec.md) para `demands/active/<slug>/spec.md`.

Capabilities duráveis: [`_templates/capability.topic.md`](_templates/capability.topic.md).
