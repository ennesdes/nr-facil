import 'package:get/get.dart';

import '../models/nr_structure.dart';
import '../models/search_chunk.dart';
import '../utils/app_logger.dart';
import 'content_service.dart';

/// SearchService — busca full-text em chunks de todas as NRs.
///
/// Responsabilidades:
/// - Carregar chunks de TODAS as NRs não revogadas para memória (lazy)
/// - Fazer busca simples (contains) por texto
/// - Retornar resultados com metadados da NR
///
/// Performance: Poucos milhares de chunks, O(n) simples é suficiente para &lt;1s.
/// Sem necessidade de índice invertido ou isolate separado.
class SearchService extends GetxService {
  final ContentService contentService;

  SearchService({
    required this.contentService,
  });

  /// Mapa de chunks por NR: nrId -> List&lt;SearchChunk&gt;
  /// Preenchido na primeira busca (lazy loading)
  final Map<String, List<SearchChunk>> _chunksByNr = {};

  /// Indicador se índice foi carregado
  final isReady = false.obs;

  /// Indicador se está carregando
  final isLoading = false.obs;

  /// Carregar chunks de todas as NRs não revogadas.
  /// Executado apenas uma vez, na primeira busca.
  Future<void> _loadChunks() async {
    if (isReady.value) return;

    isLoading.value = true;
    try {
      final manifest = contentService.manifest.value;
      if (manifest == null) {
        AppLogger.warning('Manifest não carregado. SearchService inoperável.');
        return;
      }

      // Iterar apenas sobre NRs não revogadas
      for (final entry in manifest.nrs.where((e) => !e.isRevoked)) {
        final chunks = await contentService.readSearchIndex(entry.id);
        _chunksByNr[entry.id] = List<SearchChunk>.from(chunks);

        // Indexar itens normativos do structure.json para busca por número
        final structure = await contentService.readNrStructure(entry.id);
        if (structure != null) {
          _appendStructureItemChunks(entry.id, structure, _chunksByNr[entry.id]!);
        }

        AppLogger.debug(
            'Carregados ${_chunksByNr[entry.id]!.length} chunks para ${entry.id}');
      }

      isReady.value = true;
      AppLogger.info('SearchService pronto. Total de NRs: ${_chunksByNr.length}');
    } catch (e, st) {
      AppLogger.error('Erro ao carregar chunks de busca', e, st);
    } finally {
      isLoading.value = false;
    }
  }

  /// Buscar chunks que contêm o texto (case-insensitive).
  ///
  /// [favoritesOnly] restringe a NRs favoritadas.
  /// [nrFilter] restringe a uma NR específica (ex.: nr-06).
  Future<List<SearchResult>> search(
    String query, {
    bool favoritesOnly = false,
    String? nrFilter,
  }) async {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return [];
    }

    if (!isReady.value) {
      await _loadChunks();
    }

    final itemNumberPattern = RegExp(r'^\d+(?:\.\d+)+$');
    final isItemNumberSearch = itemNumberPattern.hasMatch(normalizedQuery);

    final results = <SearchResult>[];

    for (final entry in _chunksByNr.entries) {
      final nrId = entry.key;
      final chunks = entry.value;

      if (nrFilter != null && nrFilter.isNotEmpty && nrId != nrFilter) {
        continue;
      }

      final nrEntry = contentService.manifest.value?.findNr(nrId);
      if (nrEntry == null) continue;

      if (favoritesOnly && !contentService.isFavorite(nrId)) {
        continue;
      }

      for (final chunk in chunks) {
        final haystack = chunk.text.toLowerCase();
        final matchesText = haystack.contains(normalizedQuery);
        final matchesItem = isItemNumberSearch &&
            haystack.contains('**$normalizedQuery**');

        if (matchesText || matchesItem) {
          results.add(
            SearchResult(
              nrId: nrId,
              nrTitle: nrEntry.title,
              chunk: chunk,
              score: _scoreResult(
                nrId: nrId,
                chunk: chunk,
                normalizedQuery: normalizedQuery,
                isItemNumberSearch: isItemNumberSearch,
              ),
            ),
          );
        }
      }
    }

    results.sort((a, b) => b.score.compareTo(a.score));

    AppLogger.debug('Busca "$normalizedQuery" retornou ${results.length} resultados');
    return results;
  }

  int _scoreResult({
    required String nrId,
    required SearchChunk chunk,
    required String normalizedQuery,
    required bool isItemNumberSearch,
  }) {
    var score = 0;
    if (contentService.isFavorite(nrId)) score += 10;

    final text = chunk.text.toLowerCase();
    if (isItemNumberSearch && text.contains('**$normalizedQuery**')) {
      score += 100;
    } else if (text.startsWith('**$normalizedQuery')) {
      score += 50;
    }

    // Preferir ocorrências mais cedo no documento
    score -= chunk.charOffset ~/ 10000;
    return score;
  }

  void _appendStructureItemChunks(
    String nrId,
    NrStructure structure,
    List<SearchChunk> chunks,
  ) {
    var offset = 0;
    for (final section in structure.sections) {
      for (final block in section.blocks) {
        if (block is NrItemBlock && block.number.isNotEmpty) {
          final text = '**${block.number}** ${block.text}';
          final exists = chunks.any(
            (c) =>
                c.text.toLowerCase().contains('**${block.number.toLowerCase()}**'),
          );
          if (!exists) {
            chunks.add(
              SearchChunk(
                id: 'item-${block.number}',
                text: text,
                heading: section.displayTitle,
                charOffset: offset,
              ),
            );
          }
          offset += text.length;
        }
      }
    }
  }

  /// Buscar dentro de uma NR específica (search_index.json local).
  Future<List<SearchChunk>> searchInNr(String nrId, String query) async {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return [];

    final chunks = await contentService.readSearchIndex(nrId);
    return chunks
        .where((chunk) => chunk.text.toLowerCase().contains(normalizedQuery))
        .toList();
  }
}

/// Resultado de busca — chunk com metadados da NR.
class SearchResult {
  final String nrId;
  final String nrTitle;
  final SearchChunk chunk;
  final int score;

  SearchResult({
    required this.nrId,
    required this.nrTitle,
    required this.chunk,
    this.score = 0,
  });
}
