# Scripts — Pipeline de conteúdo

Ferramentas Python para scraping, conversão e indexação de NRs. Cada script pode rodar standalone ou ser chamado pela GitHub Action.

**Princípio:** Nunca reescrever conteúdo normativo — só extrair, estruturar e exibir melhor.

---

## Setup (1x)

```bash
chmod +x scripts/setup.sh scripts/check.sh
./scripts/setup.sh
```

Instala FVM, Flutter pub, Python venv e `requirements.txt`.

---

## Dados — merge nr_index.json + nr_sources.json

A lista de NRs vem **dinamicamente** de `nr_index.json` (gerado por `discover_nrs.py`), não é fixa.
`nr_sources.json` serve só para **overrides pontuais** — quando o scraping falha para uma NR específica.

**Ordem de precedência:**
1. `nr_sources.json[nr_id]` (override manual, tem prioridade)
2. `nr_index.json[nr_id]` (scraping automático, base)
3. fallback vazio

Implementado em `scripts/_common.py` (`merge_nr_data()`, `list_all_nrs()`).

---

## Scripts

### 1. `discover_nrs.py` — Descoberta de NRs

Faz scraping da página-índice do gov.br, extrai lista de NRs, URLs de PDF/página, status de revogação.

**Responsabilidades:**
- Descobre NRs novas automaticamente
- Marca NRs revogadas (quando o site deixar explícito)
- Mapeia NR sucessora via `substitui_por` (quando o gov.br indicar)

**Uso:**

```bash
python3 scripts/discover_nrs.py              # scraping completo → scripts/nr_index.json
python3 scripts/discover_nrs.py --dry-run    # simula sem gravar
python3 scripts/discover_nrs.py --verbose    # logging DEBUG
python3 scripts/discover_nrs.py --help       # ajuda
```

**Output:**
- `scripts/nr_index.json` (gerado) — por NR: `id`, `title`, `pdf_url`, `page_url`, `revogada` (bool), `substitui_por` (id ou null)

**Falha defensiva:**
Se o layout do gov.br mudar (seletores HTML não encontrados), o script lança exceção — isso falha a Action, alertando que precisa atualizar os seletores. Usa fallback `FIXTURE_NRS` para testes sem rede.

---

### 2. `cleanup_orphans.py` — Remoção de conteúdo órfão

Remove `content/nr-XX/` inteiro quando `nr-XX` não existe mais em `nr_index.json` nem em `nr_sources.json`
(ex.: NR renumerada, unificada ou removida do índice do gov.br). Sem isso, markdown/PDF/PNGs/índices dessa
NR ficam para sempre no repositório — lixo que só cresce a cada execução da Action.

**Uso:**

```bash
python3 scripts/cleanup_orphans.py              # remove órfãos
python3 scripts/cleanup_orphans.py --dry-run    # lista sem remover
python3 scripts/cleanup_orphans.py --help       # ajuda
```

**Output:**
- Remove `content/nr-XX/` (diretório inteiro) para cada órfão encontrado

**Quando rodar:** logo após `discover_nrs.py` (índice fresco), antes de qualquer outra etapa —
assim nenhuma etapa seguinte perde tempo com uma NR que já não existe.

---

### 3. `scrape_vigencia.py` — Metadados de vigência

Scraping da página HTML de cada NR (não do PDF) → extrai metadados que descrevem quando entrou em vigor.

**Responsabilidades:**
- `publicado_em` — data de publicação oficial (ex.: 2018-04-12)
- `vigente_desde` — quando passou a vigorar (ex.: 2018-06-10)
- `portaria` — ato normativo (ex.: Portaria MTE nº 509/2018)
- `ultima_alteracao` — última alteração conhecida

Estes metadados enriquecem `content/nr-XX/meta.json` (preenchido durante conversão).

**Uso:**

```bash
python3 scripts/scrape_vigencia.py --nr nr-06           # uma NR
python3 scripts/scrape_vigencia.py --all                # todas (de nr_index.json)
python3 scripts/scrape_vigencia.py --all --dry-run      # simula
python3 scripts/scrape_vigencia.py --help               # ajuda
```

**Output:**
- `content/nr-XX/meta.json` (atualiza) — adiciona `publicado_em`, `vigente_desde`, `portaria`, `ultima_alteracao`

