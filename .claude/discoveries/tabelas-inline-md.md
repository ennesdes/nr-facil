# Descoberta — Tabelas mal posicionadas, duplicadas e potencialmente falso-positivas no pipeline de conversão

> Gerado por `/descobrir` · Consumido por `/decidir`

## Demanda

Hoje `extract_tables_pass` (Pass 2, `pdfplumber`) extrai tabelas de todo PDF e as referencia como links HTML agrupados no fim do `.md`, sob `## Tabelas` — desconectadas do ponto do texto onde a tabela realmente aparece, e a investigação encontrou dois problemas adicionais: duplicação parcial com o Pass 1 e falso-positivos.

## Perspectiva do usuário

- Hoje, no app Flutter já implementado (`app/lib/features/reader/views/nr_reader_page.dart:255`), o link `> [Tabela N: page X](../assets/tables/...)` é tratado como link externo comum: `onTapLink` → `_launchUrl` → `Uri.parse` + `canLaunchUrl`. Um caminho relativo (`../assets/tables/page_XXX_table_00.html`) não é uma URI válida para `url_launcher`; `canLaunchUrl` deve retornar `false`, e o clique **não faz nada visível** (só loga warning). **Ou seja: hoje, toda tabela do app é, na prática, inacessível ao usuário** — não é só "mal posicionada", está funcionalmente quebrada.
- Mesmo se o link funcionasse, o usuário perde o contexto: lê o artigo normativo, chega ao fim da NR, e só lá encontra uma lista de "Tabela 1, Tabela 2, ... Tabela 47" sem saber a qual trecho cada uma pertence.
- Em ~20% dos casos (ver abaixo) a "tabela" nem é uma tabela — é uma caixa de texto normativo comum que o PDF desenhou com borda, então o usuário veria uma entrada de tabela redundante para conteúdo que ele já leu como parágrafo normal.

## Perspectiva do produto

- Fidelidade de conteúdo é o diferencial do app (ver `project_motivation` em memória) — tabela inacessível ou mal indexada mina a confiança justamente no tipo de conteúdo (limites, classificações de risco) que mais importa em NRs de segurança.
- Não é um item novo do MVP: cai dentro do item **12 "Leitor Markdown + índice lateral + assets"** (já marcado `[x]` no `todo.md`), mas `app/lib/features/reader/IMPLEMENTATION_SUMMARY.md:184` já lista "Tabelas HTML — `flutter_widget_from_html`" como pendência em "Próximos passos (Fase 2+)" — ou seja, o app sabe que isso não foi fechado; é dívida técnica documentada, não regressão nova.
- Afeta as 27 NRs já convertidas (todas as que têm tabela), 573 tabelas no total — escopo real de conteúdo, não caso isolado.

## Perspectiva técnica

| Arquivo | O que muda | Por quê | Risco |
|---------|-----------|---------|-------|
| `scripts/convert_nr.py` (`extract_tables_pass`, `merge_passes`) | Tabela vira Markdown (`\| col \| col \|`) inserida logo após o texto da página correspondente (via `page_chunks=True` do Pass 1), em vez de HTML acumulado no fim | Corrige posição e formato; elimina dependência de `flutter_widget_from_html` (não implementado) | Médio — precisa achar o ponto de inserção certo por página sem quebrar headings já normalizados |
| `scripts/convert_nr.py` (mesma função) | Checagem de duplicação: comparar conteúdo já capturado pelo Pass 1 (que usa `table_strategy='lines_strict'` e às vezes já produz Markdown de tabela inline) antes de adicionar a versão do Pass 2 | Evita tabela dobrada quando os dois passes acertam a mesma tabela | Médio-alto — heurística de "é a mesma tabela" não é trivial (comparar por página + nº de linhas/colunas é o caminho mais simples) |
| `scripts/convert_nr.py` (mesma função) | Filtro de falso-positivo: descartar "tabelas" de 1 coluna (caixas de texto, não dados tabulares) | 118/573 (≈20%) das tabelas hoje extraídas são de 1 coluna — medido diretamente nos HTMLs já commitados | Baixo — heurística simples (`max cols <= 1` → não é tabela) |
| `content/*/nr-*.md` (573 arquivos, 27 NRs) | Reconversão via `python3 scripts/convert_nr.py --nr nr-XX` (nunca editar `.md` à mão — regra do `CLAUDE.md`) | Aplicar o novo formato ao conteúdo já commitado | Baixo — é reprocessamento determinístico do PDF já versionado, reversível via git |
| `app/lib/features/reader/` | Nenhuma mudança obrigatória se a tabela virar Markdown nativo (`flutter_markdown` já renderiza tabelas Markdown padrão) | Remove a necessidade de `flutter_widget_from_html` para os casos que viram Markdown limpo | Baixo — mas tabelas complexas (células mescladas, cabeçalho rotacionado) continuam precisando de fallback HTML/PNG |

