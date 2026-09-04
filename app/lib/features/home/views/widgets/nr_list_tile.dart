import 'package:flutter/material.dart';
import 'package:nrfacil/core/models/manifest.dart';
import 'package:nrfacil/core/theme/app_spacing.dart';
import 'package:nrfacil/core/widgets/nr_badge.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final tile = ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      minVerticalPadding: AppSpacing.sm,
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            nrEntry.nrLabel,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nrEntry.title,
                  style: theme.textTheme.bodyLarge,
                ),
                if (hasUpdate || isRevoked) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      if (hasUpdate) const NrBadge(variant: NrBadgeVariant.update),
                      if (isRevoked) ...[
                        if (hasUpdate) const SizedBox(width: AppSpacing.sm),
                        const NrBadge(variant: NrBadgeVariant.revoked),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      trailing: (isRevoked || hideStarButton)
          ? (showNotDownloaded
              ? Icon(
                  Icons.cloud_off,
                  color: colorScheme.outline,
                  size: 20,
                )
              : null)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showNotDownloaded)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: Icon(
                      Icons.cloud_off,
                      color: colorScheme.outline,
                      size: 20,
                    ),
                  ),
                IconButton(
                  icon: Icon(isFavorite ? Icons.star : Icons.star_border),
                  color: isFavorite
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  tooltip: isFavorite
                      ? 'Remover dos favoritos'
                      : 'Adicionar aos favoritos',
                  onPressed: onToggleFavorite,
                ),
              ],
            ),
    );

    if (!isRevoked) return tile;

    return Opacity(opacity: 0.55, child: tile);
  }
}
