import 'package:flutter/material.dart';
import 'package:nrfacil/core/models/manifest.dart';
import 'package:nrfacil/core/theme/app_spacing.dart';
import 'package:nrfacil/core/utils/display_text_utils.dart';

/// Card compacto "Continuar leitura".
class ContinuarLeituraCard extends StatelessWidget {
  final ManifestEntry nrEntry;
  final String? sectionLabel;
  final int? progressPercent;
  final VoidCallback onTap;

  const ContinuarLeituraCard({
    required this.nrEntry,
    required this.onTap,
    this.sectionLabel,
    this.progressPercent,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final displayTitle = formatNrTitleForDisplay(nrEntry.title);

    return Card(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CONTINUAR LENDO',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '${nrEntry.nrLabel} · $displayTitle',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (sectionLabel != null && sectionLabel!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        sectionLabel!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (progressPercent != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: progressPercent! / 100,
                                minHeight: 4,
                                backgroundColor: colorScheme.outline
                                    .withValues(alpha: 0.22),
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            '$progressPercent%',
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
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.sm, top: 20),
                child: Icon(
                  Icons.chevron_right,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
