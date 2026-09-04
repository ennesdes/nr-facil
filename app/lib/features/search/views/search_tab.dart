import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nrfacil/core/theme/app_spacing.dart';
import 'package:nrfacil/core/widgets/empty_state.dart';
import 'package:nrfacil/core/widgets/shimmer_placeholders.dart';
import 'package:nrfacil/features/ads/widgets/list_banner_ad.dart';
import 'package:nrfacil/features/reader/bindings/reader_binding.dart';
import 'package:nrfacil/features/reader/views/nr_reader_page.dart';
import 'package:nrfacil/features/search/controllers/search_screen_controller.dart';
import 'package:nrfacil/features/search/views/widgets/search_result_tile.dart';

/// Aba de busca full-text — corpo sem Scaffold (embutida na HomePage).
class SearchTab extends StatefulWidget {
  /// Quando true, o campo de busca recebe foco (aba Buscar ativa).
  final bool isActive;

  const SearchTab({
    this.isActive = false,
    super.key,
  });

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final _focusNode = FocusNode();

  SearchScreenController get _controller => Get.find<SearchScreenController>();

  @override
  void didUpdateWidget(SearchTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: TextField(
            controller: _controller.queryController,
            focusNode: _focusNode,
            decoration: InputDecoration(
              hintText: 'Buscar em todas as normas...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: Obx(
                () => _controller.query.value.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _controller.clearSearch,
                      )
                    : const SizedBox.shrink(),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 12,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Obx(
            () => Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Só favoritos'),
                  selected: _controller.favoritesOnly.value,
                  onSelected: (value) {
                    _controller.favoritesOnly.value = value;
                    if (_controller.query.value.isNotEmpty) {
                      _controller.performSearchNow();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Obx(
            () {
              if (_controller.isIndexLoading.value) {
                return const SearchResultsShimmer();
              }

              if (!_controller.hasSearched.value) {
                return const EmptyState(
                  icon: Icons.search,
                  title: 'Digite para buscar',
                  body: 'Busque por número, título ou trecho normativo',
                );
              }

              if (_controller.isSearching.value) {
                return const SearchResultsShimmer();
              }

              if (_controller.results.isEmpty) {
                return const EmptyState(
                  icon: Icons.not_interested,
                  title: 'Nenhum resultado encontrado',
                  body: 'Tente outro termo de busca',
                );
              }

              return ListView.builder(
                itemCount: _controller.results.length,
                itemBuilder: (context, index) {
                  final result = _controller.results[index];
                  return SearchResultTile(
                    result: result,
                    searchQuery: _controller.query.value,
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
    );
  }
}
