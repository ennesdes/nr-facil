import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nrfacil/features/reader/views/widgets/reader_app_bar.dart';

void main() {
  testWidgets('ReaderAppBar mostra NR-06 e botão de busca', (tester) async {
    var searchTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: ReaderAppBar(
            nrId: 'nr-06',
            onOpenSearch: () => searchTapped = true,
          ),
        ),
      ),
    );

    expect(find.text('NR-06'), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);
    expect(find.byIcon(Icons.add), findsNothing);

    await tester.tap(find.byIcon(Icons.search));
    expect(searchTapped, isTrue);
  });

  test('formatNrLabel formata id da NR', () {
    expect(ReaderAppBar.formatNrLabel('nr-06'), 'NR-06');
    expect(ReaderAppBar.formatNrLabel('nr-17'), 'NR-17');
  });
}
