import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nrfacil/core/theme/app_spacing.dart';
import 'package:nrfacil/core/widgets/app_safe_area.dart';
import 'package:nrfacil/core/widgets/empty_state.dart';
import 'package:nrfacil/features/updates/controllers/updates_controller.dart';
import 'package:nrfacil/features/updates/views/widgets/update_entry_card.dart';
import 'package:nrfacil/features/updates/views/widgets/updates_action_progress.dart';
import 'package:nrfacil/features/updates/views/widgets/updates_quick_actions.dart';
import 'package:nrfacil/features/updates/views/widgets/updates_summary_header.dart';

/// UpdatesPage — tela de atualizações de NRs.
///
/// Exibe:
/// - Lista de NRs com atualizações pendentes
/// - Detalhes granulares por norma (portaria, itens alterados)
/// - Tap abre o leitor (marca como vista no leitor)
/// - Estado vazio quando não há atualizações
class UpdatesPage extends GetView<UpdatesController> {
  const UpdatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atualizações'),
        actions: [
          Obx(
            () {
              final showDownload =
                  controller.offlineDownloadNeeded.value &&
                  !controller.isBulkDownloading;

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showDownload)
                    IconButton(
                      icon: const Icon(Icons.download_for_offline_outlined),
                      tooltip: 'Baixar tudo para offline',
                      onPressed: controller.downloadAllForOffline,
                    ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Verificar atualizações',
                    onPressed: controller.isChecking.value
                        ? null
                        : controller.checkForUpdates,
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: AppScaffoldBody(
        child: Obx(
          () {
            final updates = controller.updatedNrs.value;
            final isChecking = controller.isChecking.value;
            final isDownloading = controller.isBulkDownloading;
            final downloadProgress = controller.bulkSyncProgress.value;
            final showDownloadButton =
                controller.offlineDownloadNeeded.value && !isDownloading;
            final showProgress = isChecking ||
                (isDownloading &&
                    downloadProgress != null &&
                    downloadProgress.isActive);

            final progressCard = UpdatesActionProgress(
              isChecking: isChecking,
              downloadProgress: downloadProgress,
              onDownloadTap: isDownloading
                  ? () => controller.confirmCancelDownload(context)
                  : null,
            );

            if (updates.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  const EmptyState(
                    icon: Icons.notifications_off_outlined,
                    title: 'Nenhuma atualização disponível',
                    body: 'Suas normas estão em dia.',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (showProgress) ...[
                    progressCard,
                    const SizedBox(height: AppSpacing.md),
                  ],
                  UpdatesQuickActions(
                    isChecking: isChecking,
                    showDownloadButton: showDownloadButton,
                    onCheck: controller.checkForUpdates,
                    onDownload: controller.downloadAllForOffline,
                  ),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              itemCount: updates.length + (showProgress ? 2 : 1),
              itemBuilder: (context, index) {
                if (showProgress && index == 0) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      AppSpacing.xs,
                    ),
                    child: progressCard,
                  );
                }

                final summaryIndex = showProgress ? 1 : 0;
                if (index == summaryIndex) {
                  return UpdatesSummaryHeader(pendingCount: updates.length);
                }

                final entryIndex = index - summaryIndex - 1;
                final entry = updates[entryIndex];
                final updateEntry = controller.getUpdateEntry(entry.id);

                return UpdateEntryCard(
                  entry: entry,
                  updateEntry: updateEntry,
                  onTap: () => controller.openNrAndMarkSeen(entry),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
