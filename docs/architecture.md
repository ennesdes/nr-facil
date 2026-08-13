# NR Fácil — Arquitetura técnica

Referência consolidada. Checklist de execução: [todo.md](../todo.md).

## Decisões

| Decisão | Escolha |
|---------|---------|
| Repositório | Monorepo (`app/`, `content/`, `scripts/`) |
| Flutter | FVM, versão em `.fvmrc` |
| Plataforma MVP | Android only |
| Fonte da verdade | **GitHub** (MD, PDF, manifest, histórico git) |
| Supabase | Metadados leves apenas — **R$ 0** free tier |
| Monetização | AdMob + IAP `remove_ads_lifetime` R$ 9,90 |
| Navegação | Abas **Favoritos** \| **Todos** |

## Fluxo de dados

```
Portal MTE (PDFs públicos)
        ↓ GitHub Action (diária)
scripts/ Python (download, convert, manifest)
        ↓ commit
GitHub (content/ + manifest.json)  ← FONTE DA VERDADE
        ↓ HTTP raw
App Flutter (cache offline local)
        ↓ SELECT leve
Supabase (nr_updates, app_versions)
```

**O app nunca acessa o MTE diretamente.**

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
├── scripts/
├── docs/
└── .github/workflows/
```

## Acesso ao MTE

- Sem API oficial; URLs de PDF não padronizadas
- Lista curada: `scripts/nr_sources.json`
- Detecção de mudança: hash SHA-256 do PDF
- NRs revogadas: NR-2, NR-27 (`revogada: true`)
- Procedure: [03-mapear-urls-mte.md](procedures/03-mapear-urls-mte.md)

## Pipeline de conteúdo

### Princípio

> Nunca reescrever o conteúdo normativo. Só extrair, estruturar e exibir melhor.

### 3 camadas

1. **Extração** — `pymupdf4llm` + PDF original salvo + `pdf_hash`
2. **Normalização** — headings `17.1`, remover artefatos PDF, hifenização
3. **Índices** — `index.json` (navegação) + `search_index.json` (busca por chunk)

### Tabelas e imagens (3 níveis de fallback)

| Nível | Ferramenta | Quando |
|-------|-----------|--------|
| 1 | pymupdf4llm | Texto, tabelas simples, imagens |
| 2 | pdfplumber | Tabelas complexas → HTML em `assets/tables/` |
| 3 | page PNG | Diagramas → `assets/pages/page-XX.png` |

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
      "url": "https://raw.githubusercontent.com/USER/nr-facil/main/content/nr-06/nr-06.md",
      "reviewed": true
    }
  ]
}
```

### Qualidade

Script gera `quality_report.json` por NR: `char_ratio`, `warnings[]`, `pages_fallback_png`.

## Supabase mínimo

### O que armazena

| Tabela | Uso | Tamanho |
|--------|-----|---------|
| `app_versions` | Versão mínima do APK | ~10 linhas |
| `nr_updates` | Feed de atualizações | ~200 linhas/ano |

### O que NÃO armazena

Markdown, PDFs, imagens, histórico completo de textos.

### Schema

Ver [supabase/migration.sql](supabase/migration.sql).

### Atualizações para o usuário

**Grátis:** NR, data, portaria, resumo 1 linha, botão Abrir, link **Ver versão anterior** (commit GitHub).

**Premium (pós-MVP):** diff inline — calculado localmente ou de 2 commits git, sem storage Supabase.

### Quem escreve

- GitHub Action → INSERT `nr_updates` (service_role)
- App → SELECT apenas
- Script gera `summary` sem IA: "Seções alteradas: 6.3, 6.9"

## App Flutter

### Navegação

- **Bottom nav:** Favoritos (padrão se ≥1 favorito) | Todos
- **App bar:** Busca | Sino (atualizações + badge) | Ajustes
- **Continuar leitura:** card no topo de Favoritos
- **Histórico:** automático, não é aba

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
- Assets: imagens, tabelas HTML (`flutter_widget_from_html`), PNG zoom (`photo_view`)
- Link "Ver PDF original no MTE"
- Aviso legal fixo

### Busca

- Filtro (aba Todos): título/número da NR
- Busca (app bar): full-text em `search_index.json` chunks com highlight

### Offline

- `path_provider` + arquivos `.md` e assets
- Sync incremental via hash no manifest

### Monetização

| Grátis | Premium (IAP) |
|--------|---------------|
| Todas NRs offline | Sem anúncios |
| Busca, favoritos | Diff "o que mudou" |
| Feed atualizações | Anotações (pós-MVP) |
| Ads em listas | Exportar trecho PDF |

Ads **nunca** no leitor.

## GitHub Actions

### `update-nrs.yml` (diária 09:00 UTC)

1. `update_nrs.py` — download + hash
2. `convert_nr.py` — se mudou
3. `build_manifest.py`
4. `push_nr_updates.py` — Supabase
5. git commit + push

### `ci.yml`

- `fvm flutter analyze` + `test`
- `validate_manifest.py`

## Escopo MVP

### Grátis

Download offline, busca global, favoritos, histórico, lista NRs, tela atualizações, leitura otimizada.

### Pago

Remover anúncios, destaque mudanças (diff), anotações, exportar trecho PDF.

## Critérios de sucesso (90 dias)

- 1.000 downloads
- 200 MAU
- Nota ≥ 4.5
- Receita ≥ R$ 50/mês

## Texto legal (no app)

> Este aplicativo disponibiliza conteúdo público oficial das Normas Regulamentadoras do Ministério do Trabalho e Emprego. O conteúdo não substitui a consulta às publicações oficiais no portal gov.br.

## Estimativa de esforço

| Área | Horas |
|------|-------|
| Flutter base + leitor | 20 |
| Busca + favoritos + UX | 10 |
| Pipeline Python | 10 |
| CI + Supabase | 5 |
| Ads + IAP + publicação | 15 |
| **Total** | **~60h** |

## Evoluções pós-MVP

Push notifications, widget Android, checklist NR-18, PGR simplificado, B2B.
