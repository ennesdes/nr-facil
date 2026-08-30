# Decisão — Melhorar UX/UI do feed de atualizações de NR

> Gerado por `/decidir` · Insumo: `.claude/discoveries/feed-atualizacoes-ux.md` · Consumido por `/plano`

## Contexto
A descoberta (`feed-atualizacoes-ux.md`) já registrou 2 decisões (resumo granular por item; banner no leitor) e deixou 4 lacunas bloqueantes/relevantes em aberto (D1–D4). Nenhuma delas tinha resposta em `CLAUDE.md`, `docs/architecture.md` ou na seção "Decisões registradas (não reabrir)" do `todo.md` — todas envolviam trade-off técnico real, então foram levadas ao usuário.

## D1 — Fonte única de "a NR mudou"

### Pergunta
Duas fontes distintas hoje decidem "a NR mudou": `build_app_meta.py` usa `pdf_hash` (hash do PDF original); o app usa `hash` (do markdown convertido) via `ContentService.hasUpdate`. Qual deve ser a fonte única para decidir quando gerar uma entrada em `app_meta.json`?

### Opções apresentadas
- **Usar hash do markdown** — alinha com o que o app já usa; `pdf_hash` continua só em `update_nrs.py` (decidir se reprocessa o PDF)
- Usar pdf_hash em tudo — exigiria mudar a lógica de sync já em produção no app
- Manter as duas fontes separadas — aceita o risco de divergência

### Escolha do usuário
**Usar hash do markdown (Recomendado)**

### Impacto esperado
- Custo: nenhum (sem serviço novo)
- Esforço: baixo — `build_app_meta.py` passa a comparar `hash` em vez de `pdf_hash` na lógica de `last_hash_by_nr`/detecção de mudança; `pdf_hash` permanece com seu uso atual em `update_nrs.py`, sem mexer no app
- Risco: baixo — elimina a divergência descrita na descoberta sem tocar em código já em produção no app (`ContentService`, `last_synced_hash`/`last_seen_hash`)

## D2 — Reuso do diff granular (`summarize_changes.py` → `build_app_meta.py`)

### Pergunta
Como `build_app_meta.py` deve obter o diff granular por item, hoje só gerado por `summarize_changes.py` numa etapa posterior do workflow (compara `HEAD` vs working tree)?

### Opções apresentadas
- **Importar `summarize_md()` diretamente** — reaproveita a função já existente; no ponto em que `build_app_meta.py` roda no workflow, o working tree já reflete o conteúdo novo (ainda não commitado), então a comparação funciona sem reordenar etapas
- Extrair lógica pra `_common.py` — mais alinhado ao padrão do projeto, mas refactor maior num script já em uso
- Rodar `summarize_changes.py` como subprocesso — evita import cruzado, mas exige novo formato de saída (JSON) e acopla por processo externo

### Escolha do usuário
**Importar `summarize_md()` direto (Recomendado)**

### Impacto esperado
- Custo: nenhum
- Esforço: baixo — `build_app_meta.py` importa `summarize_md` (e o necessário para obter `old_text`/`new_text`, ex. `git_show`) de `summarize_changes.py`, chama por NR quando a comparação de hash (ver D1) indicar mudança
- Risco: baixo — reusa lógica já testada/em produção (changelog mensal); não reordena etapas do workflow (`build_app_meta` continua rodando antes de "Registrar changelog mensal", e a comparação via git ainda funciona porque nada foi commitado ainda nesse ponto)

## D3 — Formato do banner no leitor

### Pergunta
Qual comportamento o banner de "NR atualizada" deve ter dentro do leitor?

### Opções apresentadas
- Banner informativo simples — só texto, sem ação
- **Banner com CTA "Ver o que mudou"** — expande/mostra a lista granular de itens alterados (ex. bottom sheet) sem sair do leitor
- Banner que leva à tela de Atualizações — navega pra fora do leitor, reaproveitando UI existente

### Escolha do usuário
**Banner com CTA "Ver o que mudou" (Recomendado)**

### Impacto esperado
- Custo: nenhum
- Esforço: médio — novo componente de UI no leitor (banner dismissível + bottom sheet/expansão com a lista granular); depende do schema decidido em D4 para renderizar os itens
- Risco: médio — precisa decidir o timing de `markNrAsSeen` em relação ao banner (a descoberta já apontou que hoje é marcado como visto antes do usuário ler; isso é detalhe de implementação a resolver no `/plano`, não uma decisão de produto nova)

## D4 — Schema do resumo granular em `app_meta.json`

### Pergunta
Qual estrutura de dado o `app_meta.json` deve usar para guardar o resumo granular por item?

### Opções apresentadas
- Só string mais rica — zero mudança estrutural, mas sem renderização item a item
- **Lista estruturada de itens** (`items: [{item, tipo, resumo}]`) — usa a mesma lista já produzida por `summarize_md()`, permite renderizar cada item separadamente (chips 🆕/❌/✏️), alimentando tanto a tela de Atualizações quanto o banner do leitor; mesmo teto de 30 itens por NR que `summarize_changes.py` já aplica
- String curta + lista estruturada — mais flexível, mais campos pra manter

### Escolha do usuário
**Lista estruturada de itens (Recomendado)**

### Impacto esperado
- Custo: tamanho de `app_meta.json` cresce um pouco por entrada (lista de itens em vez de string única), mas segue limitado pela janela de 200 entradas + teto de 30 itens por NR já existente em `summarize_changes.py` — sem risco de crescimento descontrolado
- Esforço: médio — novo schema de entrada em `app_meta.json` (`items: [{item, tipo, resumo}]` além dos campos atuais); precisa de modelo Dart novo (`AppMeta`/`UpdateEntry`, incluindo os itens) já que hoje não existe nenhum modelo Dart para esse arquivo
- Risco: baixo-médio — schema novo, mas isolado (arquivo gerado, sem migração de dado existente relevante — `app_meta.json` já é regenerado do zero a cada execução da Action a partir do `manifest.json`)

## Resumo das decisões

| ID | Decisão |
|----|---------|
| D1 | `build_app_meta.py` passa a detectar mudança por `hash` (md), não `pdf_hash` |
| D2 | `build_app_meta.py` importa `summarize_md()` de `summarize_changes.py` diretamente |
| D3 | Banner no leitor tem CTA "Ver o que mudou" que expande a lista granular |
| D4 | `app_meta.json` ganha `items: [{item, tipo, resumo}]` estruturado por entrada |

## Escopo resultante (visão geral, sem detalhar passos)
- **Pipeline:** `scripts/build_app_meta.py` (mudar fonte de hash + importar `summarize_md` + novo schema de saída), `scripts/scrape_vigencia.py` (corrigir truncamento de `portaria`), possivelmente ajuste em `generate_summary()` para não produzir mais "Atualizado em None".
- **App:** `app/lib/core/constants/app_config.dart` (URL do `app_meta.json`), novo modelo Dart (`AppMeta`/`UpdateEntry` com `items[]`), `ContentService` (buscar/expor `updates[]` + checar `min_app_version`), `UpdatesPage`/`UpdatesController` (exibir data/portaria/itens), fluxo do leitor (banner + CTA + bottom sheet, ajuste de timing de `markNrAsSeen`).
- Mais de 5 arquivos e mais de uma feature (pipeline de dados + consumo no app + 2 telas novas/alteradas) → **`/plano` continua obrigatório** antes de implementar.
