import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nrfacil/core/theme/app_theme.dart';
import 'package:nrfacil/core/widgets/nr_badge.dart';

void main() {
  testWidgets('NrBadge variantes exibem labels corretos', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Column(
            children: [
              const NrBadge(variant: NrBadgeVariant.update),
              const NrBadge(variant: NrBadgeVariant.revoked),
              const NrBadge(variant: NrBadgeVariant.downloaded),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Atualizada'), findsOneWidget);
    expect(find.text('Revogada'), findsOneWidget);
    expect(find.text('Baixada'), findsOneWidget);
  });
}
