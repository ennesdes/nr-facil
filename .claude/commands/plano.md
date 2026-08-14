Crie um plano detalhado para a demanda descrita em $ARGUMENTS.

> **Saída:** arquivo `.claude/plans/<slug>.md` — artefato pronto para `/decidir` (se sobrar lacuna) e `/fazer`.
> **Princípio:** planejamento separado de descoberta e decisão — não repetir buscas; transformar descoberta + decisão em plano acionável.

---

## Roteamento automático — verificar antes de criar o plano

### → Redirecionar para `/fazer <tarefa>` se TODOS os itens forem verdadeiros

- Mudança contida em ≤ 3 arquivos
- Sem regra de pipeline/conteúdo nova
- Sem tela nova ou fluxo de navegação novo
- Comportamento esperado é óbvio — sem lacunas que exijam decisão

**Ação:** declarar "tarefa simples — redirecionando para `/fazer`" e executar `/fazer <tarefa>` diretamente. Não criar arquivo de plano.

### → Criar plano (continuar abaixo) se QUALQUER item for verdadeiro

- Feature nova ou comportamento que o usuário não tinha antes
- Toca pipeline de conteúdo, Supabase ou monetização de forma não trivial
- Tela nova ou mudança de rotas
- Impacto em ≥ 4 arquivos
- Múltiplas fases ou dependências entre entregas

---

## Pré-requisito — descoberta e decisão existentes

Fluxo completo para features novas:

1. `/descobrir <demanda>` → `.claude/discoveries/<slug>.md`
2. `/decidir <slug>` → `.claude/decisions/<slug>.md` *(ou inline no plano, se simples)*
3. `/plano <slug>`

Para itens já definidos no `todo.md` com escopo claro (ex.: prompts I0–I10 de `docs/prompts.md`), pode ir direto para `/plano`.

### Como localizar a descoberta

- Caminho canônico: `.claude/discoveries/<slug>.md` *(mesmo `slug` do plano)*
- Se `$ARGUMENTS` apontar para o arquivo → usar esse arquivo
- Senão → procurar o arquivo correspondente à demanda

### Se a descoberta não existir

1. Executar `/descobrir <demanda>`
2. Executar `/decidir <slug>` se feature nova/complexa
3. Retomar `/plano` consumindo os arquivos gerados

### Proibido

- Repetir `grep`/leituras já presentes na descoberta
- Inventar decisões para preencher lacunas — registrar em **Decisões abertas** ou decidir com fundamento em **Decisões tomadas** *(só se a resposta estiver nas regras)*

---

## 0. Consumir descoberta e decisão *(não pesquisar de novo)*

Abrir `.claude/discoveries/<slug>.md` e `.claude/decisions/<slug>.md` (se existir) e extrair:

| Seção | Fonte | Uso no plano |
|-------|-------|--------------|
| Demanda | discoveries | Resumo executivo + Escopo |
| Perspectiva técnica | discoveries | Fases + Impacto estimado |
| Decisões já resolvidas com o usuário | discoveries | **Decisões tomadas** |
| Lacunas ainda abertas | discoveries | **Decisões abertas** |
| Escolha do usuário + justificativa | decisions | **Decisões tomadas** + fundamento |

Registrar no plano, no topo do detalhamento:

```markdown
> **Descoberta:** `.claude/discoveries/<slug>.md`
> **Decisão:** `.claude/decisions/<slug>.md` *(se existir)*
```

---

## 1. Resolver lacunas restantes *(só planejamento — sem busca; sem inventar)*

Para cada lacuna que sobrou do estudo:

| Situação | Ação |
|----------|------|
| Resposta clara em `CLAUDE.md`/`docs/architecture.md` | **Decisões tomadas** — com fundamento |
| Escolha de produto/técnica ainda em aberto | **Decisões abertas** — ID `D1`, `D2`… usuário resolve com `/decidir D1` **antes** do `/fazer` |
| Ambiguidade bloqueia o plano inteiro | Perguntar ao usuário diretamente (`AskUserQuestion`) **antes** de criar o arquivo — não adiar para depois |

**Regras:**

- Não criar plano com item **Bloqueia = Sim** ainda aberto em Decisões abertas
- Itens **Bloqueia = Não** podem ficar abertos — mas `/fazer` **não** executa enquanto houver linha aberta e bloqueante na tabela
- Nunca inventar parâmetro, copy ou comportamento para "completar" o plano

---

## 2. Escrever o plano

Criar `.claude/plans/<slug>.md` — **mesmo `slug` da descoberta vinculada**.

### Granularidade das fases *(obrigatório)*

Nenhuma fase pode exigir mais de:
- **5 arquivos principais**, **OU**
- **1 feature completa**

Se exceder → dividir em nova fase antes de salvar. Cada fase deve ser executável de forma incremental.

### Estrutura obrigatória do arquivo

