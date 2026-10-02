# Banners em listas

> **SSOT:** `AdsService`, `PersistentBannerAd`, `ads_eligibility.dart`.

## Regras

| Condição | Então |
|----------|--------|
| Superfície permitida | Listas: Normas, Favoritos, Buscar, Checklist |
| Leitor | **Nunca** exibir anúncio |
| `AppConfig.adsEnabled` false | Sem chamadas AdMob (dev/review) |
| Falha ao init AdMob | App abre normalmente — log apenas |

## Fase 6 (IAP)

SKU `remove_ads_lifetime` remove banners — spec a atualizar quando implementado.
