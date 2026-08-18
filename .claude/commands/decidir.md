Avalie opções e decida a melhor solução para a demanda/lacuna em $ARGUMENTS, **perguntando ao usuário** em vez de decidir sozinho.

> **Pré-requisito:** `/descobrir <slug>` concluído (ou lacuna `D1`/`D2`... vinda de um `.claude/plans/<slug>.md`).
> **Objetivo:** o usuário escolhe a solução — você prepara as opções, trade-offs e a pergunta; nunca implementa, nunca detalha passos de código.
> **Saída:** `.claude/decisions/<slug>.md` (ou plano atualizado, se for D1/D2... de um plano existente).
> **Próximo passo:** `/plano <slug>`

---

## Princípio central deste comando

Este projeto é conduzido por um único dev. Decisões de produto/arquitetura com trade-off real **não devem ser tomadas pela IA sozinha** — o papel deste comando é:

1. Levantar as opções plausíveis com prós/contras honestos
2. Perguntar ao usuário **com a ferramenta de pergunta interativa** (`AskUserQuestion`), oferecendo as opções como escolhas + espaço para resposta livre
3. Registrar a resposta do usuário como a decisão final, com a justificativa que ele deu

Nunca escolher por conta própria uma opção com trade-off real e apresentar como fato consumado. Se só existe **uma** opção tecnicamente viável (sem trade-off), aí sim pode seguir sem perguntar — mas declare isso explicitamente ("única opção viável, sem trade-off — seguindo direto").

---

## Roteamento automático

### → Redirecionar para `/plano <slug>` diretamente se TODOS os itens forem verdadeiros

- Existe apenas uma opção técnica/produto viável (sem trade-off real)
- Descoberta não registrou lacunas bloqueantes
- `CLAUDE.md`/`docs/architecture.md` já cobrem o comportamento esperado sem ambiguidade

**Ação:** registrar a decisão inline como **Decisões tomadas** no próprio plano e executar `/plano <slug>` diretamente. Não criar arquivo de decisão separado.

### → Perguntar ao usuário (continuar abaixo) se QUALQUER item for verdadeiro

- Dois ou mais caminhos plausíveis com trade-offs reais (custo vs escopo, UX vs esforço, build vs script manual)
- Lacuna bloqueante na descoberta sem resposta em `CLAUDE.md`/`docs/architecture.md`
- Decisão afeta custo de operação (GitHub Actions, serviços externos), fidelidade de conteúdo normativo, ou monetização
- Regra de pipeline nova ou ambígua (ex.: como tratar um caso de scraping que não segue o padrão)

---

## Fora do escopo

Este comando **NÃO** deve:
- gerar código
- alterar `todo.md`
- criar telas ou scripts
- decidir sozinho quando há trade-off real (ver princípio acima)

Apenas **levantar opções, perguntar e persistir a decisão do usuário**.

---

## 0. Identificar o contexto

**Opção A — Nova feature ou solução antes de planejar:**
→ Localizar `.claude/discoveries/<slug>.md`
→ Se não existir: executar `/descobrir <demanda>` primeiro

**Opção B — Lacuna específica dentro de um plano (D1, D2…):**
→ Localizar `.claude/plans/<slug>.md` pelo ID passado em $ARGUMENTS
→ Ler a linha da lacuna na tabela **Decisões abertas**
→ Verificar **Decisões tomadas** — não redecidir o que já está fechado

Se $ARGUMENTS estiver vazio → perguntar qual demanda/lacuna decidir.

---

## 1. Checar se já existe resposta nas regras

Ler `CLAUDE.md` e `docs/architecture.md` (seções relevantes ao escopo).

| Resultado | Ação |
|-----------|------|
| Regra clara já existe | Apontar onde está e **encerrar** — não perguntar ao usuário à toa |
| Decisão já registrada em `todo.md` § "Decisões registradas" | Apontar a linha; só reabrir se o usuário pedir explicitamente para reconsiderar |
| Regra semelhante mas incompleta | Levantar como opção "manter regra + estender" vs alternativas |
| Tema novo ou ambíguo | Continuar para §2 |

---

## 2. Montar as opções (mínimo 2, quando houver trade-off real)

```markdown
### Opção A — <nome>
Prós: ...
Contras: ...
Custo/esforço: ...

### Opção B — <nome>
Prós: ...
Contras: ...
Custo/esforço: ...
```

Se a demanda tocar arquitetura/custo/monetização, considerar mentalmente a perspectiva de um `tech-lead` (arquivos: `docs/architecture.md`) antes de montar as opções — pode acionar o agente `tech-lead` para dar parecer técnico **antes** de perguntar ao usuário, se o trade-off for técnico complexo.

---

## 3. Perguntar ao usuário

Usar `AskUserQuestion` com:
- A pergunta central em uma frase clara
- Cada opção como choice, com a descrição resumindo prós/contras (a IA já mastigou o trade-off, o usuário só escolhe ou digita algo diferente)
- Sempre permitir resposta livre (a ferramenta já oferece "Other" automaticamente)

Se houver mais de uma lacuna independente na mesma rodada, agrupar em uma única chamada com múltiplas perguntas (até 4).

---

## 4. Registrar a decisão

```markdown
## Decisão

### Pergunta
<a pergunta feita ao usuário>

### Opções apresentadas
- Opção A — <resumo>
- Opção B — <resumo>

### Escolha do usuário
<opção escolhida ou resposta livre>

### Justificativa (do usuário, quando explicada)
...

### Impacto esperado
- Custo: ...
- Esforço: ...
- Risco: ...
```

---

## 5. Persistir

**Decisão de nova feature (Opção A do §0):**
→ Salvar em `.claude/decisions/<slug>.md`

**Decisão de lacuna dentro de plano (Opção B do §0 — D1, D2…):**
1. **Remover** a linha do ID em **Decisões abertas** do plano
2. **Adicionar** em **Decisões tomadas**: `D1 — <pergunta> → <escolha do usuário> — <justificativa>`
3. Enriquecer a fase afetada com subseção `#### Decisão (referência)` se necessário (parâmetros concretos, alternativas descartadas)
4. Se **Decisões abertas** ficar vazia → escrever `*(nenhuma — plano pronto para /fazer)*`

---

## 6. Confirmar

1. Decisão escolhida em 1 linha (a escolha do usuário, não uma sugestão sua)
2. Arquivo(s) alterado(s)
3. **Próximo passo:**
   - Escopo cabe em 1 fase (≤5 arquivos, 1 feature) → pode pular `/plano` e ir direto para `/fazer <slug>`
   - Múltiplas fases previstas (>5 arquivos ou >1 feature) → `/plano <slug>` continua obrigatório mesmo com todas as decisões resolvidas — é o `/plano` que quebra em fases e define ordem/dependências
   - Plano já existe e não tem mais decisões abertas → `/fazer .claude/plans/<slug>.md`
