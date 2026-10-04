# Analytics (Firebase Analytics)

Telas e eventos-chave de produto. O código fica em `app/lib/core/services/analytics_service.dart` (`AnalyticsService`, registrado no `AppBinding`).

## Regras

- **Nunca** logar texto normativo, conteúdo de NR, dados do perfil da empresa nem PII. Só IDs de NR (`nr-06`), origem e termo de busca.
- Termo de busca: com `trim`, truncado em 100 chars (limite do GA4) e omitido se vazio.
- A coleta fica **desligada em debug** (`setAnalyticsCollectionEnabled(!kDebugMode)`), o que inclui `flutter test`. Ela liga em profile/release.
- Os métodos são fail-safe: viram no-op sem Firebase inicializado (testes, `main_e2e.dart`, falha de init) e nunca lançam.
- Os call sites usam `AnalyticsService.maybe` (`null` quando não registrado).
- Nomes em snake_case com ≤ 40 chars, e todos como constantes em `AnalyticsService`. Um evento novo precisa entrar neste catálogo no mesmo PR.
- A navegação é anônima (`Get.to`) e as abas da Home não são rotas, então `screen_view` é manual (sem `FirebaseAnalyticsObserver`).

## Telas (`screen_view`)

| screen_name | Onde é logado |
|-------------|---------------|
| `home_normas` / `home_favoritos` / `home_busca` / `home_checklist` | `HomeController._setTab`: aba inicial e `selectTab` |
| `reader` | `ReaderNavigation.open` |
| `updates` | sino da `HomePage` |
| `settings` | ícone de ajustes da `HomePage` |
| `company_profile` | `HomeController._navigateToCompanyProfile`, `ChecklistPage.editProfile` |
| `revoked_nr` | `NormasTab` / `FavoritosTab` ao abrir NR revogada |

## Eventos

| Evento | Parâmetros | Onde é logado |
|--------|-----------|------|
| `open_nr` | `nr_id`, `source` (`normas`, `favoritos`, `busca`, `atualizacoes`, `checklist`, `revogada`, `continuar_leitura`) | `ReaderNavigation.open` (`source` obrigatório) |
| `search` | `search_term`, `result_count` | `SearchScreenController._performSearch` (após debounce) |
| `favorite_add` / `favorite_remove` | `nr_id` | `ContentService.toggleFavorite` |
| `open_official_pdf` | `nr_id` | `NrReaderHeader` / `ReaderFooter` (só se `launchUrl` abriu) |
| `open_updates` | — | sino da `HomePage` |
| `acknowledge_update` | `nr_id`, `reason` (`sheetView`, `itemTap`, `bannerDismiss`, `summaryButton`) | `ContentService.acknowledgeNrUpdate` |

O SDK coleta automaticamente `first_open`, `session_start`, `user_engagement`, `app_update` e `in_app_purchase` (quando houver IAP).

## Verificação manual

```bash
adb shell setprop debug.firebase.analytics.app br.com.solvebetter.nrfacil
cd app && fvm flutter run --profile
```

Conferir em Firebase Console → Analytics → **DebugView**.
