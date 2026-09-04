import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nrfacil/core/models/nr_structure.dart';
import 'package:nrfacil/core/theme/app_theme.dart';
import 'package:nrfacil/features/reader/views/widgets/nr_block_renderer.dart';
import 'package:nrfacil/features/reader/views/widgets/searchable_markdown_body.dart';

void main() {
  group('NrBlockRenderer', () {
    testWidgets('renderiza item numerado com badge', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: NrBlockRenderer(
              block: const NrItemBlock(
                number: '6.1.1',
                depth: 2,
                text: 'Texto do item normativo.',
              ),
              fontSize: 14,
              nrId: 'nr-06',
            ),
          ),
        ),
      );

      expect(find.text('6.1.1'), findsOneWidget);
      expect(find.text('Texto do item normativo.'), findsOneWidget);
    });

    testWidgets('renderiza lista com alíneas', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: NrBlockRenderer(
              block: NrListBlock(
                items: [
                  const NrListItem(label: 'a', text: 'Primeira alínea'),
                  const NrListItem(label: 'b', text: 'Segunda alínea'),
                ],
              ),
              fontSize: 14,
              nrId: 'nr-06',
            ),
          ),
        ),
      );

      expect(find.text('a)'), findsOneWidget);
      expect(find.text('Primeira alínea'), findsOneWidget);
      expect(find.text('Segunda alínea'), findsOneWidget);
    });

    testWidgets('renderiza tabela markdown com colunas', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: NrBlockRenderer(
              block: NrTableBlock(
                markdown:
                    '|**Publicação**|**D.O.U.**|\n|---|---|\n|Portaria MTP|06/07/78|',
              ),
              fontSize: 14,
              nrId: 'nr-06',
              highlightQuery: 'Portaria',
            ),
          ),
        ),
      );

      expect(find.byType(SearchableMarkdownBody), findsOneWidget);
      expect(find.textContaining('Portaria MTP'), findsOneWidget);
    });
  });
}
