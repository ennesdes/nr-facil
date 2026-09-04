import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nrfacil/core/models/nr_structure.dart';
import 'package:nrfacil/core/theme/app_theme.dart';
import 'package:nrfacil/features/reader/views/widgets/nr_section_block.dart';

void main() {
  testWidgets('NrSectionBlock renderiza título e blocos sem card', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: NrSectionBlock(
            section: NrSection(
              id: '61-objetivo',
              number: '6.1',
              title: 'Objetivo',
              blocks: const [
                NrItemBlock(
                  number: '6.1.1',
                  depth: 2,
                  text: 'Esta norma estabelece...',
                ),
              ],
            ),
            fontSize: 16,
            nrId: 'nr-06',
            blockKeyFor: (_, _) => GlobalKey(),
          ),
        ),
      ),
    );

    expect(find.textContaining('6.1'), findsWidgets);
    expect(find.text('6.1.1'), findsOneWidget);
    expect(find.text('Esta norma estabelece...'), findsOneWidget);
    expect(find.byType(Card), findsNothing);
  });
}
