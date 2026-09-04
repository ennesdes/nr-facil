import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nrfacil/core/theme/app_theme.dart';
import 'package:nrfacil/features/reader/views/widgets/highlighted_text.dart';

void main() {
  testWidgets('HighlightedText destaca termo case-insensitive', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: HighlightedText(
            text: 'Fornecimento de EPI ao trabalhador',
            highlight: 'epi',
          ),
        ),
      ),
    );

    expect(find.textContaining('EPI'), findsOneWidget);
    expect(find.textContaining('Fornecimento'), findsOneWidget);
  });
}
