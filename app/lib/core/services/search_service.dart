import 'package:get/get.dart';

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
        _chunksByNr[entry.id] = chunks;
        AppLogger.debug(
            'Carregados ${chunks.length} chunks para ${entry.id}');
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
  /// Retorna lista de SearchResult com informações da NR.
  /// Se query vazia, retorna lista vazia.
  /// Se índice não carregado, carrega antes de buscar.
  Future<List<SearchResult>> search(String query) async {
    // Validar e normalizar query
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return [];
    }

    // Carregar chunks se ainda não carregados
    if (!isReady.value) {
      await _loadChunks();
    }

    final results = <SearchResult>[];

    // Iterar sobre todos os chunks de todas as NRs
    for (final entry in _chunksByNr.entries) {
      final nrId = entry.key;
      final chunks = entry.value;

      // Obter metadados da NR
      final nrEntry = contentService.manifest.value?.findNr(nrId);
      if (nrEntry == null) continue;

      // Filtrar chunks que contêm o termo de busca
      for (final chunk in chunks) {
        if (chunk.text.toLowerCase().contains(normalizedQuery)) {
          results.add(
            SearchResult(
              nrId: nrId,
              nrTitle: nrEntry.title,
              chunk: chunk,
            ),
          );
        }
      }
    }

    AppLogger.debug('Busca "$normalizedQuery" retornou ${results.length} resultados');
    return results;
  }
}

/// Resultado de busca — chunk com metadados da NR.
class SearchResult {
  final String nrId;
  final String nrTitle;
  final SearchChunk chunk;

  SearchResult({
    required this.nrId,
    required this.nrTitle,
    required this.chunk,
  });
}
