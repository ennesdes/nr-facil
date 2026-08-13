# Scripts — cola rápida

Comandos para rodar **você** no terminal (zero tokens de IA).

## Setup (1x)

```bash
chmod +x scripts/setup.sh scripts/check.sh
./scripts/setup.sh
```

## Dia a dia

```bash
./scripts/check.sh                 # analyze + test + manifest
fvm flutter run                    # na pasta app/ ou: cd app && fvm flutter run
fvm flutter doctor -v
```

## Conteúdo (Fase 1+)

```bash
source .venv/bin/activate          # se usar venv
python scripts/convert_nr.py --nr nr-06
python scripts/convert_nr.py --all
python scripts/convert_nr.py --nr nr-06 --dry-run
python scripts/build_manifest.py
python scripts/validate_manifest.py
```

## Git

```bash
git status && git diff --stat
git add . && git commit -m "feat: descrição"
git push
```

## FVM

```bash
fvm install
fvm use
fvm flutter pub get
fvm flutter build appbundle
```

## Scripts planejados (criar na Fase 1)

| Script | Função |
|--------|--------|
| `convert_nr.py` | PDF → MD + assets (pymupdf4llm) |
| `build_manifest.py` | Gera `manifest.json` na raiz |
| `build_index.py` | Gera `index.json` + `search_index.json` |
| `validate_manifest.py` | Valida schema JSON |
| `update_nrs.py` | Download PDFs MTE + hash |
| `push_nr_updates.py` | INSERT no Supabase (Action) |

## Quando pedir IA

- Criar/editar código Dart ou Python → `docs/prompts.md`
- Converter PDF manualmente → **não** — use `convert_nr.py`
- Rodar testes → **não** — use `./scripts/check.sh`
