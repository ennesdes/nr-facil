import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nrfacil/core/models/manifest.dart';
import 'package:nrfacil/core/services/content_service.dart';
import 'package:nrfacil/core/theme/app_spacing.dart';
import 'package:nrfacil/core/widgets/app_modal_bottom_sheet.dart';
import 'package:nrfacil/core/widgets/app_shimmer.dart';
import 'package:nrfacil/features/home/views/widgets/nr_tile_icon_button.dart';

/// Ação de download offline para um tile de NR.
class NrDownloadAction extends StatelessWidget {
  final ManifestEntry nrEntry;

  const NrDownloadAction({
    required this.nrEntry,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (nrEntry.isRevoked) return const SizedBox.shrink();

    final contentService = Get.find<ContentService>();

    return Obx(() {
      final nrId = nrEntry.id;
      final isCached = contentService.isNrFullyCached(nrId);
      if (isCached) return const SizedBox.shrink();

      final isDownloading = contentService.isNrDownloading(nrId);
      final colorScheme = Theme.of(context).colorScheme;

      if (isDownloading) {
        return const SizedBox(
          width: 48,
          height: 48,
          child: Center(child: AppShimmerIcon(size: 22)),
        );
      }

      return NrTileIconButton(
        icon: Icon(
          Icons.cloud_download_outlined,
          color: colorScheme.onSurfaceVariant,
        ),
        tooltip: 'Baixar para offline',
        onPressed: () => _showDownloadSheet(context, contentService),
      );
    });
  }

  void _showDownloadSheet(BuildContext context, ContentService contentService) {
    showAppModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Disponível apenas online',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Baixe ${nrEntry.nrLabel} para consultar sem internet.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () async {
                Navigator.pop(context);
                await contentService.downloadNrIfNeeded(nrEntry.id);
              },
              child: const Text('Baixar'),
            ),
          ],
        ),
      ),
    );
  }
}
