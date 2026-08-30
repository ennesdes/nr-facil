import 'package:flutter_test/flutter_test.dart';
import 'package:nrfacil/core/models/search_chunk.dart';
import 'package:nrfacil/core/services/search_service.dart';
import 'package:nrfacil/core/services/content_service.dart';
import 'package:get/get.dart';

class FakeContentServiceForSearch implements ContentService {
  final Map<String, List<SearchChunk>> chunksByNr;

  FakeContentServiceForSearch(this.chunksByNr);

  @override
  final favoriteIds = <String>[].obs;
  @override
  final lastError = Rxn<String>();
  @override
  final manifest = Rxn();
  @override
  final appMeta = Rxn();
  @override
  final isSyncing = false.obs;
  @override
  final lastSyncedAt = Rxn<DateTime>();
  @override
  final unreadUpdatesCount = 0.obs;

  @override
  Future<List<SearchChunk>> readSearchIndex(String nrId) async {
    return chunksByNr[nrId] ?? [];
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('SearchService.searchInNr', () {
    late SearchService searchService;

    setUp(() {
      Get.testMode = true;
      final contentService = FakeContentServiceForSearch({
        'nr-06': [
          SearchChunk(
            id: 'chunk-0',
            text: 'O EPI deve ser fornecido gratuitamente',
            heading: '**6.5 Responsabilidades**',
            charOffset: 100,
          ),
          SearchChunk(
            id: 'chunk-1',
            text: 'Treinamento obrigatório do trabalhador',
            heading: '**6.7 Treinamentos**',
            charOffset: 200,
          ),
        ],
      });
      searchService = SearchService(contentService: contentService);
    });

    tearDown(() => Get.reset());

    test('retorna chunks que contêm o termo', () async {
      final results = await searchService.searchInNr('nr-06', 'EPI');
      expect(results, hasLength(1));
      expect(results.first.text, contains('EPI'));
    });

    test('retorna vazio para query vazia', () async {
      final results = await searchService.searchInNr('nr-06', '   ');
      expect(results, isEmpty);
    });

    test('busca é case-insensitive', () async {
      final results = await searchService.searchInNr('nr-06', 'treinamento');
      expect(results, hasLength(1));
    });
  });
}