```markdown
# Plano — <título claro da demanda>

> **Descoberta:** `.claude/discoveries/<slug>.md`
> **Decisão:** `.claude/decisions/<slug>.md` *(se existir)*

## O que será feito e por quê
> Leitura de 30 segundos — direção antes dos detalhes.

- **<tópico 1>** — <por quê>
- **<tópico 2>** — <por quê>
_(máx. 6 tópicos; se precisar de mais, dividir em planos separados)_

## Escopo
<O que entra neste plano — app, pipeline, Supabase, CI. Bullets objetivos.>

## Fora de escopo
- Não alterar <ex.: schema Supabase>
- Não migrar <ex.: telas existentes fora do fluxo>
- Não refatorar <ex.: componentes não relacionados>

## Impacto estimado

### App Flutter
- <N telas | widgets | rotas | Nenhum>

### Pipeline Python
- <N scripts | Nenhum>

### Supabase / manifest
- <Nenhum | tabelas | schema do manifest.json>

### Testes
- <N cenários previstos>

## Referências

| Arquivo | Seções utilizadas |
|---------|-------------------|
| `docs/architecture.md` | <seção> |
| `docs/prompts.md` | <prompt Ix, se aplicável> |
| `todo.md` | <item> |

## Decisões tomadas

| Decisão | Escolha | Fundamento |
|---------|---------|------------|
| ... | ... | regra em `CLAUDE.md`/`docs/architecture.md` ou escolha do usuário via `/decidir` |

## Decisões abertas

| ID | Pergunta | Impacto | Bloqueia |
|----|----------|---------|----------|
| D1 | <pergunta> | Produto / UX / Custo / Arquitetura | Sim / Não |

*(Se vazia: `*(nenhuma — plano pronto para /fazer)*`)*

Resolver com `/decidir D1` — uma decisão por sessão.

## Riscos

| Risco | Impacto | Mitigação |
|-------|---------|-----------|
| <ex.: regra de scraping ambígua> | Médio | Abrir D1 em Decisões abertas |
| <ex.: custo Supabase/Actions> | Alto | Estimar volume antes de implementar |

## Dependências entre fases

Fase 2 depende de:
- Fase 1 concluída — <entregável concreto>

---

## Detalhamento

### Fase 1 — <nome>
**Objetivo:** <resultado concreto desta fase>
**Arquivos:** `app/lib/...` ou `scripts/...` *(máx. 5 principais)*
**Agente sugerido:** `flutter-senior` (app) · `python-pipeline` (scripts) · `tech-lead` (Supabase/arquitetura/custo)
**Depende de:** *(nenhuma | Fase N)*

#### Passos
1. <passo específico com arquivo e comportamento esperado>
2. ...

#### Testes desta fase
- Caminho feliz: <cenário>
- Falha: <cenário>
- Edge case: <offline, NR revogada, manifest corrompido, scraping fora do padrão>

---

### Fase 2 — <nome>
_(mesma estrutura — respeitar limite de 5 arquivos ou 1 feature)_

---

## Critérios de aceite

### CA1 — <nome curto>
**Dado** <pré-condição>
**Quando** <ação>
**Então** <resultado observável>

### CA2 — <nome curto>
...

## Checklist de entrega
- [ ] Descoberta vinculada em `.claude/discoveries/<slug>.md`
- [ ] Decisões abertas resolvidas *(ou nenhuma)*
- [ ] `fvm flutter analyze --fatal-infos` sem erros (se tocou app/)
- [ ] `validate_manifest.py` passa (se tocou manifest/pipeline)
- [ ] Testes: caminho feliz + falha + edge case
- [ ] `todo.md` atualizado com `[x]` + item marcado, quando aplicável
- [ ] `docs/architecture.md` atualizado se comportamento novo introduzido

## Contexto para /fazer

> Seção de consumo direto — `/fazer` lê **esta seção primeiro**, depois a fase indicada.

**Objetivo:**
<Uma frase — o que "pronto" significa para este plano>

**Arquivos previstos:**
- `app/lib/...` ou `scripts/...`
- `test/...`

**Não fazer:**
- <itens de Fora de escopo repetidos ou refinados>
- Não expandir escopo além das fases
- Não re-pesquisar — usar plano + docs citados

**Critérios obrigatórios:**
- Todos os CA1…CAn verificados
- Decisões tomadas respeitadas
- Fases na ordem das Dependências

**Ordem de execução sugerida:**
1. Fase 1 → …
2. Fase 2 → …
```

---

## 3. Confirmar

Após criar o arquivo, exiba:

1. **Caminho do plano** — `.claude/plans/<slug>.md`
2. **Descoberta vinculada** — `.claude/discoveries/<slug>.md`
3. Seção **"O que será feito e por quê"** na íntegra
4. Uma linha: **N fases** · agentes · **N critérios de aceite**
5. **Próximo passo sugerido:**
   - Decisões abertas → `/decidir D1` *(uma por sessão)*
   - Plano completo → `/fazer .claude/plans/<slug>.md`

Não exiba o detalhamento completo na conversa — o arquivo está disponível para leitura.
