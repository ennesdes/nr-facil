import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nrfacil/core/models/nr_structure.dart';
import 'package:nrfacil/core/services/content_service.dart';
import 'package:nrfacil/features/reader/controllers/nr_reader_controller.dart';
import 'package:nrfacil/features/reader/views/widgets/nr_reader_search_sheet.dart';

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
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('NrReaderSearchSheet mostra contador e navegação', (tester) async {
    final fake = _FakeContentService();
    final controller = NRReaderController(
      nrId: 'nr-06',
      contentService: fake,
    );
    controller.structure.value = NrStructure(
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
              text: 'fornecimento de EPI',
            ),
          ],
        ),
        NrSection(
          id: '62-campo',
          number: '6.2',
          title: 'Campo',
          blocks: [],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NrReaderSearchSheet(controller: controller),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'objetivo');
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.textContaining('resultado'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_left), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });
}
