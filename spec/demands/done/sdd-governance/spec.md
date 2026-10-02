# [SDD-001] Governança Spec-Driven Development

## 1. Visão Geral e Contexto

- **Contexto:** Regras espalhadas em `docs/architecture.md` e `.cursor/rules/` (incluindo cópias do Treino base) geravam drift e risco para agentes.
- **Resultado para o usuário:** Entregas futuras seguem contrato em `spec/`; menos comportamento incorreto sem documentação.
- **Impacto no sistema:** `spec/`, scripts de gate, stubs `.cursor/rules/`, índice `docs/architecture.md`.

---

## 2. Escopo e Limites

### Deve ser feito (in-scope)

- Hub `spec/` (README, INDEX, templates, standards, capabilities, demands).
- Migração de standards; capabilities extraídas de `docs/architecture.md`; gates `check_feature_docs`, `check_spec_demand`.

### Não deve ser feito (out-of-scope)

- Propagar SDD para `dev-standards` global.
- Automatizar Gherkin → testes.
- CI em `push` na `main`.

---

## 3. Arquitetura e Tecnologias

- **Stack:** Markdown no repo; scripts Python nos gates; Cursor stubs `.mdc`.
- **Dependências:** Nenhuma lib nova.

---

## 4. Requisitos Funcionais e Regras de Negócio

### 4.1 Regras e fluxos

1. **SSOT:** `spec/INDEX.md` define donos; código em `app/lib/features/` implementa.
2. **Doc-first:** alteração de `app/lib/features/*/views/` exige `spec/capabilities/<feature>/` ou demanda ativa no diff.

### 4.2 Casos de borda e erros

- **Estados:** N/A (infra de processo).

---

## 5. Especificação Técnica e Contratos

N/A para governança.

---

## 6. Requisitos Não-Funcionais

- **Segurança:** Sem mudança de runtime.
- **Performance:** Gates adicionais só em `./scripts/check.sh` (avisos).

---

## 7. Critérios de Aceitação (BDD)

### CA-SDD-001-01: Matriz SSOT

- **Dado que** um dev altera regra de feature
- **Quando** consulta `spec/INDEX.md`
- **Então** encontra o caminho `spec/capabilities/<feature>/` como dono

### CA-SDD-001-02: Gate de documentação

- **Dado que** o diff altera `app/lib/features/home/views/` sem `spec/capabilities/home/` nem `FEATURE.md`
- **Quando** roda `python3 scripts/check_feature_docs.py`
- **Então** recebe aviso `FEATURE_DOCS`

### CA-SDD-001-03: Demanda ativa válida

- **Dado que** existe pasta em `spec/demands/active/<slug>/spec.md` incompleta
- **Quando** roda `python3 scripts/check_spec_demand.py`
- **Então** recebe aviso `SPEC_DEMAND`

---

## 8. Definition of Done

- [x] `spec/` criado e populado (standards + capabilities)
- [x] Stubs `.cursor/rules/` apontando para `spec/standards/`
- [x] Scripts de gate atualizados
- [x] `CLAUDE.md` e `docs/architecture.md` atualizados
- [x] Esta spec arquivada em `spec/demands/done/sdd-governance/`
