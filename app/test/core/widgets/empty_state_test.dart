import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nrfacil/core/theme/app_theme.dart';
import 'package:nrfacil/core/widgets/empty_state.dart';

void main() {
  testWidgets('EmptyState exibe ícone, título e corpo', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: EmptyState(
            icon: Icons.search,
            title: 'Título',
            body: 'Corpo explicativo',
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.search), findsOneWidget);
    expect(find.text('Título'), findsOneWidget);
    expect(find.text('Corpo explicativo'), findsOneWidget);
  });

  testWidgets('EmptyState permanece legível com textScaleFactor 1.3',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: const Scaffold(
            body: EmptyState(
              icon: Icons.inbox_outlined,
              title: 'Nada por aqui',
              body: 'Texto ampliado para acessibilidade.',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Nada por aqui'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
