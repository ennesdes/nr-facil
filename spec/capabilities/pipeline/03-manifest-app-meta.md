# manifest.json e app_meta.json

- `build_manifest.py` — índice de todas NRs na raiz
- `build_app_meta.py` — `min_app_version` + `updates[]`
- `validate_manifest.py` — gate em `check.sh`

Commit único na Action com `content/` + ambos JSONs na raiz.

Schema: [`../../standards/domain/content/manifest-schema.md`](../../standards/domain/content/manifest-schema.md) e [`../updates/02-app-meta-feed.md`](../updates/02-app-meta-feed.md).
