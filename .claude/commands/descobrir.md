Mapeie o problema e seu impacto para a demanda descrita em $ARGUMENTS.

> **Objetivo:** entender o problema em perspectivas relevantes — sem tomar decisões, sem propor soluções.
> **Saída:** `.claude/discoveries/<slug>.md` — consumido por `/decidir`.
> **Próximo passo:** `/decidir <slug>` — avalia opções antes de planejar.

---

## Roteamento automático — verificar antes de mapear

### → Redirecionar para `/fazer <tarefa>` se TODOS os itens forem verdadeiros

- Bug fix, ajuste de copy/UI, renomear, mover ou extrair constante
- Mudança contida em ≤ 3 arquivos
- Sem regra de pipeline/conteúdo nova e sem tela nova
- Comportamento esperado é óbvio — sem lacunas em aberto

**Ação:** declarar "tarefa simples — redirecionando para `/fazer`" e executar `/fazer <tarefa>` diretamente. Não criar arquivo de descoberta.

### → Mapear (continuar abaixo) se QUALQUER item for verdadeiro

- Feature nova ou comportamento que o usuário não tinha antes
- Toca o pipeline de conteúdo (scraping, extração de PDF, manifest) de forma não trivial
- Envolve tela nova, rota ou fluxo de navegação
- Impacto incerto — não é claro quantos arquivos ou camadas são afetados
- Envolve monetização (AdMob/IAP) ou custo de operação

---

## 0. Entender a demanda

Extrair de $ARGUMENTS:
- **Intenção central** — o que muda para o usuário ou para o pipeline
- **Escopo provável** — app (Flutter/GetX) / pipeline (Python) / app_meta.json / CI
- **Palavras-chave** — termos técnicos que guiarão as buscas
- **Slug** — 2–4 palavras em kebab-case *(mesmo slug usado em `/decidir` e `/plano`)*

Se $ARGUMENTS estiver vazio → perguntar qual é a demanda.

---

## 1. Ler referências relevantes

| Escopo | Ler |
|--------|-----|
| Qualquer alteração | `CLAUDE.md`, `todo.md` |
| Arquitetura/decisões | `docs/architecture.md` |
| Escopo já coberto por prompt existente | `docs/prompts.md` (catálogo I0–I10) |
| App Flutter | seção "App architecture notes" do `CLAUDE.md` + `docs/architecture.md` § App Flutter |
| Pipeline Python | `docs/architecture.md` § Pipeline de conteúdo, § Acesso ao MTE |
| app_meta.json | `docs/architecture.md` § app_meta.json (sem backend) |

---

## 2. Buscar no projeto

```bash
grep -rn "<termo>" app/lib/ --include="*.dart" 2>/dev/null
grep -rn "<termo>" scripts/ --include="*.py" 2>/dev/null
grep -A5 -B2 "<palavra-chave>" todo.md
```

Ler **somente as seções** dos arquivos encontrados que a demanda toca — não ler arquivos inteiros sem necessidade.

---

## 3. Perspectivas

### 3a. Usuário
- Como o usuário percebe o problema hoje (ou a ausência da feature)?
- Isso afeta a leitura offline, a confiança no conteúdo, ou é só conveniência?

### 3b. Produto/Negócio
- Impacto em retenção, ativação (primeiro sync), ou monetização (Fase 5/6)?
- É consistente com o escopo do MVP (`docs/architecture.md` § Escopo MVP)?

### 3c. Técnica
- Arquivos afetados, fluxos impactados (sync, pipeline, app_meta.json)
- Risco de regressão, edge cases (offline, NR revogada, manifest corrompido, falha de scraping)
- Impacto em custo (minutos de GitHub Actions)

### 3d. Fidelidade de conteúdo *(se a demanda toca pipeline/`content/`)*
- Risco de alterar/reescrever texto normativo?
- Muda a forma de detectar update (`pdf_hash`) ou só enriquece metadados?

---

## 4. Lacunas — resolver com o usuário na hora, não só registrar

Toda vez que uma perspectiva acima revelar uma pergunta sem resposta óbvia nas regras existentes (`CLAUDE.md`, `docs/architecture.md`, `todo.md`), **não escreva a lacuna só como texto na tabela e siga em frente**. Em vez disso:

1. Formule a pergunta com **opções concretas** (2–4), cada uma com prós/contras claros — igual a uma decisão real de produto/técnica
2. Use a ferramenta de pergunta ao usuário (`AskUserQuestion`) **na hora**, uma pergunta por lacuna (ou agrupadas se relacionadas), para o usuário escolher a opção ou responder livremente
3. Registre a resposta do usuário como **decisão já tomada** no arquivo de descoberta (seção própria abaixo) — não como lacuna aberta
4. Só deixe uma linha em **Lacunas** (tabela) se a pergunta depender de uma implementação/exploração ainda não feita (não é o caso de decidir agora, é o caso de "não sei ainda o suficiente para nem formular a pergunta direito") — isso continua indo para `/decidir` depois

Ambiguidade que **bloqueia o mapeamento inteiro** (ex.: não dá pra saber nem o escopo técnico sem essa resposta) → perguntar **antes** de continuar as perspectivas, não só ao final.

---

## 5. Persistir

Salvar em `.claude/discoveries/<slug>.md`:

```markdown
# Descoberta — <título>

> Gerado por `/descobrir` · Consumido por `/decidir`

## Demanda
<uma linha: o que vai mudar>

## Perspectiva do usuário
...

## Perspectiva do produto
...

## Perspectiva técnica

| Arquivo | O que muda | Por quê | Risco |
|---------|-----------|---------|-------|
| ... | ... | ... | baixo/médio/alto |

## Fidelidade de conteúdo *(se aplicável)*
...

## Decisões já resolvidas com o usuário nesta sessão

| Pergunta | Opção escolhida | Por quê |
|----------|------------------|---------|
| ... | ... | resposta do usuário via AskUserQuestion |

## todo.md
- [ ] Previsto / [ ] Parcialmente previsto / [ ] Nova demanda
- Linha relevante: "..."

## Lacunas ainda abertas *(só o que genuinamente precisa de mais exploração antes de decidir)*
| ID | Pergunta | Bloqueia |
|----|----------|----------|
| D1 | <decisão necessária> | Sim / Não |

*(Se vazia: `*(nenhuma — todas as dúvidas foram resolvidas com o usuário nesta sessão)*`)*
```

---

## 6. Confirmar

1. **Caminho:** `.claude/discoveries/<slug>.md`
2. Seção **Demanda** na íntegra
3. **N decisões resolvidas nesta sessão** · **N lacunas ainda abertas** *(N bloqueantes)*
4. **Próximo passo:**
   - Lacuna aberta ou opção técnica com trade-off real → `/decidir <slug>`
   - Sem lacuna aberta **e** a Perspectiva técnica couber em 1 fase (≤5 arquivos, 1 feature) → pode pular `/plano` e ir direto para `/fazer <slug>`
   - Sem lacuna aberta mas com múltiplas fases previstas (>5 arquivos ou >1 feature) → `/plano <slug>` continua obrigatório, mesmo sem decisão pendente — é o `/plano` que quebra em fases e define ordem/dependências para o `/fazer`

Não exibir tabelas completas na conversa — o arquivo está disponível para leitura.
