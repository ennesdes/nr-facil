import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nrfacil/core/theme/app_theme.dart';
import 'package:nrfacil/features/reader/views/widgets/nr_item_row.dart';

void main() {
  testWidgets('NrItemRow mostra número em linha própria acima do texto',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: NrItemRow(
            nrId: 'nr-06',
            number: '6.5.1',
            depth: 3,
            text: 'O empregador deve fornecer EPI.',
            fontSize: 16,
          ),
        ),
      ),
    );

    expect(find.text('6.5.1'), findsOneWidget);
    expect(find.text('O empregador deve fornecer EPI.'), findsOneWidget);
    expect(find.byType(Card), findsNothing);
  });
}
