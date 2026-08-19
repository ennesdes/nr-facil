# NR Fácil — Arquitetura técnica

Referência consolidada. Checklist de execução: [todo.md](../todo.md).

## Decisões

| Decisão | Escolha |
|---------|---------|
| Repositório | Monorepo (`app/`, `content/`, `scripts/`) |
| Flutter | FVM, versão em `.fvmrc` |
| Plataforma MVP | Android only |
| Fonte da verdade | **GitHub** (MD, PDF, manifest, histórico git) |
| Backend | **Nenhum** — feed de atualizações + versão mínima em `app_meta.json` versionado no GitHub — **R$ 0**, sem conta externa |
| Monetização | AdMob (lançamento); IAP `remove_ads_lifetime` R$ 9,90 (Fase 6, pós-lançamento) |
| Navegação | Abas **Favoritos** \| **Todos** |

## Fluxo de dados

```
Portal MTE (PDFs públicos)
        ↓ GitHub Action (diária)
scripts/ Python (download, convert, manifest, app_meta)
        ↓ commit
GitHub (content/ + manifest.json + app_meta.json)  ← FONTE DA VERDADE
        ↓ HTTP raw
App Flutter (cache offline local)
```

**O app nunca acessa o MTE diretamente, e não há backend a operar.**

## Estrutura do monorepo

```
nr-facil/
├── .fvmrc
├── app/                    # Flutter Android
├── content/                # NRs convertidas
│   └── nr-06/
│       ├── nr-06.md
│       ├── nr-06.pdf
│       ├── index.json
│       ├── search_index.json
│       ├── meta.json
│       └── assets/
│           ├── images/
│           ├── tables/
│           └── pages/
├── manifest.json           # índice remoto de todas NRs
├── app_meta.json           # feed de atualizações + versão mínima
├── scripts/
├── docs/
└── .github/workflows/
```

## Acesso ao MTE

- Sem API oficial; URLs de PDF não padronizadas
- Lista de NRs **dinâmica**, não manual: `discover_nrs.py` faz scraping da página-índice do gov.br e gera `nr_index.json` (gerado, como o `manifest.json`) com, por NR: `pdf_url`, `page_url`, `revogada`, `substitui_por` (NR sucessora, quando o site deixar explícito)
  - Isso cobre inclusão automática de NRs novas e marcação automática de revogações — não depende de alguém lembrar de atualizar uma lista fixa
- `scripts/nr_sources.json` vira **só overrides manuais pontuais** — não é mais a lista mestra. Só tem entrada ali quando o scraping falha para uma NR específica (URL fora do padrão, página com layout diferente) ou quando é preciso forçar um valor. O pipeline faz merge: `nr_index.json` (dinâmico) com overrides de `nr_sources.json` por cima.
- Detecção de mudança: híbrida
  - `pdf_hash` (SHA-256 do PDF) segue sendo a fonte de verdade do **texto** normativo — nunca gerado a partir do site
  - metadados de vigência (`publicado_em`, `vigente_desde`, `portaria`, `ultima_alteracao`) vêm do **scraping da página HTML** (`scrape_vigencia.py`), que é mais confiável que inferir isso do PDF
  - update real de conteúdo = `pdf_hash` mudou; `vigente_desde`/`portaria` do site enriquecem o `meta.json`/`manifest.json`, não substituem o hash como gatilho
- Falha defensiva: `discover_nrs.py` e `scrape_vigencia.py` definem os seletores HTML esperados; se um campo obrigatório não for encontrado (mudança de layout do site), o script lança exceção — isolada por NR quando aplicável (ver "Isolamento de erro por NR" abaixo), ou falha a Action inteira quando é a página-índice geral que mudou. O e-mail de falha padrão do GitHub Actions já avisa, sem precisar de alerta customizado.
- NRs revogadas: hoje conhecidas NR-2, NR-27, mas a lista completa vem de `nr_index.json`, não é fixa neste doc
- Procedure: [03-mapear-urls-mte.md](procedures/03-mapear-urls-mte.md)

## Pipeline de conteúdo

### Princípio

> Nunca reescrever o conteúdo normativo. Só extrair, estruturar e exibir melhor.

### 3 camadas

