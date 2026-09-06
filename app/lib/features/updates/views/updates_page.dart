import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nrfacil/core/theme/app_spacing.dart';
import 'package:nrfacil/core/widgets/app_safe_area.dart';
import 'package:nrfacil/core/widgets/empty_state.dart';
import 'package:nrfacil/core/widgets/responsive_content.dart';
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
      appBar: AppBar(title: const Text('Atualizações')),
      body: AppScaffoldBody(
        child: ResponsiveContent(
          child: Obx(() {
            final updates = controller.updatedNrs.value;
            final isChecking = controller.isChecking.value;
            final isDownloading = controller.isBulkDownloading;
            final downloadProgress = controller.bulkSyncProgress.value;
            final showDownloadButton =
                controller.offlineDownloadNeeded.value && !isDownloading;
            final showProgress =
                isChecking ||
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

            final quickActions = Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.xs,
              ),
              child: UpdatesQuickActions(
                isChecking: isChecking,
                showDownloadButton: showDownloadButton,
                onCheck: controller.checkForUpdates,
                onDownload: controller.downloadAllForOffline,
              ),
            );

            if (updates.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  if (showProgress) ...[
                    progressCard,
                    const SizedBox(height: AppSpacing.md),
                  ],
                  EmptyState(
                    icon: Icons.notifications_off_outlined,
                    title: 'Nenhuma atualização disponível',
                    body: 'Suas normas estão em dia.',
                    actions: [
                      UpdatesQuickActions(
                        centered: true,
                        isChecking: isChecking,
                        showDownloadButton: showDownloadButton,
                        onCheck: controller.checkForUpdates,
                        onDownload: controller.downloadAllForOffline,
                      ),
                    ],
                  ),
                ],
              );
            }

            final headerCount = showProgress ? 3 : 2;

            return ListView.builder(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              itemCount: updates.length + headerCount,
              itemBuilder: (context, index) {
                if (index == 0) return quickActions;

                if (showProgress && index == 1) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      0,
                      AppSpacing.md,
                      AppSpacing.xs,
                    ),
                    child: progressCard,
                  );
                }

                final summaryIndex = showProgress ? 2 : 1;
                if (index == summaryIndex) {
                  return UpdatesSummaryHeader(pendingCount: updates.length);
                }

                final entryIndex = index - headerCount;
                final entry = updates[entryIndex];
                final updateEntry = controller.getUpdateEntry(entry.id);

                return UpdateEntryCard(
                  entry: entry,
                  updateEntry: updateEntry,
                  onTap: () => controller.openNrAndMarkSeen(entry),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}
