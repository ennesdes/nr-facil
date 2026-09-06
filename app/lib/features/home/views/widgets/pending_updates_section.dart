import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nrfacil/core/services/content_service.dart';
import 'package:nrfacil/core/theme/app_spacing.dart';
import 'package:nrfacil/core/widgets/nr_badge.dart';
import 'package:nrfacil/core/widgets/update_highlight.dart';
import 'package:nrfacil/features/updates/views/widgets/updates_bottom_sheet.dart';

/// Card compacto de atualizações pendentes na home (acima de Continuar leitura).
class PendingUpdatesSection extends StatelessWidget {
  const PendingUpdatesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final contentService = Get.find<ContentService>();

    return Obx(() {
      if (!contentService.pendingUpdatesCardVisible.value) {
        return const SizedBox.shrink();
      }

      final entries = contentService.updatedNrs;
      if (entries.isEmpty) return const SizedBox.shrink();

      final nrLabels = entries.map((entry) => entry.nrLabel).join(', ');
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;

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
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  onTap: () => UpdatesBottomSheet.showAllPending(context),
                  child: Row(
                    children: [
                      UpdateHighlight.leadingStripe(
                        context: context,
                        visible: true,
                      ),
                      Icon(
                        Icons.update,
                        size: 20,
                        color: UpdateHighlight.accentColor(context),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Atualizações pendentes',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      letterSpacing: 0.5,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                const NrBadge(
                                  variant: NrBadgeVariant.update,
                                  compact: true,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              nrLabels,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: colorScheme.onSurface,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                tooltip: 'Dispensar',
                onPressed: contentService.dismissPendingUpdatesCard,
              ),
            ],
          ),
        ),
      );
    });
  }
}
