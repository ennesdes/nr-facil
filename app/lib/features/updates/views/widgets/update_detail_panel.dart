import 'package:flutter/material.dart';
import 'package:nrfacil/core/models/app_meta.dart';
import 'package:nrfacil/core/theme/app_spacing.dart';
import 'package:nrfacil/core/theme/app_theme_extensions.dart';
import 'package:nrfacil/features/updates/utils/update_date_utils.dart';
import 'package:nrfacil/features/updates/views/widgets/update_items_list.dart';

/// Painel de detalhes granulares de uma atualização de NR.
class UpdateDetailPanel extends StatelessWidget {
  final UpdateEntry updateEntry;

  const UpdateDetailPanel({required this.updateEntry, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantics = context.semanticColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: semantics.infoContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: semantics.info.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history_edu_outlined, size: 18, color: semantics.info),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'O que mudou',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          if (updateEntry.createdAt != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Atualizado em ${formatUpdateDate(updateEntry.createdAt!)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (updateEntry.portaria != null &&
              updateEntry.portaria!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              updateEntry.portaria!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface,
              ),
              softWrap: true,
            ),
          ],
          if (updateEntry.items.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            UpdateItemsList(
              items: updateEntry.items,
              nrId: updateEntry.nrId,
              contentRef: updateEntry.contentRef,
              padding: EdgeInsets.zero,
              itemSpacing: AppSpacing.sm,
            ),
          ] else if (updateEntry.summary.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              updateEntry.summary,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
