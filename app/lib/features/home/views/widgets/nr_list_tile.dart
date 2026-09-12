import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nrfacil/core/models/manifest.dart';
import 'package:nrfacil/core/services/content_service.dart';
import 'package:nrfacil/core/theme/app_spacing.dart';
import 'package:nrfacil/core/utils/display_text_utils.dart';
import 'package:nrfacil/core/widgets/nr_badge.dart';
import 'package:nrfacil/core/widgets/update_highlight.dart';
import 'package:nrfacil/core/widgets/nr_download_loading.dart';
import 'package:nrfacil/features/home/views/widgets/nr_download_action.dart';
import 'package:nrfacil/features/home/views/widgets/nr_tile_icon_button.dart';

/// Espaçamento entre o label NR e o título da norma.
const double kNrListTileLabelTitleGap = 2;

/// Tile reativo — observa favoritos e atualiza a estrela sem rebuild da lista.
class ReactiveNrListTile extends StatelessWidget {
  final ManifestEntry nrEntry;
  final ContentService contentService;
  final bool isRevoked;
  final bool hideStarButton;
  final VoidCallback onTap;

  const ReactiveNrListTile({
    required this.nrEntry,
    required this.contentService,
    required this.onTap,
    this.isRevoked = false,
    this.hideStarButton = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      contentService.favoritesVersion.value;
      contentService.nrAssetVersions[nrEntry.id];
      contentService.downloadingNrIds.length;
      final showNotDownloaded =
          !isRevoked && !contentService.isNrFullyCached(nrEntry.id);

      return Stack(
        children: [
          NrListTile(
            nrEntry: nrEntry,
            isFavorite: contentService.isFavorite(nrEntry.id),
            hasUpdate: contentService.hasUpdate(nrEntry.id),
            isRevoked: isRevoked,
            showNotDownloaded: showNotDownloaded,
            hideStarButton: hideStarButton,
            onTap: onTap,
            onToggleFavorite: () => contentService.toggleFavorite(nrEntry.id),
          ),
          if (contentService.isNrDownloading(nrEntry.id))
            NrListTileDownloadOverlay(label: nrEntry.nrLabel),
        ],
      );
    });
  }
}

/// Tile para exibir uma NR em lista.
class NrListTile extends StatelessWidget {
  final ManifestEntry nrEntry;
  final bool isFavorite;
  final bool hasUpdate;
  final bool showNotDownloaded;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final bool isRevoked;
  final bool hideStarButton;

  const NrListTile({
    required this.nrEntry,
    required this.isFavorite,
    required this.hasUpdate,
    this.showNotDownloaded = false,
    required this.onTap,
    required this.onToggleFavorite,
    this.isRevoked = false,
    this.hideStarButton = false,
    super.key,
  });

  bool get _showUpdateBadge => hasUpdate && !isRevoked;

  bool get _showActions =>
      (showNotDownloaded && !isRevoked) || (!isRevoked && !hideStarButton);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final displayTitle = formatNrTitleForDisplay(nrEntry.title);

    final labelColor = isRevoked
        ? colorScheme.onSurfaceVariant
        : colorScheme.primary;
    final titleColor = colorScheme.onSurface;

    return UpdateHighlight.listShell(
      active: _showUpdateBadge,
      context: context,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 12,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              nrEntry.nrLabel,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: labelColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_showUpdateBadge) ...[
                            const SizedBox(width: AppSpacing.sm),
                            const NrBadge(
                              variant: NrBadgeVariant.update,
                              compact: true,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: kNrListTileLabelTitleGap),
                      Text(
                        displayTitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: titleColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isRevoked) ...[
                        const SizedBox(height: AppSpacing.sm),
                        const NrBadge(variant: NrBadgeVariant.revoked),
                      ],
                    ],
                  ),
                ),
                if (_showActions)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showNotDownloaded) NrDownloadAction(nrEntry: nrEntry),
                      if (!isRevoked && !hideStarButton)
                        _FavoriteButton(
                          isFavorite: isFavorite,
                          onPressed: onToggleFavorite,
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onPressed;

  const _FavoriteButton({required this.isFavorite, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return NrTileIconButton(
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) {
          return ScaleTransition(scale: animation, child: child);
        },
        child: Icon(
          isFavorite ? Icons.star : Icons.star_border,
          key: ValueKey(isFavorite),
          color: isFavorite
              ? colorScheme.primary
              : colorScheme.onSurfaceVariant,
        ),
      ),
      tooltip: isFavorite ? 'Remover dos favoritos' : 'Adicionar aos favoritos',
      onPressed: onPressed,
    );
  }
}
