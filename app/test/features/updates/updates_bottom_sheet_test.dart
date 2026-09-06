import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nrfacil/core/models/app_meta.dart';
import 'package:nrfacil/core/models/manifest.dart';
import 'package:nrfacil/core/services/content_service.dart';
import 'package:nrfacil/core/theme/app_theme.dart';
import 'package:nrfacil/features/updates/views/widgets/updates_bottom_sheet.dart';

class FakeContentService implements ContentService {
  UpdateEntry? updateEntry;

  @override
  UpdateEntry? updateEntryFor(String nrId) => updateEntry;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ManifestEntry _entry(String id) {
  return ManifestEntry(
    id: id,
    title: 'Título $id',
    version: '1',
    hash: 'hash-$id',
    pdfHash: 'pdf-$id',
    updatedAt: DateTime(2024, 1, 1),
    url: 'https://example.com/$id.md',
  );
}

void main() {
  late FakeContentService contentService;

  setUp(() {
    contentService = FakeContentService();
  });

  testWidgets('UpdatesBottomSheet lista itens agrupados por NR',
      (tester) async {
    contentService.updateEntry = UpdateEntry(
      nrId: 'nr-06',
      title: 'NR 06',
      hash: 'hash-v2',
      summary: '2 itens alterados',
      items: [
        UpdateItem(item: '6.5', tipo: 'novo', resumo: 'Novo item'),
        UpdateItem(item: '6.21', tipo: 'alterado', resumo: 'Texto alterado'),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => UpdatesBottomSheet.show(
                    context: context,
                    entries: [_entry('nr-06')],
                    contentService: contentService,
                  ),
                  child: const Text('Abrir'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Atualizações pendentes'), findsOneWidget);
    expect(find.text('Item 6.5'), findsOneWidget);
    expect(find.text('Item 6.21'), findsOneWidget);
    expect(find.text('Novo'), findsOneWidget);
    expect(find.text('Alterado'), findsOneWidget);
  });
}
