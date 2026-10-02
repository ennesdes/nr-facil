# NR Fácil — Arquitetura técnica (índice)

Checklist de execução: [todo.md](../todo.md).  
**Regras de produto e engenharia (SSOT):** [spec/INDEX.md](../spec/INDEX.md) · [spec/README.md](../spec/README.md).

## Decisões de alto nível

| Decisão | Escolha |
|---------|---------|
| Repositório | Monorepo (`app/`, `content/`, `scripts/`) |
| Flutter | FVM (`.fvmrc`) |
| Plataforma MVP | Android only |
| Fonte da verdade | **GitHub** — MD, PDF, `manifest.json`, `app_meta.json` |
| Backend | **Nenhum** — app lê GitHub raw HTTP |
| Monetização | AdMob (lançamento); IAP `remove_ads_lifetime` Fase 6 |

## Fluxo de dados

```
Portal MTE (PDFs públicos)
        ↓ GitHub Action (update-nrs.yml)
scripts/ Python (discover, download, convert, manifest, app_meta)
        ↓ commit
GitHub (content/ + manifest.json + app_meta.json)
        ↓ HTTP raw
App Flutter (cache offline local)
```

O app **não** baixa conteúdo normativo direto do MTE em runtime.

## Estrutura do monorepo

```
nr-facil/
├── app/                 # Flutter
├── content/             # NRs convertidas
├── manifest.json
├── app_meta.json
├── scripts/
├── spec/                # SSOT Spec-Driven Development
└── docs/
```

## Onde está o detalhe

| Tópico | SSOT |
|--------|------|
| Shell, abas, listas, sync | [spec/capabilities/home/](../spec/capabilities/home/README.md) |
| Leitor, banner, índice | [spec/capabilities/reader/](../spec/capabilities/reader/README.md) |
| Busca global | [spec/capabilities/search/](../spec/capabilities/search/README.md) |
| Sino, `app_meta` | [spec/capabilities/updates/](../spec/capabilities/updates/README.md) |
| Checklist NR-28 | [spec/capabilities/compliance/](../spec/capabilities/compliance/README.md) |
| Ajustes, tema | [spec/capabilities/settings/](../spec/capabilities/settings/README.md) |
| AdMob | [spec/capabilities/ads/](../spec/capabilities/ads/README.md) |
| Pipeline Python / Action | [spec/capabilities/pipeline/](../spec/capabilities/pipeline/README.md) |
| Manifest, hashes, fidelidade | [spec/standards/domain/content.md](../spec/standards/domain/content.md) |
| Motor compliance | [spec/standards/domain/compliance.md](../spec/standards/domain/compliance.md) |
| Sync GitHub raw | [spec/standards/domain/content_sync.md](../spec/standards/domain/content_sync.md) |
| Navegação transversal | [spec/standards/ui/screens_flow.md](../spec/standards/ui/screens_flow.md) |
| Mapa de código | [spec/standards/core/code_map.md](../spec/standards/core/code_map.md) |
| Marca / tokens visuais | [brand.md](brand.md), [design-system.md](design-system.md) |
| Cobertura checklist | [compliance-checklist-cobertura.md](compliance-checklist-cobertura.md) |

## GitHub Actions

| Workflow | Disparo | Função |
|----------|---------|--------|
| `update-nrs.yml` | cron + `workflow_dispatch` | Pipeline de conteúdo |
| `deploy-play.yml` | `workflow_dispatch` | Build AAB, Play Store |
| `maestro-e2e.yml` | `workflow_dispatch` | Smoke E2E |

Validação local antes de commit: `./scripts/check.sh` (sem CI em `push` na `main`).

## Conteúdo fora do sync automático

- **NRs:** `content/` via Action — ver pipeline capability.
- **Checklist:** `app/assets/compliance/compliance.json` — só com nova versão do app na loja.

## Texto legal (resumo)

O app exibe conteúdo público oficial das NRs e **não substitui** consulta ao [portal gov.br](https://www.gov.br/trabalho-e-emprego/). Disclaimer completo no leitor — [spec/capabilities/reader/01-leitor.md](../spec/capabilities/reader/01-leitor.md).
