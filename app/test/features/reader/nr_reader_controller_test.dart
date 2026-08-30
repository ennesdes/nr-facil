import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nrfacil/core/models/app_meta.dart';
import 'package:nrfacil/core/models/nr_structure.dart';
import 'package:nrfacil/core/models/search_chunk.dart';
import 'package:nrfacil/core/services/content_service.dart';
import 'package:nrfacil/features/reader/controllers/nr_reader_controller.dart';

class FakeContentService implements ContentService {
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

  bool hasUpdateResult = false;
  UpdateEntry? updateEntryResult;
  final List<String> markNrAsSeenCalls = [];

  NrStructure? structureResult;
  String? contentResult;

  @override
  bool isFavorite(String nrId) => favoriteIds.contains(nrId);

  @override
  bool hasUpdate(String nrId) => hasUpdateResult;

  @override
  UpdateEntry? updateEntryFor(String nrId) => updateEntryResult;

  @override
  void markNrAsSeen(String nrId) => markNrAsSeenCalls.add(nrId);

  @override
  double getScrollPosition(String nrId) => 0.0;

  @override
  Future<NrStructure?> readNrStructure(String nrId) async => structureResult;

  @override
  Future<String?> readNrContent(String nrId) async => contentResult;

  @override
  Future<List<SearchChunk>> readSearchIndex(String nrId) async => [];

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NRReaderController — banner de atualização (CA7)', () {
    late FakeContentService fakeContentService;
    late NRReaderController controller;

    setUp(() {
      Get.testMode = true;
      fakeContentService = FakeContentService();
      controller = NRReaderController(
        nrId: 'nr-06',
        contentService: fakeContentService,
      );
    });

    tearDown(() {
      Get.reset();
    });

    test(
        'dismissUpdateBanner() esconde o banner e marca a NR como vista',
        () {
      controller.showUpdateBanner.value = true;
      controller.dismissUpdateBanner();
      expect(controller.showUpdateBanner.value, false);
      expect(fakeContentService.markNrAsSeenCalls, ['nr-06']);
    });

    test('getUpdateEntry() retorna a UpdateEntry da NR atual', () {
      final entry = UpdateEntry(
        nrId: 'nr-06',
        title: 'NR-06',
        hash: 'abc123',
        summary: '1 item alterado',
        items: [UpdateItem(item: '6.5', tipo: 'alterado', resumo: 'texto')],
      );
      fakeContentService.updateEntryResult = entry;
      expect(controller.getUpdateEntry(), same(entry));
    });
  });

  group('NRReaderController — navegação estruturada', () {
    late FakeContentService fake;

    setUp(() {
      Get.testMode = true;
      fake = FakeContentService();
      fake.contentResult = '# test';
      fake.structureResult = NrStructure(
        title: 'NR 06',
        preamble: NrPreamble(blocks: []),
        sections: [
          NrSection(
            id: '61-objetivo',
            number: '6.1',
            title: 'Objetivo',
            blocks: [],
          ),
        ],
      );
    });

    tearDown(() => Get.reset());

    test('useStructuredView é true quando há seções', () {
      final controller = NRReaderController(
        nrId: 'nr-06',
        contentService: fake,
      );
      controller.structure.value = fake.structureResult;
      expect(controller.useStructuredView, isTrue);
    });

    test('expandSection adiciona id ao conjunto expandido', () {
      final controller = NRReaderController(
        nrId: 'nr-06',
        contentService: fake,
      );
      controller.expandSection('61-objetivo');
      expect(controller.isSectionExpanded('61-objetivo'), isTrue);
    });

    test('searchInDocument encontra título de seção e bloco', () async {
      fake.structureResult = NrStructure(
        title: 'NR 06',
        preamble: NrPreamble(blocks: []),
        sections: [
          NrSection(
            id: '61-objetivo',
            number: '6.1',
            title: 'Objetivo',
            blocks: [
              const NrItemBlock(
                number: '6.1.1',
                depth: 2,
                text: 'fornecimento de EPI ao trabalhador',
              ),
            ],
          ),
        ],
      );

      final controller = NRReaderController(
        nrId: 'nr-06',
        contentService: fake,
      );
      controller.structure.value = fake.structureResult;

      await controller.searchInDocument('objetivo');
      expect(controller.documentSearchResults, isNotEmpty);
      expect(controller.activeHighlightQuery.value, 'objetivo');
      expect(
        controller.documentSearchResults.any((h) => h.blockIndex == -1),
        isTrue,
      );

      await controller.searchInDocument('EPI');
      expect(controller.activeHighlightQuery.value, 'EPI');
      expect(
        controller.documentSearchResults.any((h) => h.blockIndex >= 0),
        isTrue,
      );
    });

    test('clearDocumentSearch limpa destaque e resultados', () async {
      fake.structureResult = NrStructure(
        title: 'NR 06',
        preamble: NrPreamble(blocks: []),
        sections: [
          NrSection(
            id: '61-objetivo',
            number: '6.1',
            title: 'Objetivo',
            blocks: [],
          ),
        ],
      );

      final controller = NRReaderController(
        nrId: 'nr-06',
        contentService: fake,
      );
      controller.structure.value = fake.structureResult;

      await controller.searchInDocument('objetivo');
      expect(controller.activeHighlightQuery.value, isNotNull);

      controller.clearDocumentSearch();
      expect(controller.documentSearchResults, isEmpty);
      expect(controller.activeHighlightQuery.value, isNull);
    });

    test('goToNextHit e goToPreviousHit navegam entre resultados', () async {
      fake.structureResult = NrStructure(
        title: 'NR 06',
        preamble: NrPreamble(blocks: []),
        sections: [
          NrSection(
            id: '61-objetivo',
            number: '6.1',
            title: 'Objetivo',
            blocks: [
              const NrItemBlock(
                number: '6.1.1',
                depth: 2,
                text: 'fornecimento de EPI ao trabalhador',
              ),
            ],
          ),
          NrSection(
            id: '62-campo',
            number: '6.2',
            title: 'Campo de aplicação',
            blocks: [],
          ),
        ],
      );

      final controller = NRReaderController(
        nrId: 'nr-06',
        contentService: fake,
      );
      controller.structure.value = fake.structureResult;

      await controller.searchInDocument('6.');
      expect(controller.matchCount, greaterThan(1));

      controller.goToNextHit();
      expect(controller.currentHitIndex.value, 1);

      controller.goToPreviousHit();
      expect(controller.currentHitIndex.value, 0);
    });

    test('activeHighlightQuery permanece com termo mesmo sem resultados', () async {
      fake.structureResult = NrStructure(
        title: 'NR 06',
        preamble: NrPreamble(blocks: []),
        sections: [
          NrSection(
            id: '61-objetivo',
            number: '6.1',
            title: 'Objetivo',
            blocks: [],
          ),
        ],
      );

      final controller = NRReaderController(
        nrId: 'nr-06',
        contentService: fake,
      );
      controller.structure.value = fake.structureResult;

      await controller.searchInDocument('termo_inexistente_xyz');
      expect(controller.documentSearchResults, isEmpty);
      expect(controller.activeHighlightQuery.value, 'termo_inexistente_xyz');
    });
  });
}
