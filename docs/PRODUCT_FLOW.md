# Fluxo de construção de produto

Ordem obrigatória antes de implementar qualquer site ou app.
Tecnologia e código vêm **depois** do produto estar definido.

```
PROBLEMA → USUÁRIO → ESCOPO → FLUXOS → REGRAS → ARQUITETURA
    → DESIGN SYSTEM → UI → (agentes/comandos) → IMPLEMENTAÇÃO → VALIDAÇÃO → ITERAÇÃO
```

**Agentes e comandos são camada de execução** — não substituem descoberta de produto.

---

## 1. Problema

> Por que esse produto precisa existir?

Defina o problema em uma frase. Sem stack, sem telas.

## 2. Usuário

> Para quem estou resolvendo isso?

Quem usa, contexto, frequência, ambiente, dificuldade atual.

## 3. Escopo / funcionalidades

> O que o produto precisa fazer?

Liste **capacidades** (não telas). Separe MVP do que fica para depois.

## 4. Fluxos

> Como o usuário realiza cada coisa?

Jornadas passo a passo. Exponha edge cases: offline, erro, permissão, estado vazio.

## 5. Regras de negócio

> O que pode e o que não pode acontecer?

Escreva em linguagem de produto — independente de Flutter, Astro ou banco.

## 6. Arquitetura

> Como vamos construir isso?

Stack, camadas, persistência, auth, sync, navegação, infra. Decisões técnicas aqui.

## 7. Design system

> Como o produto se comporta visualmente?

Tokens, componentes reutilizáveis, estados (loading, erro, vazio).

## 8. UI / telas

Fluxos + regras + design system → telas e seções concretas.

## 9. Agentes e comandos

Organizam a **execução** com IA — depois que as fases 1–8 estão claras o suficiente.

## 10. Implementação

Modelos → repositórios → services → controllers → UI → testes.

## 11. Validação

Funciona? Correto? Usável? Consistente? Performance? Acessibilidade? Estados de erro?

## 12. Iteração

Ajustar com base em uso real e feedback.

---

## Estados (transversal)

Para cada funcionalidade, definir antes de codar:

```
Sucesso | Erro | Loading | Vazio | Offline | Sem permissão | Primeiro uso
```

---

## Regra de ouro

**Não implementar o que ainda não está suficientemente definido.**

1. O que deve acontecer
2. Quais são as regras
3. Como será construído
4. Só então: construir (com ou sem IA)

---

## Mapeamento com comandos (projetos maduros)

| Fase do fluxo | Comando típico |
|---------------|----------------|
| 1–4 Problema, usuário, escopo, fluxos | `/descobrir` |
| 5–6 Regras e arquitetura | `/decidir` |
| 7–8 Design system e UI | `/plano` |
| 10 Implementação | `/fazer` |
| 11 Validação | `/revisar` |

Fix pontual (≤ 3 arquivos, escopo claro) pode pular direto para implementação.