1. **Extração** — 3 passes sempre executados sobre o mesmo PDF (sem classificação prévia por complexidade — toda NR recebe o mesmo tratamento):
   - Pass texto: `pymupdf4llm` → corpo normativo
   - Pass tabelas: `pdfplumber` → Markdown inline, no ponto certo do texto (fallback: PNG recortado por bbox da tabela se ilegível — texto vertical quebrado, cabeçalho rotacionado, etc)
   - Pass imagens/diagramas: extração de bboxes de imagem embutida → PNG recortado por bbox em `assets/pages/page-NNN-{image|table}-{i:02d}.png`
   - Merge dos 3 passes num único `.md` padronizado, com referências `![...]` a imagens/tabelas PNG na ordem Y
   - PDF original salvo + `pdf_hash`
2. **Normalização** — headings `17.1`, remover artefatos PDF, hifenização
3. **Índices** — `index.json` (navegação) + `search_index.json` (busca por chunk)

Rodar os 3 passes em toda NR custa mais tempo de execução por rodada, mas o limite real é o free tier do GitHub Actions (minutos), não CPU. Se o custo deixar de ser zero, o ajuste é reduzir a frequência do `update-nrs.yml` (diário → a cada 2 dias → semanal), nunca reduzir a qualidade do processamento.

### manifest.json (exemplo)

```json
{
  "generated_at": "2026-08-13T12:00:00Z",
  "version": 1,
  "nrs": [
    {
      "id": "nr-06",
      "title": "EPI",
      "version": "2026-01-17",
      "hash": "abc123...",
      "pdf_hash": "def456...",
      "updated_at": "2026-01-17T00:00:00Z",
      "portaria": "Portaria MTE nº 57/2025",
      "publicado_em": "2018-04-12",
      "vigente_desde": "2026-01-17",
      "url": "https://raw.githubusercontent.com/USER/nr-facil/main/content/nr-06/nr-06.md",
      "reviewed": true
    }
  ]
}
```

### Qualidade

Script gera `quality_report.json` por NR: `char_ratio`, `warnings[]`, `pages_fallback_png`.

## app_meta.json (sem backend)

### O que armazena

| Campo | Uso | Tamanho |
|-------|-----|---------|
| `min_app_version` | Versão mínima do APK (editado manualmente quando preciso forçar update) | 1 valor |
| `updates` | Feed de atualizações, janela rolante | últimas 200 entradas |

### O que NÃO armazena

Markdown, PDFs, imagens, histórico completo de textos.

### Schema

Gerado por [`scripts/build_app_meta.py`](../scripts/build_app_meta.py) — sem migration, sem projeto externo.

### Atualizações para o usuário

**Grátis:** NR, data, portaria, resumo 1 linha, botão Abrir, link **Ver versão anterior** (commit GitHub).

**Premium (pós-MVP):** diff inline — calculado localmente ou de 2 commits git, sem storage adicional.

### Quem escreve

- GitHub Action → gera `app_meta.json` e commita junto com `manifest.json`
- App → só lê via GitHub raw HTTP
- Script gera `summary` sem IA: "Seções alteradas: 6.3, 6.9"

## App Flutter

### Navegação

- **Bottom nav:** Favoritos (padrão se ≥1 favorito) | Todos
- **App bar:** Busca | Sino (atualizações + badge) | Ajustes
- **Continuar leitura:** card no topo de Favoritos
- **Histórico:** automático, não é aba

### NRs revogadas no app

- Aparecem na aba **Todos** com badge "Revogada" (visual opaco/cinza), mas **não** entram em Favoritos nem no índice de busca (`search_index.json`) — não são convertidas pelo pipeline.
- Ao tocar: tela simples (sem leitor interno) mostrando:
  - Botão "Ver PDF oficial (histórico)" → link externo pro PDF arquivado no MTE, sem cache local
  - Se houver NR sucessora mapeada (`substitui_por` no `nr_index.json`, quando o gov.br indicar), botão "Ver NR vigente" levando direto pra NR atual
- Fonte do status e do mapeamento de substituição: `discover_nrs.py` (scraping da página-índice do gov.br); quando o site não deixar explícito qual NR substituiu, o campo fica nulo e só o link do PDF histórico é mostrado.

### Detecção de atualização

- `last_synced_hash` — hash baixado
- `last_seen_hash` — hash visto pelo usuário
- Novo = remoto ≠ `last_seen_hash`

### Índice vs Atualizações

| | Índice | Atualizações |
|---|--------|--------------|
| Função | Navegar dentro da NR | Saber o que mudou |
| Onde | Leitor (lateral) | Tela do sino |

### Leitor

