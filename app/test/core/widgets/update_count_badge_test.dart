import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nrfacil/core/theme/app_semantic_colors.dart';
import 'package:nrfacil/core/theme/app_theme.dart';
import 'package:nrfacil/core/widgets/update_count_badge.dart';

void main() {
  testWidgets(
    'UpdateCountBadge light: par warningContainer / onWarningContainer',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: UpdateCountBadge(count: 3)),
        ),
      );

      final semantics = AppTheme.light.extension<AppSemanticColors>()!;
      final text = tester.widget<Text>(find.text('3'));
      expect(text.style?.color, semantics.onWarningContainer);

      final decoration = _badgeDecoration(tester);
      expect(decoration.color, semantics.warningContainer);
    },
  );

  testWidgets(
    'UpdateCountBadge dark: par warningContainer / onWarningContainer',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(body: UpdateCountBadge(count: 3)),
        ),
      );

      final semantics = AppTheme.dark.extension<AppSemanticColors>()!;
      final text = tester.widget<Text>(find.text('3'));
      expect(text.style?.color, semantics.onWarningContainer);

      final decoration = _badgeDecoration(tester);
      expect(decoration.color, semantics.warningContainer);
    },
  );

  testWidgets('UpdateCountBadge oculto quando count <= 0', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: UpdateCountBadge(count: 0)),
      ),
    );
    expect(find.text('0'), findsNothing);
  });

  testWidgets('UpdateCountBadge exibe 99+ acima de 99', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: UpdateCountBadge(count: 120)),
      ),
    );
    expect(find.text('99+'), findsOneWidget);
  });
}

BoxDecoration _badgeDecoration(WidgetTester tester) {
  final containerFinder = find.descendant(
    of: find.byType(UpdateCountBadge),
    matching: find.byWidgetPredicate(
      (w) => w is Container && w.decoration is BoxDecoration,
    ),
  );
  final container = tester.widget<Container>(containerFinder);
  return container.decoration! as BoxDecoration;
}
