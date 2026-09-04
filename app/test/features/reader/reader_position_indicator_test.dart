import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nrfacil/core/theme/app_theme.dart';
import 'package:nrfacil/features/reader/views/widgets/reader_position_indicator.dart';

void main() {
  testWidgets('ReaderPositionIndicator mostra item, caption e percentual',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Stack(
            children: const [
              ReaderPositionIndicator(
                itemLabel: '6.5.2',
                progressPercent: 68,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Item'), findsOneWidget);
    expect(find.text('6.5.2'), findsOneWidget);
    expect(find.text('68%'), findsOneWidget);
  });

  testWidgets('ReaderPositionIndicator mostra caption Seção para títulos',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Stack(
            children: const [
              ReaderPositionIndicator(
                itemLabel: '6.1 Objetivo',
                progressPercent: 12,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Seção'), findsOneWidget);
    expect(find.text('6.1 Objetivo'), findsOneWidget);
    expect(find.text('12%'), findsOneWidget);
  });
}