**Isolamento de erro:**
Falha numa NR (scraping HTML fora do padrão) não interrompe as demais. Registra erro, segue. Exit code != 0 ao final se houver erros.

---

### 4. `convert_nr.py` — Conversão PDF → Markdown

Converte PDF oficial em Markdown + assets (PNG de página para diagramas ou tabelas ilegíveis).

**3 passes SEMPRE executados (sem classificação de complexidade prévia):**

1. **Pass texto** — `pymupdf4llm`, por página (`page_chunks=True`) → corpo normativo em Markdown
2. **Pass tabelas** — `pdfplumber` → Markdown inline (`| col | col |`), inserido logo após o texto da página correspondente. Tabelas de 1 coluna (caixas de texto com borda, falso-positivo) são descartadas; tabelas ilegíveis nos dois passes (ex.: cabeçalho com texto vertical quebrado) caem para o fallback do Pass 3 (PNG da página) em vez de virar Markdown/HTML ilegível
3. **Pass imagens/diagramas** — render de página com `pymupdf` → PNG em `content/nr-XX/assets/pages/page-*.png` (páginas com imagem embutida + páginas com tabela ilegível)

Depois faz merge dos 3 passes num `.md` único por página, normaliza, salva PDF original + calcula `pdf_hash` (SHA-256).

**Uso:**

```bash
python3 scripts/convert_nr.py --nr nr-06           # uma NR
python3 scripts/convert_nr.py --all                # todas (de nr_index.json)
python3 scripts/convert_nr.py --nr nr-06 --dry-run # simula
python3 scripts/convert_nr.py --help               # ajuda
```

**Output:**
- `content/nr-XX/nr-XX.md` — Markdown normalizado (headings `17.1`, sem artefatos PDF)
- `content/nr-XX/nr-XX.pdf` — PDF original (arquivo de referência + prova de fidelidade)
- `content/nr-XX/meta.json` — adiciona `pdf_hash`
- `content/nr-XX/assets/pages/page-*.png` — páginas renderizadas (imagem embutida ou tabela ilegível)

**Isolamento de erro:**
Falha numa NR (PDF corrompido, scraping quebrado) não interrompe as demais. Exit code != 0 ao final se houver erros.

---

### 5. `normalize_md.py` — Normalização de Markdown

Remove artefatos de PDF (cabeçalhos/rodapés repetidos, hifenização quebrada), normaliza headings.

Pode rodar standalone ou ser importado por `convert_nr.py`.

**Uso:**

```bash
python3 scripts/normalize_md.py --nr nr-06           # normaliza content/nr-06/nr-06.md
python3 scripts/normalize_md.py --all                # todas
python3 scripts/normalize_md.py --nr nr-06 --dry-run # simula
python3 scripts/normalize_md.py --help               # ajuda
```

**Transformações:**
- Remove sequências de linhas em branco excessivas
- Corrige hifenização (linha termina em hífen → une à próxima)
- Normaliza headings
- Remove cabeçalho/rodapé repetido

**Output:**
- Modifica `content/nr-XX/nr-XX.md` no lugar

---

### 6. `build_index.py` — Construção de índices

Gera índices de navegação e busca a partir do `.md` normalizado.

**Output:**

- **`content/nr-XX/index.json`** — estrutura de headings para navegação (sidebar do leitor)
  ```json
  {
    "headings": [
      {"level": 2, "text": "Artigo 17", "id": "artigo-17"},
      {"level": 3, "text": "Seção 17.1", "id": "secao-17-1"}
    ]
  }
  ```

- **`content/nr-XX/search_index.json`** — chunks de ~250 chars para busca full-text
  ```json
  [
    {"id": "chunk-0", "text": "...", "heading": "Artigo 17", "char_offset": 1234},
    ...
  ]
  ```

**Uso:**

```bash
python3 scripts/build_index.py --nr nr-06           # uma NR
python3 scripts/build_index.py --all                # todas
python3 scripts/build_index.py --nr nr-06 --dry-run # simula
python3 scripts/build_index.py --help               # ajuda
```

---

### 7. `build_manifest.py` — Geração do manifest remoto

Agrega dados de `content/nr-XX/meta.json`, `nr_index.json`, e arquivo `.md`
para criar `manifest.json` na raiz do repo (índice central de todas as NRs).

