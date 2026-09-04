import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nrfacil/core/services/content_service.dart';
import 'package:nrfacil/core/widgets/app_snackbar.dart';
import 'package:nrfacil/features/home/views/widgets/continuar_leitura_section.dart';
import 'package:nrfacil/features/home/views/widgets/empty_favoritos_state.dart';
import 'package:nrfacil/features/home/views/widgets/nr_list_tile.dart';
import 'package:nrfacil/features/reader/utils/reader_navigation.dart';
import 'package:nrfacil/features/reader/views/revoked_nr_page.dart';

/// Aba "Favoritos" — NRs favoritadas com reordenação.
class FavoritosTab extends StatefulWidget {
  const FavoritosTab({super.key});

  @override
  State<FavoritosTab> createState() => _FavoritosTabState();
}

class _FavoritosTabState extends State<FavoritosTab> {
  static var _revokedSnackShown = false;

  @override
  Widget build(BuildContext context) {
    final contentService = Get.find<ContentService>();

    return Obx(
      () {
        if (contentService.favoriteIds.isEmpty) {
          return EmptyFavoritosState(manifest: contentService.manifest.value);
        }

        _maybeNotifyRevokedFavorites(contentService);

        return ListView(
          children: [
            const ContinuarLeituraSection(),
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              onReorderItem: (oldIndex, newIndex) {
                contentService.reorderFavorites(oldIndex, newIndex);
              },
              children: [
                for (final nrId in contentService.favoriteIds)
                  _buildFavoritoTile(context, nrId, contentService),
              ],
            ),
          ],
        );
      },
    );
  }

  void _maybeNotifyRevokedFavorites(ContentService contentService) {
    if (_revokedSnackShown) return;

    final hasRevoked = contentService.favoriteIds.any((id) {
      final entry = contentService.manifest.value?.findNr(id);
      return entry?.isRevoked == true;
    });

    if (hasRevoked) {
      _revokedSnackShown = true;
      AppSnackbar.showInfo(
        title: 'Favorito revogado',
        message:
            'Uma ou mais normas favoritas foram revogadas. Toque para ver detalhes.',
      );
    }
  }

  Widget _buildFavoritoTile(
    BuildContext context,
    String nrId,
    ContentService contentService,
  ) {
    final entry = contentService.manifest.value?.findNr(nrId);
    if (entry == null) {
      Future.microtask(() => contentService.toggleFavorite(nrId));
      return SizedBox(key: ValueKey(nrId), width: 0, height: 0);
    }

    return NrListTile(
      key: ValueKey(nrId),
      nrEntry: entry,
      isFavorite: true,
      hasUpdate: contentService.hasUpdate(nrId),
      isRevoked: entry.isRevoked,
      showNotDownloaded:
          !entry.isRevoked && !contentService.isNrFullyCached(nrId),
      hideStarButton: entry.isRevoked,
      onTap: () {
        if (entry.isRevoked) {
          Get.to(() => RevokedNrPage(entry: entry));
          return;
        }
        ReaderNavigation.open(nrId: nrId);
      },
      onToggleFavorite: () {
        contentService.toggleFavorite(nrId);
      },
    );
  }
}
