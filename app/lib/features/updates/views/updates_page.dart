import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nrfacil/core/models/app_meta.dart';
import 'package:nrfacil/core/theme/app_spacing.dart';
import 'package:nrfacil/core/widgets/empty_state.dart';
import 'package:nrfacil/features/home/views/widgets/nr_list_tile.dart';
import 'package:nrfacil/features/updates/controllers/updates_controller.dart';
import 'package:nrfacil/features/updates/views/widgets/update_items_list.dart';

/// UpdatesPage — tela de atualizações de NRs.
///
/// Exibe:
/// - Lista de NRs com atualizações pendentes
/// - Cada linha mostra: título + badge "🆕"
/// - Tap abre o leitor e marca como vista (badge desaparece)
/// - Estado vazio quando não há atualizações
class UpdatesPage extends GetView<UpdatesController> {
  const UpdatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atualizações'),
        elevation: 1,
        actions: [
          Obx(
            () => IconButton(
              icon: controller.isDownloadingAll.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_for_offline_outlined),
              tooltip: 'Baixar tudo para offline',
              onPressed: controller.isDownloadingAll.value
                  ? null
                  : controller.downloadAllForOffline,
            ),
          ),
          Obx(
            () => IconButton(
              icon: controller.isChecking.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              tooltip: 'Verificar atualizações',
              onPressed: controller.isChecking.value
                  ? null
                  : controller.checkForUpdates,
            ),
          ),
        ],
      ),
      body: Obx(
        () {
          final updates = controller.updatedNrs.value;

          // Estado vazio
          if (updates.isEmpty) {
            return EmptyState(
              icon: Icons.notifications_off_outlined,
              title: 'Nenhuma atualização disponível',
              body: 'Suas normas estão em dia.',
              actions: [
                Obx(
                  () => FilledButton.icon(
                    onPressed: controller.isChecking.value
                        ? null
                        : controller.checkForUpdates,
                    icon: controller.isChecking.value
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    label: const Text('Verificar atualizações'),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Obx(
                  () => OutlinedButton.icon(
                    onPressed: controller.isDownloadingAll.value
                        ? null
                        : controller.downloadAllForOffline,
                    icon: controller.isDownloadingAll.value
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download_for_offline_outlined),
                    label: const Text('Baixar tudo para offline'),
                  ),
                ),
              ],
            );
          }

          // Lista de atualizações
          return ListView.builder(
            itemCount: updates.length,
            itemBuilder: (context, index) {
              final entry = updates[index];
              final updateEntry = controller.getUpdateEntry(entry.id);

              return Column(
                children: [
                  NrListTile(
                    nrEntry: entry,
                    isFavorite: false,
                    hasUpdate: true, // Todas as NRs aqui têm atualização por definição
                    isRevoked: false,
                    hideStarButton: true, // Atualizações não suportam favoritar
                    onTap: () {
                      controller.openNrAndMarkSeen(entry);
                    },
                    onToggleFavorite: () {},
                  ),
                  // Renderizar detalhes de atualização se houver entrada correspondente
                  if (updateEntry != null)
                    _UpdateDetailCard(updateEntry: updateEntry)
                  else
                    const SizedBox.shrink(),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// Widget que exibe os detalhes granulares de uma atualização.
///
/// Mostra: data, portaria (se existir) e lista de itens granulares (se existirem).
/// Se não houver items, mostra o summary como texto simples.
class _UpdateDetailCard extends StatelessWidget {
  final UpdateEntry updateEntry;

  const _UpdateDetailCard({required this.updateEntry});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Data de atualização
              if (updateEntry.createdAt != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Atualizado em ${_formatDate(updateEntry.createdAt!)}',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),

              // Portaria
              if (updateEntry.portaria != null && updateEntry.portaria!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Portaria: ${updateEntry.portaria}',
                    style: textTheme.bodySmall,
                    softWrap: true,
                  ),
                ),

              // Lista de itens granulares (se houver) ou summary como fallback
              if (updateEntry.items.isNotEmpty)
                UpdateItemsList(
                  items: updateEntry.items,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemSpacing: 8,
                )
              else if (updateEntry.summary.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    updateEntry.summary,
                    style: textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Formatar data para exibição amigável
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateDay = DateTime(date.year, date.month, date.day);

    if (dateDay == today) {
      return 'hoje às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (dateDay == yesterday) {
      return 'ontem às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
  }
}
