import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nrfacil/core/theme/app_theme.dart';
import 'package:nrfacil/core/utils/nr_id_utils.dart' as nr_id;
import 'package:nrfacil/features/reader/views/widgets/reader_app_bar.dart';

void main() {
  testWidgets('ReaderAppBar mostra NR-06 e botões principais', (tester) async {
    var searchTapped = false;
    var indexTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          appBar: ReaderAppBar(
            nrId: 'nr-06',
            isFavorite: false,
            isDarkMode: false,
            onOpenIndex: () => indexTapped = true,
            onOpenSearch: () => searchTapped = true,
            onToggleFavorite: () {},
            onIncreaseFontSize: () {},
            onDecreaseFontSize: () {},
            onToggleDarkMode: () {},
          ),
        ),
      ),
    );

    expect(find.text('NR-06'), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);
    expect(find.byIcon(Icons.list_alt), findsOneWidget);

    await tester.tap(find.byIcon(Icons.search));
    expect(searchTapped, isTrue);

    await tester.tap(find.byIcon(Icons.list_alt));
    expect(indexTapped, isTrue);
  });

  test('formatNrLabel formata id da NR', () {
    expect(nr_id.formatNrLabel('nr-06'), 'NR-06');
    expect(nr_id.formatNrLabel('nr-17'), 'NR-17');
  });
}
