# Telas e fluxo — transversal

> **SSOT:** invariantes globais de navegação. Detalhe por feature: `spec/capabilities/<feature>/`.

## Shell (`HomePage`)

| Elemento | Comportamento |
|----------|---------------|
| Bottom nav | **Normas** · **Favoritos** · **Buscar** · **Checklist** |
| Aba inicial | Favoritos se ≥1 favorito; senão Normas |
| App bar | Título da aba · sino (Normas) · ajustes (Normas) · ações do Checklist |
| Continuar leitura | Card no topo em Normas e Favoritos |
| Banner de ads | Listas permitidas — ver [`../../capabilities/ads/01-banners-listas.md`](../../capabilities/ads/01-banners-listas.md) |

## Rotas principais

| Destino | Como abrir | Notas |
|---------|------------|-------|
| Home | `GetMaterialApp(home: HomePage)` | `AppBinding` |
| Leitor | `ReaderNavigation.open(nrId, …)` | `ReaderBinding`; args `nrId`, anchor opcional |
| NR revogada | Tap em tile revogada | `RevokedNrPage` — sem leitor interno |
| Atualizações | Sino na app bar | `UpdatesPage` |
| Ajustes | Ícone na app bar (Normas) | `SettingsPage` |
| Perfil empresa | Checklist sem perfil | `CompanyProfilePage` |
| Checklist | Aba com perfil salvo | `ChecklistPage` |

Não há login nem rotas `/auth`.

## Leitor

| Regra | Comportamento |
|-------|---------------|
| Ads | **Proibido** no leitor |
| PDF MTE | Link no rodapé |
| Disclaimer legal | Fixo no rodapé |
| Índice lateral | `index.json` — navegação intra-NR |
| Atualização pendente | Banner + sheet — ver [`../../capabilities/reader/03-atualizacao-banner.md`](../../capabilities/reader/03-atualizacao-banner.md) |

## Busca

| Superfície | Escopo |
|------------|--------|
| Aba Buscar | Global em `search_index.json` |
| Menu do leitor | Só a NR aberta |

## Monetização (fases)

| Fase | Comportamento |
|------|---------------|
| Lançamento (5) | Grátis + AdMob em listas |
| Fase 6 | IAP `remove_ads_lifetime` — remove ads; diff premium a especificar na capability `updates` |

## Offline

- Leitura e busca usam cache após download.
- Sync via manifest GitHub raw — [`../domain/content_sync.md`](../domain/content_sync.md).

## Índice de capabilities

| Feature | Capability |
|---------|------------|
| home | [`../../capabilities/home/README.md`](../../capabilities/home/README.md) |
| reader | [`../../capabilities/reader/README.md`](../../capabilities/reader/README.md) |
| search | [`../../capabilities/search/README.md`](../../capabilities/search/README.md) |
| updates | [`../../capabilities/updates/README.md`](../../capabilities/updates/README.md) |
| compliance | [`../../capabilities/compliance/README.md`](../../capabilities/compliance/README.md) |
| settings | [`../../capabilities/settings/README.md`](../../capabilities/settings/README.md) |
| ads | [`../../capabilities/ads/README.md`](../../capabilities/ads/README.md) |
