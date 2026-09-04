import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nrfacil/core/theme/app_theme.dart';
import 'package:nrfacil/core/widgets/app_shimmer.dart';
import 'package:nrfacil/core/widgets/shimmer_placeholders.dart';

void main() {
  testWidgets('AppShimmerBox renderiza placeholder', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: AppShimmerBox(width: 100, height: 20),
        ),
      ),
    );

    expect(find.byType(AppShimmerBox), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 700));
    expect(tester.takeException(), isNull);
  });

  testWidgets('NormasTabShimmer exibe cabeçalho e lista', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const TickerMode(
          enabled: false,
          child: Scaffold(body: NormasTabShimmer()),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(NormasTabShimmer), findsOneWidget);
    expect(find.byType(NrListTileShimmer), findsWidgets);
  });
}
