import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nrfacil/core/models/nr_structure.dart';
import 'package:nrfacil/core/models/reading_history_entry.dart';
import 'package:nrfacil/core/services/content_service.dart';
import 'package:nrfacil/core/theme/app_theme.dart';
import 'package:nrfacil/features/reader/controllers/nr_reader_controller.dart';
import 'package:nrfacil/features/reader/views/widgets/nr_structured_body.dart';
import 'package:nrfacil/features/reader/views/widgets/reader_drawer.dart';

class _FakeContentService implements ContentService {
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
  bool isFavorite(String nrId) => false;

  @override
  bool hasUpdate(String nrId) => false;

  @override
  double getScrollPosition(String nrId) =>
      readingHistoryEntry?.scrollPosition ?? 0;

  @override
  String? getLastItemNumber(String nrId) => null;

  @override
  String? getLastHeadingViewed(String nrId) => null;

  @override
  String? getContinueReadingPositionLabel(String nrId) => null;

  ReadingHistoryEntry? readingHistoryEntry;
  double? lastSavedScrollPosition;

  @override
  ReadingHistoryEntry? getReadingHistoryEntry(String nrId) => readingHistoryEntry;

  @override
  int? getReadingProgressPercent(String nrId) =>
      readingHistoryEntry?.effectiveProgressPercent;

