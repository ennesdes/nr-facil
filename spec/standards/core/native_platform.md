# Integração nativa — Android (MVP)

> Validar `AndroidManifest.xml`, `build.gradle` e plugins ao adicionar dependência nativa.

## Quando consultar

- Novo plugin com canal nativo
- Erro Gradle / `MissingPluginException`
- Permissões (armazenamento, notificações futuras)
- AdMob, Firebase, `url_launcher`

## Permissões

- Declarar no Manifest só o necessário
- Pedir em runtime no momento de uso
- Tratar negada / negada permanentemente

## Plugins relevantes ao NR Fácil

| Plugin | Notas |
|--------|--------|
| `google_mobile_ads` | App ID no Manifest; test devices em debug |
| `firebase_core` / Crashlytics / Performance / Analytics | `google-services.json`; falha de init não bloqueia app; coleta desligada em debug; eventos em [`analytics.md`](analytics.md) |
| `url_launcher` | PDF MTE e links externos |
| `path_provider` | Cache de NRs offline |
| `permission_handler` / galeria | Salvar imagem da NR se aplicável |

## iOS

Fora do MVP Android — não assumir paridade até haver target iOS.

## Deep links

Não há OAuth/login — sem custom scheme de auth. Links externos via `url_launcher`.
