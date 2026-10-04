import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nrfacil/core/models/search_chunk.dart';
import 'package:nrfacil/core/services/search_service.dart';
import 'package:nrfacil/core/theme/app_theme.dart';
import 'package:nrfacil/features/search/views/widgets/search_result_tile.dart';

void main() {
  testWidgets('tocar no snippet destacado abre o resultado', (tester) async {
    var taps = 0;
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ListView(
            children: [
              SearchResultTile(
                result: SearchResult(
                  nrId: 'nr-25',
                  nrTitle: 'RESÍDUOS INDUSTRIAIS',
                  chunk: SearchChunk(
                    id: 'chunk-0',
                    text: 'gerenciamento de resíduos industriais',
                    heading: '25.1 Objetivo',
                    charOffset: 0,
                  ),
                ),
                searchQuery: 'industriais',
                onTap: () => taps++,
              ),
            ],
          ),
        ),
      ),
    );

    // Snippet não pode ser selecionável — SelectableText engole o toque.
    expect(find.byType(SelectableText), findsNothing);

    await tester.tap(find.textContaining('gerenciamento', findRichText: true));
    await tester.pump();

    expect(taps, 1);
  });
}
