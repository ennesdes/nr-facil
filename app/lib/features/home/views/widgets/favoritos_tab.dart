import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nrfacil/core/services/content_service.dart';
import 'package:nrfacil/features/home/views/widgets/continuar_leitura_card.dart';
import 'package:nrfacil/features/home/views/widgets/empty_favoritos_state.dart';
import 'package:nrfacil/features/home/views/widgets/nr_list_tile.dart';
import 'package:nrfacil/features/reader/bindings/reader_binding.dart';
import 'package:nrfacil/features/reader/views/nr_reader_page.dart';

/// Aba "Favoritos" — exibir NRs favoritadas com reordenação.
///
/// Estrutura:
/// - Se vazio: EmptyFavoritosState
/// - Se não vazio:
///   - ContinuarLeituraCard (topo, se houver última NR aberta)
///   - ReorderableListView com favoritos
class FavoritosTab extends StatelessWidget {
  const FavoritosTab({super.key});

  @override
  Widget build(BuildContext context) {
    final contentService = Get.find<ContentService>();

    return Obx(
      () {
        // Mostrar estado vazio se sem favoritos
        if (contentService.favoriteIds.isEmpty) {
          return EmptyFavoritosState(manifest: contentService.manifest.value);
        }

        // Listar favoritos com reordenação
        return SingleChildScrollView(
          child: Column(
            children: [
              // Card "Continuar leitura"
              _buildContinuarLeituraSection(context, contentService),

              // ReorderableListView com favoritos
              _buildFavoritosList(context, contentService),
            ],
          ),
        );
      },
    );
  }

  /// Construir section de "Continuar leitura" se houver última NR aberta.
  Widget _buildContinuarLeituraSection(
    BuildContext context,
    ContentService contentService,
  ) {
    final lastOpenedNrId = contentService.lastOpenedNrId;
    if (lastOpenedNrId == null) return const SizedBox.shrink();

    final entry = contentService.manifest.value?.findNr(lastOpenedNrId);
    if (entry == null || entry.isRevoked) return const SizedBox.shrink();

    return ContinuarLeituraCard(
      nrEntry: entry,
      onTap: () {
        Get.to(
          () => NRReaderPage(nrId: lastOpenedNrId),
          binding: ReaderBinding(nrId: lastOpenedNrId),
        );
      },
    );
  }

  /// Construir ReorderableListView com favoritos.
  Widget _buildFavoritosList(
    BuildContext context,
    ContentService contentService,
  ) {
    return ReorderableListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      onReorderItem: (oldIndex, newIndex) {
        contentService.reorderFavorites(oldIndex, newIndex);
      },
      children: [
        for (final nrId in contentService.favoriteIds)
          _buildFavoritoTile(context, nrId, contentService),
      ],
    );
  }

  /// Construir um tile de favorito.
  Widget _buildFavoritoTile(
    BuildContext context,
    String nrId,
    ContentService contentService,
  ) {
    final entry = contentService.manifest.value?.findNr(nrId);
    if (entry == null) {
      // NR removida do manifest — removê-la de favoritos
      Future.microtask(() => contentService.toggleFavorite(nrId));
      return const SizedBox.shrink();
    }

    // Filtrar NRs revogadas de favoritos
    if (entry.isRevoked) {
      return const SizedBox.shrink();
    }

    return NrListTile(
      key: ValueKey(nrId),
      nrEntry: entry,
      isFavorite: true, // Always true in favoritos tab
      hasUpdate: contentService.hasUpdate(nrId),
      onTap: () {
        Get.to(
          () => NRReaderPage(nrId: nrId),
          binding: ReaderBinding(nrId: nrId),
        );
      },
      onToggleFavorite: () {
        contentService.toggleFavorite(nrId);
      },
    );
  }
}
