import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nrfacil/core/models/manifest.dart';
import 'package:nrfacil/core/services/content_service.dart';
import 'package:nrfacil/core/utils/user_messages.dart';
import 'package:nrfacil/core/widgets/empty_state.dart';
import 'package:nrfacil/core/widgets/shimmer_placeholders.dart';
import 'package:nrfacil/features/ads/widgets/list_banner_ad.dart';
import 'package:nrfacil/features/home/controllers/normas_controller.dart';
import 'package:nrfacil/features/home/views/widgets/continuar_leitura_section.dart';
import 'package:nrfacil/features/home/views/widgets/normas_list_header.dart';
import 'package:nrfacil/features/home/views/widgets/nr_list_tile.dart';
import 'package:nrfacil/features/reader/bindings/reader_binding.dart';
import 'package:nrfacil/features/reader/views/nr_reader_page.dart';
import 'package:nrfacil/features/reader/views/revoked_nr_page.dart';

/// Aba "Normas" — lista completa de NRs com busca e filtros.
class NormasTab extends StatelessWidget {
  const NormasTab({super.key});

  @override
  Widget build(BuildContext context) {
    final contentService = Get.find<ContentService>();
    final normasController = Get.find<NormasController>();

    return Obx(() {
      if (contentService.isManifestLoading) {
        return const NormasTabShimmer();
      }

      final manifest = contentService.manifest.value;
      final syncError = contentService.lastError.value;
      final hasManifest = manifest != null && manifest.nrs.isNotEmpty;

      if (!hasManifest) {
        final isOfflineNoCache =
            syncError == UserMessages.noNetworkNoLocal || syncError != null;

        return EmptyState(
          icon: isOfflineNoCache ? Icons.cloud_off : Icons.error_outline,
          title: isOfflineNoCache
              ? 'Sem conexão'
              : 'Erro ao carregar normas',
          body: syncError ??
              'Não foi possível carregar as normas. Tente novamente.',
          actions: [
            FilledButton.icon(
              onPressed: () => contentService.syncMetadata(),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        );
      }

      final entries = normasController.filteredEntries;

      if (entries.isEmpty) {
        return CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: NormasListHeader()),
            const SliverToBoxAdapter(child: ContinuarLeituraSection()),
            SliverFillRemaining(
              child: EmptyState(
                icon: Icons.search_off,
                title: 'Nenhuma norma encontrada',
                body: 'Tente outro termo ou filtro.',
              ),
            ),
          ],
        );
      }

      return CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: NormasListHeader()),
          const SliverToBoxAdapter(child: ContinuarLeituraSection()),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final entry = entries[index];
                return NrListTile(
                  nrEntry: entry,
                  isFavorite: contentService.isFavorite(entry.id),
                  hasUpdate: contentService.hasUpdate(entry.id),
                  isRevoked: entry.isRevoked,
                  showNotDownloaded: !entry.isRevoked &&
                      !contentService.isNrFullyCached(entry.id),
                  onTap: () => _openNr(entry),
                  onToggleFavorite: () {
                    contentService.toggleFavorite(entry.id);
                  },
                );
              },
              childCount: entries.length,
            ),
          ),
          const SliverToBoxAdapter(child: ListBannerAd()),
        ],
      );
    });
  }

  void _openNr(ManifestEntry entry) {
    if (entry.isRevoked) {
      Get.to(() => RevokedNrPage(entry: entry));
      return;
    }
    Get.to(
      () => NRReaderPage(nrId: entry.id),
      binding: ReaderBinding(nrId: entry.id),
    );
  }
}
