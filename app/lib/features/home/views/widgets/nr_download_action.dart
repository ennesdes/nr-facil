import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nrfacil/core/models/manifest.dart';
import 'package:nrfacil/core/services/content_service.dart';
import 'package:nrfacil/core/theme/app_spacing.dart';
import 'package:nrfacil/core/widgets/app_filter_chip.dart';
import 'package:nrfacil/core/widgets/app_modal_bottom_sheet.dart';
import 'package:nrfacil/core/widgets/app_snackbar.dart';
import 'package:nrfacil/features/home/views/widgets/nr_tile_icon_button.dart';

/// Ação de download offline para um tile de NR.
class NrDownloadAction extends StatelessWidget {
  final ManifestEntry nrEntry;

  const NrDownloadAction({required this.nrEntry, super.key});

  @override
  Widget build(BuildContext context) {
    if (nrEntry.isRevoked) return const SizedBox.shrink();

    final contentService = Get.find<ContentService>();

    return Obx(() {
      final nrId = nrEntry.id;
      contentService.nrAssetVersions[nrId];
      final isCached = contentService.isNrFullyCached(nrId);
      if (isCached) return const SizedBox.shrink();

      final isDownloading = contentService.isNrDownloading(nrId);
      final colorScheme = Theme.of(context).colorScheme;

      if (isDownloading) {
        return Tooltip(
          message: 'Baixando ${nrEntry.nrLabel}…',
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ),
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
            Align(
              alignment: Alignment.centerLeft,
              child: AppFilterChip(
                label: 'Baixar',
                icon: Icons.download,
                emphasized: true,
                onTap: () async {
                  Navigator.pop(context);
                  await _startDownload(contentService);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startDownload(ContentService contentService) async {
    final nrId = nrEntry.id;

    if (contentService.isNrFullyCached(nrId)) {
      AppSnackbar.showInfo(
        title: 'Já disponível offline',
        message: '${nrEntry.nrLabel} já está salva neste aparelho.',
      );
      return;
    }

    final ok = await contentService.downloadNrIfNeeded(nrId);
    if (ok) {
      AppSnackbar.showSuccess(
        title: 'Download concluído',
        message: '${nrEntry.nrLabel} disponível offline.',
      );
      return;
    }

    final error = contentService.lastError.value;
    if (error != null) {
      AppSnackbar.showError(title: 'Download', message: error);
    } else if (contentService.isNrDownloading(nrId)) {
      AppSnackbar.showInfo(
        title: 'Download em andamento',
        message: 'Aguarde a conclusão do download.',
      );
    }
  }
}
