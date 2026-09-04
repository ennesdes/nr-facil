import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nrfacil/core/theme/app_theme.dart';
import 'package:nrfacil/features/reader/views/widgets/searchable_markdown_body.dart';

void main() {
  testWidgets('SearchableMarkdownBody destaca termo mantendo heading', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SearchableMarkdownBody(
            data: '# 1.1 Objetivo\nTexto com **objetivo** normativo.',
            highlightQuery: 'objetivo',
            styleSheet: MarkdownStyleSheet(
              h1: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              p: const TextStyle(fontSize: 14),
              strong: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('1.1 Objetivo'), findsOneWidget);
    expect(find.textContaining('objetivo'), findsWidgets);
  });
}
