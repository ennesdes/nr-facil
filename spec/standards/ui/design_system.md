# Design System — NR Fácil

> **SSOT visual detalhado:** [`../../../docs/design-system.md`](../../../docs/design-system.md) · marca [`../../../docs/brand.md`](../../../docs/brand.md).

## Princípios

1. Tokens em `app/lib/core/theme/` — sem cores/tamanhos hardcoded em features
2. Verde-teal institucional (`#0F5C4E`), Inter, Material 3
3. Tema system / light / dark via `ThemeController` (Ajustes)
4. Alvo de toque ≥ 48×48 dp
5. Leitor: tipografia legível, contraste AA — prioridade sobre decoração

## Arquivos Flutter

| Área | Caminho |
|------|---------|
| Cores / tema | `app_colors.dart`, `app_theme.dart`, `app_semantic_colors.dart` |
| Tipografia / espaçamento | `app_typography.dart`, `app_spacing.dart` |
| Widgets compartilhados | `app/lib/core/widgets/` |

## Componentes de produto

| Componente | Uso |
|------------|-----|
| `NrListTile` / tiles home | Listas de NRs |
| `UpdateBanner` | Atualização no leitor |
| `AppSnackbar` | Feedback global |
| `PersistentBannerAd` | Listas — ver capability `ads` |
| Shimmer placeholders | Loading de listas |

## Estados visuais

| Estado | Padrão |
|--------|--------|
| NR revogada | Esmaecido + badge |
| Atualização pendente | Badge no sino + banner no leitor |
| Erro / vazio | `EmptyState`, copy humanizada |

Alterações de token ou componente base: atualizar `docs/design-system.md` e este arquivo se a regra de produto mudar.
