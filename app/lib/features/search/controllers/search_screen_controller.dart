import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/search_service.dart';
import '../../../core/utils/app_logger.dart';

/// Controller para SearchPage — gerencia estado da busca.
///
/// Responsabilidades:
/// - Gerenciar TextEditingController de busca
/// - Debounce de entrada para chamar SearchService.search
/// - Manter lista reativa de resultados
/// - Estado de carregamento do índice
///
/// Uso: GetView com SearchScreenController
class SearchScreenController extends GetxController {
  final SearchService searchService;

  SearchScreenController({
    required this.searchService,
  });

  /// Controlador de entrada de texto de busca
  late final TextEditingController queryController;

  /// Query normalizada atual
  final query = ''.obs;

  /// Resultados de busca
  final results = <SearchResult>[].obs;

  /// Se está buscando
  final isSearching = false.obs;

  /// Se o índice está carregando (primeira busca)
  final isIndexLoading = false.obs;

  /// Indicador se houve uma busca realizada
  final hasSearched = false.obs;

  /// Timer para debounce
  Timer? _debounceTimer;

  /// Duração do debounce em ms
  static const int _debounceMs = 300;

  @override
  void onInit() {
    super.onInit();
    queryController = TextEditingController();
    queryController.addListener(_onQueryChanged);

    // Observar estado de carregamento do índice
    ever(searchService.isLoading, (isLoading) {
      isIndexLoading.value = isLoading;
    });
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    queryController.dispose();
    super.onClose();
  }

  /// Chamado quando o texto de busca muda.
  /// Dispara debounce de 300ms antes de realizar a busca.
  void _onQueryChanged() {
    final q = queryController.text.trim();
    query.value = q;

    // Cancelar timer anterior
    _debounceTimer?.cancel();

    if (q.isEmpty) {
      results.clear();
      hasSearched.value = false;
      return;
    }

    // Iniciar novo timer
    _debounceTimer = Timer(
      const Duration(milliseconds: _debounceMs),
      () => _performSearch(q),
    );
  }

  /// Executar busca com debounce.
  Future<void> _performSearch(String searchQuery) async {
    if (searchQuery.isEmpty) return;

    isSearching.value = true;
    hasSearched.value = true;

    try {
      final searchResults = await searchService.search(searchQuery);
      results.value = searchResults;
      AppLogger.debug('Busca realizada: ${searchResults.length} resultados');
    } catch (e, st) {
      AppLogger.error('Erro ao buscar', e, st);
      results.clear();
    } finally {
      isSearching.value = false;
    }
  }

  /// Limpar busca e resultados.
  void clearSearch() {
    queryController.clear();
    results.clear();
    hasSearched.value = false;
  }
}
