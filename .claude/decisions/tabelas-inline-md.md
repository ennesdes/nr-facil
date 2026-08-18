# Decisão — Tabelas inline, sem duplicação e sem falso-positivo no pipeline

> Gerado por `/decidir` a partir de `.claude/discoveries/tabelas-inline-md.md` · Consumido por `/plano`

## Decisão 1 — Fonte da tabela quando Pass 1 e Pass 2 batem na mesma página

### Pergunta
Quando o Pass 1 (pymupdf4llm) e o Pass 2 (pdfplumber) capturam a mesma tabela, qual versão deve prevalecer no `.md` final?

### Opções apresentadas
- Sempre pdfplumber (Pass 2) — grade de células mais limpa; precisa de heurística "é a mesma tabela" por página para descartar a tentativa do Pass 1
- Sempre pymupdf4llm (Pass 1) — já sai como Markdown, mas testado na NR-03 produziu colunas genéricas (Col4..Col16), pior fidelidade
- pdfplumber só quando Pass 1 não achou tabela na página — menor esforço, não corrige tabelas que o Pass 1 capturou mal

### Escolha do usuário
Sempre pdfplumber (Pass 2)

### Impacto esperado
- `extract_tables_pass` passa a converter a grade de células do pdfplumber para Markdown (`| col | col |`) em vez de HTML
- `merge_passes`/inserção precisa remover qualquer tentativa de tabela Markdown que o Pass 1 já tenha colocado na mesma página, para não duplicar
- Esforço: médio — precisa de heurística por página (nº de linhas com `|` vindas do Pass 1 na região da tabela) para saber o que remover

## Decisão 2 — Fallback para tabela ilegível em ambos os passes

### Pergunta
Tabelas que nenhum dos dois passes consegue extrair de forma legível (cabeçalho rotacionado, células mescladas complexas — caso real: TABELA 3.4 da NR-03) — o que mostrar no lugar?

### Opções apresentadas
- PNG da página inteira (Pass 3), inserido visível no `.md` no lugar da tabela
- Manter link pro HTML mesmo sabendo que fica ruim
- Marcar para revisão manual futura via `quality_report.json`, sem renderizar nada

### Escolha do usuário
PNG da página inteira (Recomendado)

### Impacto esperado
- Precisa de heurística para detectar "tabela ilegível" (ex.: célula com muitas quebras de linha isoladas por caractere — sinal de texto vertical/rotacionado mal extraído)
- Quando detectado, a referência à página vira `![Tabela N](../assets/pages/page-XXX.png)` visível no ponto certo do `.md`, em vez do comentário oculto que hoje existe só como fallback geral de imagens
- Esforço: médio-alto — a heurística de "ilegível" é o ponto mais delicado (falso-negativo deixa lixo visível; falso-positivo esconde uma tabela que na verdade ficou boa)

## Decisão 3 — Falso-positivo (tabelas de 1 coluna)

### Pergunta
As tabelas de 1 coluna (~20% do total, 118/573, medidas nos HTMLs já commitados) são caixas de texto que o PDF desenhou com borda, não dados tabulares reais — o que fazer com elas?

### Opções apresentadas
- Descartar sempre — o texto já está coberto pelo Pass 1 como parágrafo normal
- Descartar só se o texto já aparece no Pass 1 — mais preciso, mais código

### Escolha do usuário
Descartar sempre (Recomendado)

### Impacto esperado
- `extract_tables_pass` ganha um filtro: se `max(cols por linha) <= 1`, a "tabela" é ignorada (não vira arquivo, não vira referência)
- Esforço: baixo — heurística de uma linha

## Decisão 4 — Reconversão das NRs já commitadas

### Pergunta
Depois de ajustar o pipeline, quando reconverter as 27 NRs já commitadas (573 tabelas) para o novo formato?

### Opções apresentadas
- Rodar local antes de commitar (`--all`), revisando o diff
- Deixar o `update-nrs.yml` diário aplicar sozinho quando o hash de cada PDF mudar

### Escolha do usuário
Rodar local antes de commitar (Recomendado)

### Impacto esperado
- `python3 scripts/convert_nr.py --all` roda localmente após a mudança no pipeline, e o diff das 27 NRs é revisado antes de subir
- Garante que todas as NRs já tenham o formato novo imediatamente, sem depender de o PDF de cada uma mudar
- Custo: tempo de execução local (não consome minutos de GitHub Actions)
