import 'package:flutter/material.dart';
import 'package:nrfacil/core/constants/semantics/management_semantics_ids.dart';
import 'package:nrfacil/core/models/app_meta.dart';
import 'package:nrfacil/core/models/manifest.dart';
import 'package:nrfacil/core/theme/app_spacing.dart';
import 'package:nrfacil/core/utils/display_text_utils.dart';
import 'package:nrfacil/core/widgets/nr_badge.dart';
import 'package:nrfacil/core/widgets/update_highlight.dart';
import 'package:nrfacil/features/updates/views/widgets/update_detail_panel.dart';

/// Card para uma NR com atualização pendente de revisão.
class UpdateEntryCard extends StatelessWidget {
  final ManifestEntry entry;
  final UpdateEntry? updateEntry;
  final VoidCallback onOpenNr;
  final ValueChanged<UpdateItem>? onItemTap;
  final VoidCallback? onMarkReviewed;

  const UpdateEntryCard({
    required this.entry,
    required this.onOpenNr,
    this.updateEntry,
    this.onItemTap,
    this.onMarkReviewed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final displayTitle = formatNrTitleForDisplay(entry.title);

    return Semantics(
      identifier: ManagementSemanticsIds.updateEntry(entry.id),
      child: Card(
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
                    if (updateEntry != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      UpdateDetailPanel(
                        updateEntry: updateEntry!,
                        onItemTap: onItemTap,
                        onMarkReviewed: onMarkReviewed,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Semantics(
                        identifier:
                            ManagementSemanticsIds.openNrFromUpdatesButton(
                              entry.id,
                            ),
                        button: true,
                        child: TextButton.icon(
                          onPressed: onOpenNr,
                          icon: const Icon(Icons.menu_book_outlined, size: 18),
                          label: const Text('Abrir norma'),
                        ),
                      ),
                    ),
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
