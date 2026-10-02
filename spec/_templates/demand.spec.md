# [ID-DEMANDA] Título da Demanda

## 1. Visão Geral e Contexto

- **Contexto:** [Qual problema? Por que existe?]
- **Resultado para o usuário:** [O que a pessoa ganha após a entrega?]
- **Impacto no sistema:** [Features/fluxos afetados — ver `spec/INDEX.md`]

---

## 2. Escopo e Limites

### Deve ser feito (in-scope)

- [Item 1]

### Não deve ser feito (out-of-scope)

- [Item explícito fora desta entrega]

---

## 3. Arquitetura e Tecnologias

- **Stack:** Flutter 3.4+, MVVM, GetX, GetStorage (ver `spec/standards/core/architecture.md`)
- **Dependências / config:** [pacotes, env, feature flags]

---

## 4. Requisitos Funcionais e Regras de Negócio

### 4.1 Regras e fluxos

1. **[Regra 01]:** [Comportamento]
2. **[Regra 02]:** [Comportamento]

### 4.2 Casos de borda e erros

- **Estados:** sucesso, erro, loading, vazio, offline, sem permissão, primeiro uso (os que aplicarem)
- **[Exceção]:** [Comportamento]

Referência domínio: `spec/standards/domain/` · capability: `spec/capabilities/<feature>/`

---

## 5. Especificação Técnica e Contratos

### 5.1 Estado local / remoto

| Origem | Chave / entidade | Tipo | Nulável | Regra |
|--------|------------------|------|---------|-------|
| GetStorage | `StorageKeys.*` | … | … | `fromMap` defensivo |
| GitHub raw | `manifest.json`, `app_meta.json` | JSON | — | só leitura no app |

Fragmento: [`contracts.storage.md`](contracts.storage.md)

### 5.2 Contratos externos

- GitHub raw HTTP, portal MTE (links oficiais) — só o que esta demanda toca.

### 5.3 Rotas e navegação

| Rota / destino | Binding | Arguments |
|----------------|---------|-----------|
| … | … | tipo tipado |

Fragmento: [`contracts.routes.md`](contracts.routes.md)

---

## 6. Requisitos Não-Funcionais

- **Legal:** disclaimer MTE, fidelidade ao PDF — `spec/standards/domain/content/normative-fidelity.md`
- **Performance:** [metas]
- **UX/UI:** `spec/standards/ui/design_system.md`, `copy_voice.md`, `content_quality.md`

---

## 7. Critérios de Aceitação (BDD)

### CA-<demand-id>-01: Fluxo principal

- **Dado que** …
- **Quando** …
- **Então** …

### CA-<demand-id>-02: Erro / borda

- **Dado que** …
- **Quando** …
- **Então** …

---

## 8. Definition of Done

- [ ] Spec permanente atualizada (`spec/capabilities/` ou `spec/standards/`) se regra durável
- [ ] `fvm flutter analyze` e `fvm flutter test` verdes em `app/`
- [ ] Impacto em testes: `spec/standards/testing/change_impact.md`
- [ ] `./scripts/check.sh` sem falhas
- [ ] Testes novos com `// spec: CA-<demand-id>-NN` quando aplicável
