import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nrfacil/core/models/nr_structure.dart';
import 'package:nrfacil/core/theme/app_theme.dart';
import 'package:nrfacil/features/reader/views/widgets/nr_preamble_section.dart';

void main() {
  testWidgets('NrPreambleSection inicia colapsado', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: NrPreambleSection(
            preamble: NrPreamble(
              blocks: [
                const NrParagraphBlock(text: 'Texto de publicação'),
              ],
            ),
            fontSize: 14,
            nrId: 'nr-06',
            isExpanded: false,
            blockKeyFor: (_, _) => GlobalKey(),
          ),
        ),
      ),
    );

    expect(find.text('Publicação e histórico'), findsOneWidget);
    expect(find.text('Texto de publicação'), findsNothing);

    await tester.tap(find.text('Publicação e histórico'));
    await tester.pumpAndSettle();

    expect(find.text('Texto de publicação'), findsOneWidget);
  });
}