- `flutter_markdown` + tipografia customizada
- Índice lateral de `index.json`
- Assets: imagens e tabelas via Markdown padrão (`flutter_markdown`), PNG zoom (`photo_view`) — `flutter_widget_from_html` não é mais necessário, tabelas saem do pipeline como Markdown nativo
- Link "Ver PDF original no MTE"
- Aviso legal fixo

### Busca

- Filtro (aba Todos): título/número da NR
- Busca (app bar): full-text em `search_index.json` chunks com highlight

### Offline

- `path_provider` + arquivos `.md` e assets
- Sync incremental via hash no manifest

### Monetização

| Grátis (lançamento) | Premium (IAP, Fase 6) |
|--------|---------------|
| Todas NRs offline | Sem anúncios |
| Busca, favoritos | Diff "o que mudou" |
| Feed atualizações | Anotações (pós-MVP) |
| Ads em listas | Exportar trecho PDF |

Ads **nunca** no leitor.

Lançamento (Fase 5) sai apenas com a coluna grátis + ads. A coluna premium (IAP) só é implementada na Fase 6, depois de validar uso real do app publicado.

## GitHub Actions

### `update-nrs.yml` (diária 09:00 UTC — ajustável para 2 em 2 dias ou semanal se o free tier de minutos do Actions apertar)

1. `discover_nrs.py` — lista de NRs + status de revogação a partir da página-índice do gov.br → `nr_index.json`
2. `update_nrs.py` — download PDF + hash, por NR
3. `scrape_vigencia.py` — extrai metadados de vigência da página HTML, por NR
4. `convert_nr.py` — se `pdf_hash` mudou, por NR (3 passes + merge)
5. `build_manifest.py`
6. `build_app_meta.py` — gera `app_meta.json` (feed de atualizações + versão mínima)
7. git commit + push

**Isolamento de erro por NR:** o loop dos passos 2–4 processa NR por NR. Se uma etapa falhar para uma NR específica (scraping fora do padrão, PDF corrompido, etc.), o script captura o erro, **não atualiza aquela NR** (mantém a versão anterior em `content/`), registra a NR e o motivo em `errors[]`, e segue para a próxima NR. Ao final, se `errors[]` não estiver vazio, o script sai com código de erro — isso falha o job da Action (notificação padrão do GitHub por e-mail, job vermelho), mas o commit já inclui todas as NRs que processaram com sucesso. O log do job mostra exatamente qual(is) NR(s) falharam.

### `ci.yml`

- `fvm flutter analyze` + `test`
- `validate_manifest.py`

## Escopo MVP

### Grátis

Download offline, busca global, favoritos, histórico, lista NRs, tela atualizações, leitura otimizada.

### Pago (Fase 6, pós-lançamento)

Remover anúncios, destaque mudanças (diff), anotações, exportar trecho PDF.

## Critérios de sucesso (90 dias)

- 1.000 downloads
- 200 MAU
- Nota ≥ 4.5
- Receita ≥ R$ 50/mês

## Texto legal (no app)

> Este aplicativo disponibiliza conteúdo público oficial das Normas Regulamentadoras do Ministério do Trabalho e Emprego. O conteúdo não substitui a consulta às publicações oficiais no portal gov.br.

### Base legal do conteúdo

Textos de leis, decretos, regulamentos e demais atos oficiais são excluídos de proteção autoral pela Lei 9.610/98, art. 8º, inciso IV. NRs são atos normativos do MTE, portanto não exigem licença do órgão para reprodução — desde que o texto não seja alterado (ver princípio "nunca reescrever texto normativo").

Cuidados que continuam valendo mesmo sem exigência de licença:
- Não usar brasão da República ou logotipos oficiais do MTE/gov.br no app (proteção de marca, não autoral).
- Manter o disclaimer acima visível, para não sugerir oficialidade.
- Guardar PDF original + `pdf_hash` por NR como evidência de fidelidade ao texto oficial.

## Estimativa de esforço

| Área | Horas |
|------|-------|
| Flutter base + leitor | 20 |
| Busca + favoritos + UX | 10 |
| Pipeline Python | 10 |
| CI + app_meta.json | 3 |
| Ads + publicação (Fase 5) | 12 |
| **Total lançamento (grátis + ads)** | **~57h** |
| IAP remove_ads_lifetime (Fase 6) | 3 |

## Evoluções pós-MVP

IAP `remove_ads_lifetime` (Fase 6, ver acima), push notifications, widget Android, checklist NR-18, PGR simplificado, B2B.