**Output:**
- **`manifest.json`** (raiz do repo) — índice remoto
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
        "reviewed": false
      }
    ]
  }
  ```

**Uso:**

```bash
python3 scripts/build_manifest.py              # gera manifest.json
python3 scripts/build_manifest.py --dry-run    # simula
python3 scripts/build_manifest.py --help       # ajuda
```

Extrai automaticamente `owner/repo/branch` do git remote origin. O campo `url` aponta para raw do GitHub.

---

### 8. `update_nrs.py` — Detecção de mudanças

Para cada NR:
1. Baixa PDF (usando `pdf_url` de `nr_index.json` + overrides de `nr_sources.json`)
2. Calcula SHA-256
3. Compara com `pdf_hash` anterior (em `content/nr-XX/meta.json`)
4. Se mudou, dispara `convert_nr.py`

**Uso:**

```bash
python3 scripts/update_nrs.py              # processa todas
python3 scripts/update_nrs.py --dry-run    # simula
python3 scripts/update_nrs.py --help       # ajuda
```

**Isolamento de erro:**
Falha numa NR não interrompe as demais. Exit code != 0 ao final se houver erros.

---

### 9. `validate_manifest.py` — Validação do schema

Valida `manifest.json` contra schema esperado (campos obrigatórios, tipos, URLs bem formadas).

Usado por `scripts/check.sh` e CI — funciona graciosamente no-op se `manifest.json` ainda não existir (Fase 0).

**Uso:**

```bash
python3 scripts/validate_manifest.py                   # valida manifest.json
python3 scripts/validate_manifest.py --path=meu.json   # arquivo custom
python3 scripts/validate_manifest.py --help            # ajuda
```

**Campos obrigatórios por NR:**
- `id`, `title`, `version`, `hash`, `pdf_hash`, `updated_at`
- `portaria`, `publicado_em`, `vigente_desde`
- `url`, `reviewed`

---

### 10. `build_app_meta.py` — Feed de atualizações (sem backend)

Lê `manifest.json`, compara com a última entrada conhecida em `app_meta.json`
(se existir) usando `hash` (do markdown convertido, mesmo critério que o app usa
em `ContentService.hasUpdate` — não `pdf_hash`), e acrescenta uma entrada por NR
que mudou. Mantém só as 200 entradas mais recentes.

Para cada NR que mudou, reaproveita `summarize_md()` de `summarize_changes.py`
(mesma função usada no changelog mensal) para gerar `items[]` granular por seção
(`{item, tipo, resumo}`, tipo é `novo`/`removido`/`alterado`). Quando o diff não
está disponível (ex.: primeira versão da NR, ou `git show` falha por falta de
histórico), `items` fica vazio e `summary` cai num resumo curto genérico — nunca
interpola um campo que pode ser `None` diretamente (bug antigo: "Atualizado em None").

**Uso:**

```bash
python3 scripts/build_app_meta.py            # gera/atualiza app_meta.json
python3 scripts/build_app_meta.py --dry-run  # simula
python3 scripts/build_app_meta.py --help     # ajuda
python3 scripts/test_build_app_meta.py -v    # testes unitários
```

**Output:**
- `app_meta.json` (raiz do repo) — `min_app_version` + `updates[]` (cada entrada com `items[]` granular). Commitado pela Action junto com `manifest.json`; o app lê os dois via GitHub raw.

---

### 11. `summarize_changes.py` — Resumo legível das alterações normativas

Compara o markdown de cada NR alterada (`content/nr-XX/nr-XX.md`) contra um ref git, item a item
(ex.: `10.4.2`), e classifica cada item como novo, removido ou alterado — mostrando só o trecho de
palavras que de fato mudou (via `difflib`), não o item inteiro. Também aponta mudanças de vigência
em `meta.json` (`publicado_em`, `vigente_desde`, `ultima_alteracao`). Puramente baseado em regex/diff
de texto — sem IA, custo zero, determinístico.

Usado pela etapa "Registrar changelog mensal" do workflow: o resultado vai tanto para o changelog em
`docs/changelog/` quanto para o Job Summary da execução do Actions (para não precisar abrir os logs de
cada step para saber o que mudou).

**Uso:**

```bash
python3 scripts/summarize_changes.py             # compara HEAD vs working tree
python3 scripts/summarize_changes.py --ref HEAD~1  # compara contra outro ref
```

**Output:**
- Markdown no stdout, um bloco `### NR-XX` por NR alterada, com linhas `🆕`/`❌`/`✏️` por item.
- Cada NR mostra no máximo `MAX_ITEMS_PER_NR` (30) itens — excesso vira uma linha "+N omitida(s)"
  em vez de inundar o changelog/summary (acontece em commits que reformatam o pipeline inteiro,
  não em atualizações normativas normais).

