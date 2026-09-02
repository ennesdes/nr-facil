import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../ads/widgets/list_banner_ad.dart';
import '../../reader/bindings/reader_binding.dart';
import '../../reader/views/nr_reader_page.dart';
import '../controllers/search_screen_controller.dart';
import 'widgets/search_result_tile.dart';

/// SearchPage — tela de busca full-text com índice de chunks.
///
/// Exibe:
/// - TextField de busca com autofocus
/// - Estados: vazio inicial, carregando índice, sem resultados, lista de resultados
/// - Cada resultado mostra: título da NR, heading, snippet com highlight
/// - Ao tocar: navega para o leitor da NR com âncora inicial
class SearchPage extends GetView<SearchScreenController> {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SearchScreenController>(
      init: SearchScreenController(
        searchService: Get.find(),
      ),
      builder: (_) => Scaffold(
        appBar: AppBar(
          title: const Text('Buscar'),
          elevation: 1,
        ),
        body: Column(
          children: [
            // Campo de busca
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: controller.queryController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Buscar em todas as NRs...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: Obx(
                    () => controller.query.value.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: controller.clearSearch,
                          )
                        : const SizedBox.shrink(),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Obx(
                () => Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('Só favoritos'),
                      selected: controller.favoritesOnly.value,
                      onSelected: (value) {
                        controller.favoritesOnly.value = value;
                        if (controller.query.value.isNotEmpty) {
                          controller.performSearchNow();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Conteúdo
            Expanded(
              child: Obx(
                () {
                  // Carregando índice
                  if (controller.isIndexLoading.value) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Carregando índice de busca...'),
                        ],
                      ),
                    );
                  }

                  // Vazio inicial
                  if (!controller.hasSearched.value) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Digite para buscar',
                              style: Theme.of(context).textTheme.bodyLarge,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Buscando
                  if (controller.isSearching.value) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  // Sem resultados
                  if (controller.results.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.not_interested,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Nenhum resultado encontrado',
                              style: Theme.of(context).textTheme.bodyLarge,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tente outro termo de busca',
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Lista de resultados
                  return ListView.builder(
                    itemCount: controller.results.length,
                    itemBuilder: (context, index) {
                      final result = controller.results[index];
                      return SearchResultTile(
                        result: result,
                        searchQuery: controller.query.value,
                        onTap: () {
                          Get.to(
                            () => NRReaderPage(nrId: result.nrId),
                            binding: ReaderBinding(
                              nrId: result.nrId,
                              initialAnchor: result.chunk.heading,
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            const ListBannerAd(),
          ],
        ),
      ),
    );
  }
}