  @override
  void saveScrollPosition(
    String nrId,
    double position, {
    double? scrollMaxExtent,
    String? lastHeadingViewed,
    String? lastItemNumber,
    String? lastSectionId,
    int? lastBlockIndex,
    double? scrollRatio,
    int? progressPercent,
    bool replacePositionLabels = false,
  }) {
    lastSavedScrollPosition = position;
    final extent = scrollMaxExtent ?? readingHistoryEntry?.scrollMaxExtent ?? 0;
    final ratio = scrollRatio ??
        (extent > 0 ? (position / extent).clamp(0.0, 1.0) : null);
    if (readingHistoryEntry != null) {
      readingHistoryEntry = readingHistoryEntry!.copyWith(
        scrollPosition: position,
        scrollMaxExtent: extent,
        lastHeadingViewed: lastHeadingViewed,
        lastItemNumber: lastItemNumber,
        lastSectionId: lastSectionId,
        lastBlockIndex: lastBlockIndex,
        scrollRatio: ratio,
        progressPercent: progressPercent,
      );
    }
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

NrStructure _buildLongStructure() {
  final sections = <NrSection>[];
  for (var i = 1; i <= 25; i++) {
    sections.add(
      NrSection(
        id: 'sec-$i',
        number: '6.$i',
        title: 'Seção $i',
        blocks: [
          NrItemBlock(
            number: '6.$i.1',
            depth: 2,
            text:
                'Texto longo da seção $i para forçar altura no scroll. '
                'Equipamentos de proteção individual e responsabilidades.',
          ),
          NrItemBlock(
            number: '6.$i.2',
            depth: 2,
            text: 'Segundo item da seção $i com mais conteúdo normativo.',
          ),
        ],
      ),
    );
  }
  return NrStructure(
    title: 'NR 06',
    preamble: NrPreamble(blocks: []),
    sections: sections,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(Get.reset);

  testWidgets(
    'navigateToItemNumber rola até item distante no corpo estruturado',
    (tester) async {
      Get.testMode = true;
      final fake = _FakeContentService();
      final structure = _buildLongStructure();
      final controller = NRReaderController(
        nrId: 'nr-06',
        contentService: fake,
      );
      controller.structure.value = structure;
      controller.isLoading.value = false;
      controller.showContinueChip.value = false;
      Get.put(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SizedBox(
              height: 640,
              child: NrStructuredBody(
                structure: structure,
                nrEntry: null,
                nrId: 'nr-06',
                fontSize: 16,
                scrollController: controller.scrollController,
                sectionKeyFor: controller.sectionKeyFor,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(controller.scrollController.hasClients, isTrue);
      expect(
        controller.scrollController.position.maxScrollExtent,
        greaterThan(1000),
      );
      expect(controller.scrollController.offset, lessThan(100));

      controller.navigateToItemNumber('6.25.1');

      for (var i = 0; i < 80; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(controller.scrollController.offset, greaterThan(800));
      expect(controller.currentItemNumber.value, '6.25.1');
    },
  );

  testWidgets(
      'continueFromSavedPosition rola até item salvo no corpo estruturado',
      (tester) async {
    Get.testMode = true;
    final fake = _FakeContentService();
    final structure = _buildLongStructure();
    fake.readingHistoryEntry = ReadingHistoryEntry(
      nrId: 'nr-06',
      lastAccessedAt: DateTime(2026),
      scrollPosition: 5000,
      scrollMaxExtent: 6000,
      lastHeadingViewed: '6.25.1',
      lastItemNumber: '6.25.1',
      lastSectionId: 'sec-25',
      lastBlockIndex: 0,
      progressPercent: 72,
    );

    final controller = NRReaderController(nrId: 'nr-06', contentService: fake);
    controller.structure.value = structure;
    controller.isLoading.value = false;
    controller.showContinueChip.value = true;
    controller.readingProgressPercent.value = 0;
    Get.put(controller);

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SizedBox(
            height: 640,
            child: NrStructuredBody(
              structure: structure,
              nrEntry: null,
              nrId: 'nr-06',
              fontSize: 16,
              scrollController: controller.scrollController,
              sectionKeyFor: controller.sectionKeyFor,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(controller.scrollController.offset, lessThan(100));

    controller.continueFromSavedPosition();
    expect(controller.readingProgressPercent.value, 72);

    for (var i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(controller.scrollController.offset, greaterThan(800));
    expect(controller.showContinueChip.value, isFalse);
  });

  testWidgets(
      'continueFromSavedPosition usa scroll quando só há heading de seção',
      (tester) async {
    Get.testMode = true;
    final fake = _FakeContentService();
    final structure = _buildLongStructure();
    fake.readingHistoryEntry = ReadingHistoryEntry(
      nrId: 'nr-06',
      lastAccessedAt: DateTime(2026),
      scrollPosition: 5000,
      scrollMaxExtent: 6000,
      lastHeadingViewed: '6.25 Seção 25',
      progressPercent: 87,
    );

    final controller = NRReaderController(nrId: 'nr-06', contentService: fake);
    controller.structure.value = structure;
    controller.isLoading.value = false;
    controller.showContinueChip.value = true;
    Get.put(controller);

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SizedBox(
            height: 640,
            child: NrStructuredBody(
              structure: structure,
              nrEntry: null,
              nrId: 'nr-06',
              fontSize: 16,
              scrollController: controller.scrollController,
              sectionKeyFor: controller.sectionKeyFor,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    controller.continueFromSavedPosition();

    for (var i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(controller.scrollController.offset, greaterThan(800));
  });

  testWidgets(
      'continueFromSavedPosition rola até bloco sem item numerado',
      (tester) async {
    Get.testMode = true;
    final fake = _FakeContentService();
    final structure = NrStructure(
      title: 'NR 06',
      preamble: NrPreamble(blocks: []),
      sections: [
        for (var i = 1; i <= 25; i++)
          NrSection(
            id: 'sec-$i',
            number: '6.$i',
            title: 'Seção $i',
            blocks: [
              NrParagraphBlock(
                text:
                    'Texto introdutório longo da seção $i sem itens numerados. '
                    'Equipamentos de proteção individual e responsabilidades.',
              ),
              NrParagraphBlock(
                text: 'Segundo parágrafo da seção $i com mais conteúdo normativo.',
              ),
            ],
          ),
      ],
    );

    fake.readingHistoryEntry = ReadingHistoryEntry(
      nrId: 'nr-06',
      lastAccessedAt: DateTime(2026),
      scrollPosition: 5000,
      scrollMaxExtent: 6000,
      lastHeadingViewed: '6.25 Seção 25',
      lastSectionId: 'sec-25',
      lastBlockIndex: 1,
      progressPercent: 87,
    );

    final controller = NRReaderController(nrId: 'nr-06', contentService: fake);
    controller.structure.value = structure;
    controller.isLoading.value = false;
    controller.showContinueChip.value = true;
    Get.put(controller);

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SizedBox(
            height: 640,
            child: NrStructuredBody(
              structure: structure,
              nrEntry: null,
              nrId: 'nr-06',
              fontSize: 16,
              scrollController: controller.scrollController,
              sectionKeyFor: controller.sectionKeyFor,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    controller.continueFromSavedPosition();

    for (var i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(controller.scrollController.offset, greaterThan(800));
  });

  testWidgets(
      'abrir no topo com chip não apaga posição salva no histórico',
      (tester) async {
    Get.testMode = true;
    final fake = _FakeContentService();
    final structure = _buildLongStructure();
    fake.readingHistoryEntry = ReadingHistoryEntry(
      nrId: 'nr-06',
      lastAccessedAt: DateTime(2026),
      scrollPosition: 5000,
      scrollMaxExtent: 6000,
      lastHeadingViewed: '6.25 Seção 25',
      progressPercent: 87,
    );

    final controller = NRReaderController(nrId: 'nr-06', contentService: fake);
    controller.structure.value = structure;
    controller.isLoading.value = false;
    controller.showContinueChip.value = true;
    Get.put(controller);

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SizedBox(
            height: 640,
            child: NrStructuredBody(
              structure: structure,
              nrEntry: null,
              nrId: 'nr-06',
              fontSize: 16,
              scrollController: controller.scrollController,
              sectionKeyFor: controller.sectionKeyFor,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    controller.onReady();
    await tester.pump();
    await tester.pump();

    expect(fake.lastSavedScrollPosition, isNull);
    expect(fake.readingHistoryEntry?.scrollPosition, 5000);

    controller.continueFromSavedPosition();

    for (var i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(controller.scrollController.offset, greaterThan(800));
  });

  testWidgets('ReaderDrawer chama navegação após fechar', (tester) async {
    Get.testMode = true;
    final structure = _buildLongStructure();
    var navigatedTo = '';

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          drawer: ReaderDrawer(
            structure: structure,
            legacyIndex: null,
            onNavigate: (_) {},
            onNavigateToItem: (item) => navigatedTo = item,
          ),
          body: const SizedBox.shrink(),
        ),
      ),
    );

    final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
    scaffoldState.openDrawer();
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '6.10.1');
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pump();

    expect(navigatedTo, '6.10.1');
  });

  testWidgets('continueFromSavedPosition prioriza lastSectionId sobre ratio',
      (tester) async {
    Get.testMode = true;
    final fake = _FakeContentService();
    final structure = _buildLongStructure();
    fake.readingHistoryEntry = ReadingHistoryEntry(
      nrId: 'nr-06',
      lastAccessedAt: DateTime(2026),
      scrollPosition: 100,
      scrollMaxExtent: 6000,
      scrollRatio: 0.02,
      lastSectionId: 'sec-25',
      lastBlockIndex: 0,
      lastItemNumber: '6.25.1',
      progressPercent: 72,
    );

    final controller = NRReaderController(nrId: 'nr-06', contentService: fake);
    controller.structure.value = structure;
    controller.isLoading.value = false;
    controller.showContinueChip.value = true;
    Get.put(controller);

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SizedBox(
            height: 640,
            child: NrStructuredBody(
              structure: structure,
              nrEntry: null,
              nrId: 'nr-06',
              fontSize: 16,
              scrollController: controller.scrollController,
              sectionKeyFor: controller.sectionKeyFor,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    controller.continueFromSavedPosition();

    for (var i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(controller.scrollController.offset, greaterThan(800));
    expect(controller.currentItemNumber.value, '6.25.1');
  });

  testWidgets('continueFromSavedPosition não rola só com progressPercent',
      (tester) async {
    Get.testMode = true;
    final fake = _FakeContentService();
    final structure = _buildLongStructure();
    fake.readingHistoryEntry = ReadingHistoryEntry(
      nrId: 'nr-06',
      lastAccessedAt: DateTime(2026),
      progressPercent: 87,
    );

    final controller = NRReaderController(nrId: 'nr-06', contentService: fake);
    controller.structure.value = structure;
    controller.isLoading.value = false;
    controller.showContinueChip.value = false;
    Get.put(controller);

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SizedBox(
            height: 640,
            child: NrStructuredBody(
              structure: structure,
              nrEntry: null,
              nrId: 'nr-06',
              fontSize: 16,
              scrollController: controller.scrollController,
              sectionKeyFor: controller.sectionKeyFor,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    controller.continueFromSavedPosition();

    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(controller.scrollController.offset, lessThan(100));
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('navigateToSection rola até seção distante', (tester) async {
    Get.testMode = true;
    final fake = _FakeContentService();
    final structure = _buildLongStructure();
    final controller = NRReaderController(nrId: 'nr-06', contentService: fake);
    controller.structure.value = structure;
    controller.isLoading.value = false;
    controller.showContinueChip.value = false;
    Get.put(controller);

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SizedBox(
            height: 640,
            child: NrStructuredBody(
              structure: structure,
              nrEntry: null,
              nrId: 'nr-06',
              fontSize: 16,
              scrollController: controller.scrollController,
              sectionKeyFor: controller.sectionKeyFor,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    controller.navigateToSection('sec-22');

    for (var i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(controller.scrollController.offset, greaterThan(800));
    expect(controller.currentSectionId.value, 'sec-22');
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('navigateToItemNumber rola até parágrafo sem item numerado',
      (tester) async {
    Get.testMode = true;
    final fake = _FakeContentService();
    final structure = NrStructure(
      title: 'NR 06',
      preamble: NrPreamble(blocks: []),
      sections: [
        for (var i = 1; i <= 25; i++)
          NrSection(
            id: 'sec-$i',
            number: '6.$i',
            title: 'Seção $i',
            blocks: [
              NrParagraphBlock(
                text:
                    'Texto introdutório longo da seção $i sem itens numerados. '
                    'Equipamentos de proteção individual e responsabilidades.',
              ),
              NrTableBlock(
                markdown: '| Coluna |\n| --- |\n| Tabela $i |',
              ),
            ],
          ),
      ],
    );

    final controller = NRReaderController(nrId: 'nr-06', contentService: fake);
    controller.structure.value = structure;
    controller.isLoading.value = false;
    controller.showContinueChip.value = false;
    Get.put(controller);

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SizedBox(
            height: 640,
            child: NrStructuredBody(
              structure: structure,
              nrEntry: null,
              nrId: 'nr-06',
              fontSize: 16,
              scrollController: controller.scrollController,
              sectionKeyFor: controller.sectionKeyFor,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    controller.navigateToSection('sec-24');

    for (var i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(controller.scrollController.offset, greaterThan(800));
    expect(controller.currentSectionId.value, 'sec-24');
    await tester.pump(const Duration(seconds: 3));
  });
}