---

## `_common.py` — Utilitários compartilhados

Funções reutilizáveis por vários scripts:
- `merge_nr_data(nr_id)` — merge de `nr_index.json` + `nr_sources.json`
- `list_all_nrs()` — lista de IDs conhecidas
- `ensure_content_dir(nr_id)` — cria e retorna `content/nr-XX/`
- `ensure_assets_dir(nr_id, asset_type)` — cria e retorna `content/nr-XX/assets/{type}/`
- `setup_logging(verbose)` — configura logging com DEBUG/INFO
- `CONTENT_DIR` — `Path` de `content/`, usado por `cleanup_orphans.py` para achar diretórios órfãos

---

## Fluxo: GitHub Action `update-nrs.yml` (Fase 3)

Execução automática, diária (configurável):

```
discover_nrs.py                (scraping → nr_index.json)
    ↓
cleanup_orphans.py             (remove content/nr-XX/ órfãos)
    ↓
update_nrs.py                  (detecção de mudanças)
    ↓
scrape_vigencia.py --all       (metadados de vigência)
    ├→ convert_nr.py --all     (se pdf_hash mudou)
    ├→ normalize_md.py --all
    └→ build_index.py --all
    ├→ build_manifest.py
    └→ validate_manifest.py
    ↓
build_app_meta.py              (app_meta.json: feed de atualizações + versão mínima)
    ↓
summarize_changes.py           (resumo legível → changelog + Job Summary do Actions)
    ↓
git commit + push              (GitHub: content/ + manifest.json + app_meta.json)
```

---

## Dia a dia (CLI)

```bash
# Dev: testar um script localmente
python3 scripts/convert_nr.py --nr nr-06 --dry-run
python3 scripts/build_index.py --all
python3 scripts/validate_manifest.py

# Checar tudo (é o que `scripts/check.sh` roda)
fvm flutter analyze --fatal-infos
fvm flutter test
python3 scripts/validate_manifest.py

# FVM
fvm install
fvm use
fvm flutter pub get
fvm flutter run
```

---

## Isolamento de erro por NR (regra crítica)

Em qualquer script que itera sobre múltiplas NRs (`--all` ou `update_nrs.py`):

```python
errors: list[tuple[str, str]] = []

for nr_id in nrs_to_process:
    try:
        # processar
    except Exception as e:
        errors.append((nr_id, str(e)))
        continue  # não interrompe

# Ao final
if errors:
    logger.error(f"Erros em {len(errors)} NR(s)")
    return 1  # Action falha, mas com sucesso parcial
```

**Resultado:** Action sempre processa todas as NRs que conseguir (mesmo com falhas);
commit inclui sucessos; erros são registrados no log; exit code != 0 notifica falha.

---

## Sem rede / testes

Todos os scripts com `--dry-run` funcionam sem rede ou API real:
- `discover_nrs.py` usa `FIXTURE_NRS` como fallback
- `scrape_vigencia.py` usa `FIXTURE_META`
- `convert_nr.py` simula os 3 passes sem chamar PDF real
- Outros usam dados em memória

Ideal para CI ou desenvolvimento offline.

---

## Nunca

- ❌ Reescrever conteúdo normativo (só extrair/estruturar)
- ❌ Classificar NRs por complexidade (A–D) — todas passam pelos 3 passes
- ❌ Pular um dos 3 passes
- ❌ Rodar `build_app_meta.py` sem antes gerar um `manifest.json` atualizado (ele lê de lá)
- ❌ Deixar loop da Action parar por erro numa NR — continua as demais
- ❌ Esquecer `--dry-run` e `--help` em novo script

---

## Quando pedir IA

- Criar/editar código Dart ou Python → `docs/prompts.md`
- Converter PDF manualmente → **não** — use `convert_nr.py`
- Rodar testes → **não** — use `./scripts/check.sh`
