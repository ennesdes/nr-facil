import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nrfacil/core/theme/app_theme.dart';
import 'package:nrfacil/core/utils/nr_id_utils.dart' as nr_id;
import 'package:nrfacil/features/reader/views/widgets/reader_app_bar.dart';

void main() {
  testWidgets('ReaderAppBar mostra voltar, NR-06, busca, índice e menu',
      (tester) async {
    var searchTapped = false;
    var indexTapped = false;
    var backTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          appBar: ReaderAppBar(
            nrId: 'nr-06',
            isFavorite: false,
            fontSize: 16,
            onBack: () => backTapped = true,
            onOpenIndex: () => indexTapped = true,
            onOpenSearch: () => searchTapped = true,
            onToggleFavorite: () {},
            onIncreaseFontSize: () {},
            onDecreaseFontSize: () {},
          ),
        ),
      ),
    );

    expect(find.text('NR-06'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);
    expect(find.byIcon(Icons.list_alt), findsOneWidget);
    expect(find.byIcon(Icons.menu), findsNothing);

    await tester.tap(find.byType(BackButton));
    expect(backTapped, isTrue);

    await tester.tap(find.byIcon(Icons.search));
    expect(searchTapped, isTrue);

    await tester.tap(find.byIcon(Icons.list_alt));
    expect(indexTapped, isTrue);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text('Tamanho do texto'), findsOneWidget);
    expect(find.text('16'), findsOneWidget);
  });

  test('formatNrLabel formata id da NR', () {
    expect(nr_id.formatNrLabel('nr-06'), 'NR-06');
    expect(nr_id.formatNrLabel('nr-17'), 'NR-17');
  });
}
