import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nrfacil/core/services/content_service.dart';
import 'package:nrfacil/features/home/views/widgets/nr_list_tile.dart';
import 'package:nrfacil/features/reader/bindings/reader_binding.dart';
import 'package:nrfacil/features/reader/views/nr_reader_page.dart';

/// Aba "Todos" — exibir todas as NRs (incluindo revogadas).
///
/// Exibe:
/// - Status de sincronização/erro
/// - Lista de todas as NRs com badges (🆕, Revogada)
/// - Ícones de estrela para toggle favorito (desabilitados se revogada)
class TodosTab extends StatelessWidget {
  const TodosTab({super.key});

  @override
  Widget build(BuildContext context) {
    final contentService = Get.find<ContentService>();

    return Obx(
      () {
        // Estado de sincronização
        if (contentService.isSyncing.value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // Erro na sincronização
        if (contentService.lastError.value != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    contentService.lastError.value!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          );
        }

        // Sem manifest carregado
        if (contentService.manifest.value == null ||
            contentService.manifest.value!.nrs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Nenhuma NR disponível. Sincronize para carregar.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          );
        }

        // Listar todas as NRs
        final nrs = contentService.manifest.value!.nrs;
        return ListView.builder(
          itemCount: nrs.length,
          itemBuilder: (context, index) {
            final entry = nrs[index];
            return NrListTile(
              nrEntry: entry,
              isFavorite: contentService.isFavorite(entry.id),
              hasUpdate: contentService.hasUpdate(entry.id),
              isRevoked: entry.isRevoked,
              onTap: () {
                // Revogadas não abrem leitor por enquanto
                if (entry.isRevoked) {
                  // TODO: Implementar tela de detalhe de NR revogada (item 16)
                  return;
                }
                Get.to(
                  () => NRReaderPage(nrId: entry.id),
                  binding: ReaderBinding(nrId: entry.id),
                );
              },
              onToggleFavorite: () {
                contentService.toggleFavorite(entry.id);
              },
            );
          },
        );
      },
    );
  }
}