### Achado extra: tabela com cabeçalho rotacionado (NR-03, TABELA 3.4, página 5)

Testado empiricamente: **nem o Pass 1 nem o Pass 2 conseguem essa tabela** — ambos produzem saída ilegível (Pass 1: Markdown com colunas "Col4"..."Col16" genéricas e primeira coluna repetida; Pass 2/pdfplumber: célula com texto vertical quebrado caractere-por-caractere, ex. `"la\nu\n)\nt a\na d\n..."`). Isso já está commitado em `content/nr-03/nr-03.md:190` (tentativa inline ruim) **e** `content/nr-03/nr-03.md:260` (link pro HTML igualmente ruim) — ou seja, esse caso específico não é resolvido só reposicionando; precisa do fallback de PNG de página inteira (`assets/pages/page-XXX.png`), que já existe no Pass 3 mas hoje é só comentário oculto no `.md` (`merge_passes`, linha "Imagens das páginas (para fallback)").

## Fidelidade de conteúdo

- Reprocessar via `convert_nr.py` não reescreve texto normativo — é o mesmo pipeline determinístico rodando de novo sobre o mesmo PDF (mesmo `pdf_hash`). Não muda a detecção de update.
- O risco de fidelidade está na direção oposta: a situação **atual** já é a menos fiel (tabela inacessível ou, no caso de cabeçalho rotacionado, ilegível nos dois passes) — qualquer uma das opções em `/decidir` tende a melhorar, não piorar, fidelidade.

## Decisões já resolvidas com o usuário nesta sessão

*(nenhuma — usuário pediu para mapear, decidir e planejar; decisões de trade-off ficam para `/decidir`)*

## todo.md

- [x] Parcialmente previsto — item 12 ("Leitor Markdown + índice lateral + assets") está marcado `[x]`, mas a pendência de tabelas HTML já estava documentada como não fechada em `app/lib/features/reader/IMPLEMENTATION_SUMMARY.md:184` ("Próximos passos Fase 2+"). Esta descoberta fecha essa lacuna específica.

## Lacunas ainda abertas

| ID | Pergunta | Bloqueia |
|----|----------|----------|
| D1 | Quando Pass 1 e Pass 2 capturam a "mesma" tabela, qual mantém (Markdown do Pass 1, HTML do Pass 2, ou tentar sempre gerar Markdown a partir dos dados do Pass 2 que tendem a ser mais limpos)? | Sim |
| D2 | Para tabelas que nenhum dos dois passes consegue legivelmente (cabeçalho rotacionado, células mescladas complexas) — cair para o PNG de página inteira (Pass 3) como conteúdo visível no `.md`, em vez de comentário oculto? | Sim |
| D3 | Filtro de falso-positivo (tabelas de 1 coluna) — descartar sempre, ou só quando o texto já aparece no Pass 1 (evitar descartar uma tabela real de 1 coluna genuína, se existir)? | Não (heurística simples resolve na prática, mas afeta o desenho da função) |
| D4 | Reconversão das 27 NRs (`--all`) depois da mudança — rodar local antes de commitar, ou deixar a próxima execução do `update-nrs.yml` (diária) aplicar? | Não (é decisão operacional, não de arquitetura) |
