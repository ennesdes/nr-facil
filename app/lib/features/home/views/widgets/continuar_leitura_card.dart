import 'package:flutter/material.dart';
import 'package:nrfacil/core/models/manifest.dart';
import 'package:nrfacil/core/theme/app_spacing.dart';
import 'package:nrfacil/core/utils/display_text_utils.dart';
import 'package:nrfacil/core/widgets/nr_badge.dart';
import 'package:nrfacil/core/widgets/update_highlight.dart';
import 'package:nrfacil/features/home/views/widgets/nr_list_tile.dart';

/// Card compacto "Continuar leitura".
class ContinuarLeituraCard extends StatelessWidget {
  final ManifestEntry nrEntry;
  final String? sectionLabel;
  final int? progressPercent;
  final bool hasUpdate;
  final VoidCallback onTap;

  const ContinuarLeituraCard({
    required this.nrEntry,
    required this.onTap,
    this.sectionLabel,
    this.progressPercent,
    this.hasUpdate = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final displayTitle = formatNrTitleForDisplay(nrEntry.title);
    final clampedProgress = progressPercent?.clamp(0, 100);

    return Card(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: UpdateHighlight.cardBorderSide(
          context: context,
          active: hasUpdate,
          colorScheme: colorScheme,
        ),
      ),
      color: hasUpdate ? UpdateHighlight.backgroundColor(context) : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              UpdateHighlight.leadingStripe(
                context: context,
                visible: hasUpdate,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'CONTINUAR LENDO',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              letterSpacing: 0.5,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        if (hasUpdate)
                          const NrBadge(
                            variant: NrBadgeVariant.update,
                            compact: true,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      nrEntry.nrLabel,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: kNrListTileLabelTitleGap),
                    Text(
                      displayTitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (sectionLabel != null && sectionLabel!.isNotEmpty) ...[
                      Text(
                        sectionLabel!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (clampedProgress != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: clampedProgress / 100,
                                minHeight: 3,
                                backgroundColor: colorScheme.outline.withValues(
                                  alpha: 0.22,
                                ),
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            '$clampedProgress%',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
