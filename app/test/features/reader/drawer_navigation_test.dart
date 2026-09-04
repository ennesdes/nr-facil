import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nrfacil/core/models/nr_structure.dart';
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
  double getScrollPosition(String nrId) => 0;

  @override
  String? getLastItemNumber(String nrId) => null;

  @override
  String? getLastHeadingViewed(String nrId) => null;

  @override
  void saveScrollPosition(
    String nrId,
    double position, {
    double? scrollMaxExtent,
    String? lastHeadingViewed,
    String? lastItemNumber,
  }) {}

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

  testWidgets('navigateToItemNumber rola até item distante no corpo estruturado',
      (tester) async {
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
}
