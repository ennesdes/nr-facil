# Code Map — NR Fácil

> Índice técnico. Regras de produto: `spec/capabilities/<feature>/`.

## Estrutura `app/lib/`

```
app/lib/
├── main.dart, main_e2e.dart
├── core/
│   ├── bindings/app_binding.dart
│   ├── constants/ (app_config, storage_keys, e2e_semantics_ids, official_sources)
│   ├── controllers/theme_controller.dart
│   ├── models/ (manifest, app_meta, company_profile, …)
│   ├── services/ (content_service, storage_service, search_service, compliance_service)
│   ├── theme/
│   └── widgets/
└── features/
    ├── home/
    ├── reader/
    ├── search/
    ├── updates/
    ├── compliance/
    ├── settings/
    └── ads/
```

## Features

| Feature | Caminho | Capability |
|---------|---------|------------|
| home | `app/lib/features/home/` | `spec/capabilities/home/` |
| reader | `app/lib/features/reader/` | `spec/capabilities/reader/` |
| search | `app/lib/features/search/` | `spec/capabilities/search/` |
| updates | `app/lib/features/updates/` | `spec/capabilities/updates/` |
| compliance | `app/lib/features/compliance/` | `spec/capabilities/compliance/` |
| settings | `app/lib/features/settings/` | `spec/capabilities/settings/` |
| ads | `app/lib/features/ads/` | `spec/capabilities/ads/` |

## Navegação

| Destino | Entrada |
|---------|---------|
| Shell | `GetMaterialApp(home: HomePage)` |
| Leitor | `ReaderNavigation.open` → `NrReaderPage` + `ReaderBinding` |
| Updates | Sino → `UpdatesPage` |
| Settings | App bar → `SettingsPage` |

## Serviços globais (`AppBinding`)

| Serviço | Arquivo |
|---------|---------|
| StorageService | `core/services/storage_service.dart` |
| ContentService | `core/services/content_service.dart` |
| SearchService | `core/services/search_service.dart` |
| ComplianceService | `core/services/compliance_service.dart` |
| AdsService | `features/ads/services/ads_service.dart` |
| HomeController / NormasController | `features/home/controllers/` |
| SearchScreenController | `features/search/controllers/` |

Ordem de registro: ver comentários em `app_binding.dart`.

## Storage keys

`app/lib/core/constants/storage_keys.dart` — favoritos, histórico, hashes por NR, tema, compliance.

## Pipeline (monorepo)

| Área | Caminho | Capability |
|------|---------|------------|
| Scripts | `scripts/` | `spec/capabilities/pipeline/` |
| Conteúdo | `content/`, `manifest.json`, `app_meta.json` | `spec/standards/domain/content/` |

## Testes

- `app/test/` — Flutter unit/widget
- `scripts/test_*.py` — pipeline
- E2E: `.maestro/flows/ci/`, `app/lib/main_e2e.dart`

## Integrações

| Integração | Onde |
|------------|------|
| GitHub raw | `AppConfig` URLs + `ContentService` |
| AdMob | `ads_service.dart`, `AppConfig.adsEnabled` |
| Firebase | Crashlytics/perf/analytics inicializados em `main.dart`; `core/utils/crash_reporting.dart`, `core/services/analytics_service.dart` (não é backend de conteúdo) |
