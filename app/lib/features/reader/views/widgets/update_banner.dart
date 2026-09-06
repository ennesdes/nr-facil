import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nrfacil/core/services/content_service.dart';
import 'package:nrfacil/core/theme/app_spacing.dart';
import 'package:nrfacil/core/theme/app_theme_extensions.dart';
import 'package:nrfacil/core/widgets/nr_badge.dart';
import 'package:nrfacil/features/reader/controllers/nr_reader_controller.dart';
import 'package:nrfacil/features/updates/views/widgets/updates_bottom_sheet.dart';

/// Banner dispensável indicando que a NR foi atualizada.
class UpdateBanner extends GetView<NRReaderController> {
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantics = context.semanticColors;
    final contentService = Get.find<ContentService>();
    final entry = contentService.manifest.value?.findNr(controller.nrId);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: semantics.warningContainer.withValues(alpha: 0.55),
        border: Border(
          bottom: BorderSide(
            color: semantics.warning.withValues(alpha: 0.45),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + AppSpacing.xs,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: InkWell(
                onTap: entry == null
                    ? null
                    : () => UpdatesBottomSheet.showForNr(
                          context,
                          entry: entry,
                          readerController: controller,
                        ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: semantics.warningContainer,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(
                          color: semantics.warning.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Icon(
                        Icons.update,
                        size: 20,
                        color: semantics.warning,
                      ),
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
                                  'Esta NR foi atualizada',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              const NrBadge(
                                variant: NrBadgeVariant.update,
                                compact: true,
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.xs),
                            child: Text(
                              'Toque para ver o que mudou.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
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
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              tooltip: 'Dispensar',
              onPressed: controller.dismissUpdateBanner,
            ),
          ],
        ),
      ),
    );
  }
}
