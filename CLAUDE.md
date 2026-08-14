# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project status

This repo is pre-implementation (Fase 0 — Setup). There is no `app/` (Flutter project), no `content/` (converted NRs), and no `manifest.json` yet — those are created in later phases. Don't assume they exist; check before referencing paths under them.

**Always check [todo.md](todo.md) first.** It is the authoritative, ordered checklist (`[ ]` unchecked items) driving all work — find the next unchecked item and work on that unless the user directs otherwise. Don't skip ahead to later phases or re-open items under "Decisões registradas (não reabrir)" in todo.md.

## What this project is

NR Fácil — an Android app (Flutter) for offline access to Brazil's official Normas Regulamentadoras (NRs, workplace safety regulations from the Ministério do Trabalho e Emprego). Content is scraped/converted from official PDFs, versioned in this GitHub repo (the source of truth), and synced into the app. Supabase holds only lightweight metadata (update feed, minimum app version) — never the content itself.

## Monorepo layout (target state)

```
nr-facil/
├── .fvmrc                  # pinned Flutter version (FVM)
├── app/                    # Flutter Android app (not yet created)
├── content/                # converted NRs: nr-XX/{nr-XX.md, nr-XX.pdf, index.json, search_index.json, meta.json, assets/}
├── manifest.json           # remote index of all NRs (generated, root of repo)
├── scripts/                # Python content pipeline + shell helpers
├── docs/                   # architecture, procedures, Cursor prompts
└── .github/workflows/      # ci.yml, update-nrs.yml
```

Data flow: MTE portal PDFs → GitHub Action (`update-nrs.yml`, daily 09:00 UTC) runs the Python pipeline → commits `content/` + `manifest.json` to GitHub (source of truth) → Flutter app fetches manifest via GitHub raw HTTP and caches offline → Supabase only receives a lightweight `nr_updates` insert. **The app never talks to the MTE portal directly.**

## Commands

Setup and everyday checks (run from repo root):
```bash
./scripts/setup.sh          # FVM install/use, flutter pub get (once app/ exists), Python venv + requirements
./scripts/check.sh          # flutter analyze --fatal-infos + flutter test + validate_manifest.py — run before every commit
fvm flutter doctor -v
```

Flutter (once `app/` exists, from `app/`):
```bash
fvm flutter pub get
fvm flutter analyze --fatal-infos
fvm flutter test
fvm flutter test test/path/to/some_test.dart   # single test file
fvm flutter run
fvm flutter build appbundle
```

Content pipeline (Fase 1+, scripts not yet implemented — see `scripts/README.md` for the planned list: `convert_nr.py`, `build_manifest.py`, `build_index.py`, `update_nrs.py`, `push_nr_updates.py`):
```bash
source .venv/bin/activate
python scripts/convert_nr.py --nr nr-06
python scripts/convert_nr.py --all
python scripts/validate_manifest.py
```

`scripts/check.sh` and CI (`.github/workflows/ci.yml`) both no-op gracefully around missing pieces (`app/pubspec.yaml`, `manifest.json`) during early phases — don't "fix" that guarding logic, it's intentional for a repo that grows in phases.

## Content pipeline design (once implemented)

Principle: **never rewrite normative text** — only extract, structure, and display it better.

Three layers: extraction (`pymupdf4llm`, plus the original PDF saved + SHA-256 `pdf_hash`) → normalization (heading structure like `17.1`, strip PDF artifacts, fix hyphenation) → indices (`index.json` for navigation, `search_index.json` for chunked full-text search).

Tables/images use a 3-level fallback: `pymupdf4llm` → `pdfplumber` (complex tables, saved as HTML in `assets/tables/`) → full-page PNG render (`assets/pages/page-XX.png`) for diagrams pymupdf4llm can't handle.

The list of NRs, PDF/page URLs, and `revogada` status is generated dynamically by `discover_nrs.py` scraping the gov.br index page into `nr_index.json` — not hand-maintained. `scripts/nr_sources.json` only holds manual overrides for when scraping fails for a specific NR. There is no complexity classification (A–D) — every NR goes through the same uniform 3-pass extraction (text/tables/images) regardless of expected difficulty.

## Supabase

Supabase is metadata-only by design — it must never store Markdown, PDFs, images, or full text history. Only two tables: `app_versions` (minimum APK version) and `nr_updates` (update feed, ~200 rows/year). The app only ever `SELECT`s; only the GitHub Action writes (via `service_role`). Schema: `docs/supabase/migration.sql`.

## App architecture notes (for when `app/` is built)

- Bottom nav has exactly two tabs: **Favoritos** (default if the user has ≥1 favorite) and **Todos**. Update history/notifications live behind a bell icon in the app bar, not as a third tab.
- Update detection is hash-based: compare `last_synced_hash` (downloaded) vs `last_seen_hash` (viewed by user) per NR.
- Ads (`google_mobile_ads`) only appear in list screens (Favoritos/Todos/Busca) — **never in the reader**. IAP (`in_app_purchase`) is a single lifetime SKU `remove_ads_lifetime`.
- The reader must always show a link to the original PDF on the MTE portal and a fixed legal disclaimer — the app supplements, never replaces, official publications.

## Working with this repo as Claude Code

- `docs/prompts.md` contains a catalog of pre-written prompts per todo.md phase (I0–I10) — when implementing a checklist item, check there first for the intended scope/constraints before designing your own approach.
- `docs/architecture.md` is the consolidated technical reference (decisions table, data flow, manifest schema example, effort estimates) — treat it as authoritative over any ad hoc design choice.
- Scripts vs AI: PDF conversion, manifest generation/validation, and running tests are always done via the scripts/CI, never by hand-editing generated output or asking the assistant to "convert this PDF."
