import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nrfacil/core/models/manifest.dart';
import 'package:nrfacil/core/services/content_service.dart';
import 'package:nrfacil/features/ads/widgets/list_banner_ad.dart';
import 'package:nrfacil/features/home/views/widgets/continuar_leitura_card.dart';
import 'package:nrfacil/features/home/views/widgets/nr_list_tile.dart';
import 'package:nrfacil/features/reader/bindings/reader_binding.dart';
import 'package:nrfacil/features/reader/views/nr_reader_page.dart';
import 'package:nrfacil/features/reader/views/revoked_nr_page.dart';

/// Aba "Todos" — exibir todas as NRs (incluindo revogadas).
///
/// Exibe:
/// - Filtro de busca por título (client-side, local)
/// - Status de sincronização/erro
/// - Lista de todas as NRs com badges (🆕, Revogada)
/// - Ícones de estrela para toggle favorito (desabilitados se revogada)
class TodosTab extends StatefulWidget {
  const TodosTab({super.key});

  @override
  State<TodosTab> createState() => _TodosTabState();
}

class _TodosTabState extends State<TodosTab> {
  final _filterController = TextEditingController();
  var _filterQuery = '';

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contentService = Get.find<ContentService>();

    return Obx(
      () {
        // Erro na sincronização (mas ainda mostra lista se houver manifest)
        final syncError = contentService.lastError.value;
        final hasManifest = contentService.manifest.value != null &&
            contentService.manifest.value!.nrs.isNotEmpty;

        if (!hasManifest && syncError != null) {
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
                    syncError,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          );
        }

        if (!hasManifest) {
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

        return SingleChildScrollView(
          child: Column(
            children: [
              if (contentService.isSyncing.value)
                const LinearProgressIndicator(minHeight: 2),
              if (contentService.lastSyncedLabel != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      contentService.lastSyncedLabel!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              // Card "Continuar leitura"
              _buildContinuarLeituraSection(context, contentService),

              // Campo de filtro
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  controller: _filterController,
                  decoration: InputDecoration(
                    hintText: 'Filtrar por número ou título...',
                    prefixIcon: const Icon(Icons.filter_list),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _filterQuery = value.toLowerCase().trim();
                    });
                  },
                ),
              ),

              // Lista de NRs
              _buildNrsList(context, contentService),
              const ListBannerAd(),
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

  /// Construir lista de NRs filtradas.
  Widget _buildNrsList(
    BuildContext context,
    ContentService contentService,
  ) {
    // Ordenar por número e filtrar
    final allNrs = List<ManifestEntry>.from(contentService.manifest.value!.nrs)
      ..sort(ManifestEntry.compareByNumber);
    final filteredNrs = _filterQuery.isEmpty
        ? allNrs
        : allNrs
            .where(
              (nr) =>
                  nr.title.toLowerCase().contains(_filterQuery) ||
                  nr.nrLabel.toLowerCase().contains(_filterQuery) ||
                  nr.id.toLowerCase().contains(_filterQuery),
            )
            .toList();

    // Nenhum resultado de filtro
    if (filteredNrs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Nenhuma NR encontrada com "$_filterQuery"',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    // Listar NRs filtradas
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredNrs.length,
      itemBuilder: (context, index) {
        final entry = filteredNrs[index];
        return NrListTile(
          nrEntry: entry,
          isFavorite: contentService.isFavorite(entry.id),
          hasUpdate: contentService.hasUpdate(entry.id),
          isRevoked: entry.isRevoked,
          showNotDownloaded:
              !entry.isRevoked && !contentService.isNrFullyCached(entry.id),
          onTap: () {
            if (entry.isRevoked) {
              Get.to(() => RevokedNrPage(entry: entry));
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
  }
}
