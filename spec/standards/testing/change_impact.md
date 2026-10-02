# Matriz de impacto em testes

| Área alterada | Testes mínimos |
|---------------|----------------|
| `app/lib/core/services/content_service.dart` | testes de sync/hash |
| `app/lib/core/services/compliance_service.dart` | testes de match OR |
| `app/lib/features/*/controllers/` | controller tests |
| `scripts/validate_manifest.py` | `test_validate_*` / manifest fixtures |
| `scripts/build_app_meta.py` | `scripts/test_build_app_meta.py` |
| Storage keys / shape JSON | round-trip `fromMap` + migration se houver |
| Semantics E2E | `scripts/check_e2e_semantics.py` |

Comentário em teste novo: `// spec: CA-<id>-NN` quando ligado a demanda BDD.
