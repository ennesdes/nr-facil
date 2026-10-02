# Fonte da verdade (SSOT)

> **Uma regra = um arquivo dono.** Índices só linkam. Planos `.claude/plans/` e chat **não** são SSOT após merge.

## Princípio

| Situação | Ação |
|----------|------|
| Mesma **Se → Então** em dois arquivos versionados | Bug de doc — manter dono, apagar cópia no mesmo PR |
| Índice (`FEATURE.md`, `screens_flow`) | Máx. 1 frase + link — sem tabelas de regra |
| Arquivo de regra > **500 linhas** | Fatiar por tópico no mesmo dono lógico |

## Matriz — onde editar

| Tipo | SSOT (editar aqui) | Índices (só link) |
|------|-------------------|-------------------|
| Regra de **feature** | `spec/capabilities/<feature>/*.md` | `app/lib/features/<feature>/FEATURE.md` |
| **Pipeline** (monorepo) | `spec/capabilities/pipeline/*.md` | [`scripts/README.md`](../scripts/README.md) |
| **Conteúdo normativo** (sync, hash, manifest) | `spec/standards/domain/content/*.md` · índice `domain/content.md` | [`docs/architecture.md`](../docs/architecture.md) |
| **Checklist NR-28** | `spec/standards/domain/compliance/*.md` · índice `domain/compliance.md` | [`docs/compliance-checklist-cobertura.md`](../docs/compliance-checklist-cobertura.md) |
| **Transversal** (nav global) | `spec/standards/ui/screens_flow.md` | capabilities por feature |
| **Copy** literal | `spec/standards/ui/copy_voice.md` | capability → seção de copy |
| **Visual** | `spec/standards/ui/design_system.md`, `content_quality.md` | [`docs/brand.md`](../docs/brand.md), [`docs/design-system.md`](../docs/design-system.md) |
| **Decisão** | `.claude/decisions/<slug>.md` | link na capability/standard afetado |
| **Backlog** | [`todo.md`](../todo.md) | proibido em capabilities e domain |
| **Procedimentos** | `docs/procedures/*` | não SSOT de comportamento |
| **Mapa de código** | `spec/standards/core/code_map.md` | |
| **Entrega em curso** | `spec/demands/active/<slug>/spec.md` | promover para capability/standard no merge |
| **E2E ids** | `app/lib/core/constants/e2e_semantics_ids.dart` | `.maestro/flows/ci/` |
| **Implementação** | `app/`, `scripts/`, `content/` | nunca SSOT de produto |

## Features (capabilities)

| Feature | Índice código | Regras |
|---------|---------------|--------|
| home · reader · search · updates · compliance · settings · ads | `app/lib/features/<f>/FEATURE.md` | `spec/capabilities/<f>/` |
| pipeline | `scripts/README.md` | `spec/capabilities/pipeline/` |

## Domínio (fatiado)

| Área | Índice |
|------|--------|
| Conteúdo / sync | `spec/standards/domain/content.md` → `domain/content/*.md` |
| Compliance | `spec/standards/domain/compliance.md` → `domain/compliance/*.md` |
| Sync remoto (GitHub raw) | `spec/standards/domain/content_sync.md` |

## Algoritmo

1. Tocou `app/lib/features/<f>/views/` → `spec/capabilities/<f>/` + `FEATURE.md` se rotas/estrutura mudaram.
2. Tocou `scripts/` de pipeline → `spec/capabilities/pipeline/` + fatia em `domain/content/` se regra durável.
3. Só string → `spec/standards/ui/copy_voice.md`.
4. Global → `screens_flow.md` — não replicar por feature.
5. Decisão → `.claude/decisions/` → atualizar dono da matriz.
6. UI checklist → `validation/ui_ux.md` + capability dona.

## Governança IA

- Doc-first no **dono SSOT**, mesmo PR que código.
- Proibido: regra nova só em plano, `CLAUDE.md` ou stub `.mdc` sem atualizar `spec/`.
- Gates: `scripts/check_feature_docs.py` · `scripts/check_spec_demand.py`
