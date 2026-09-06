import 'package:flutter/material.dart';
import 'package:nrfacil/core/models/app_meta.dart';
import 'package:nrfacil/core/models/manifest.dart';
import 'package:nrfacil/core/theme/app_spacing.dart';
import 'package:nrfacil/core/utils/display_text_utils.dart';
import 'package:nrfacil/core/widgets/nr_badge.dart';
import 'package:nrfacil/core/widgets/update_highlight.dart';
import 'package:nrfacil/features/updates/views/widgets/update_detail_panel.dart';

/// Card unificado para uma NR com atualização pendente.
class UpdateEntryCard extends StatelessWidget {
  final ManifestEntry entry;
  final UpdateEntry? updateEntry;
  final VoidCallback onTap;

  const UpdateEntryCard({
    required this.entry,
    required this.onTap,
    this.updateEntry,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final displayTitle = formatNrTitleForDisplay(entry.title);

    return Card(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      color: UpdateHighlight.backgroundColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: UpdateHighlight.cardBorderSide(
          context: context,
          active: true,
          colorScheme: colorScheme,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UpdateHighlight.leadingStripe(context: context, visible: true),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    entry.nrLabel,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  const Flexible(
                                    child: NrBadge(
                                      variant: NrBadgeVariant.update,
                                      compact: true,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                displayTitle,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurface,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                    if (updateEntry != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      UpdateDetailPanel(updateEntry: updateEntry!),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
