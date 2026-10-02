# Documentação antes do código

> **Regra:** nada entra no código sem estar previsto na documentação do projeto. A documentação descreve **o quê** e **por quê**; o código decide **como**.

## Escopo da documentação

| Tipo | Onde | Conteúdo |
|------|------|----------|
| **SSOT / matriz** | `spec/INDEX.md`, `spec/README.md` | Onde editar cada tipo de regra |
| **Regras de feature** | `spec/capabilities/<feature>/` | Se → Então, estados, fluxos |
| **Engenharia / UI** | `spec/standards/` | Arquitetura, copy, design, validação |
| **Domínio** | `spec/standards/domain/` | Conteúdo normativo, sync, compliance |
| **Planos de implementação** | `.claude/plans/*.md` | Ordem de construção — **não** SSOT após merge |
| **Decisões** | `.claude/decisions/<slug>.md` | Trade-offs registrados |
| **Backlog / histórico** | `todo.md` (raiz) | Fases e itens — sem duplicar regras |
| **Índice técnico por feature** | `app/lib/features/<f>/FEATURE.md` | Rotas, arquivos — link para capability |
| **Procedimentos** | `docs/procedures/` | Play Console, keystore, etc. |
| **Índice técnico monorepo** | `docs/architecture.md` | Fluxo de dados + links para `spec/` |

**Proibido:** regra nova só em plano, chat ou stub `.cursor/rules/` sem atualizar `spec/`.

## Ordem obrigatória

1. Localizar dono em `spec/INDEX.md`
2. Se a mudança **não** estiver descrita → atualizar spec **antes** do código (ou no mesmo PR)
3. Implementar
4. Decisão nova → atualizar spec no mesmo PR
5. Remover código, assets e docs obsoletos no mesmo PR

**Exceção:** bug trivial sem impacto de produto (typo, crash óbvio).

## Limpeza ao alterar

| Tipo | Ação |
|------|------|
| Regra substituída | Apagar texto duplicado no mesmo PR |
| Feature removida | Capability + `FEATURE.md` + testes |
| String morta | Remover do Dart e de `copy_voice.md` se era SSOT de copy |

## Gates

- `python3 scripts/check_feature_docs.py` — views sem doc no diff
- `python3 scripts/check_spec_demand.py` — demanda ativa incompleta
- `./scripts/check.sh` — analyze, test, manifest, etc.
