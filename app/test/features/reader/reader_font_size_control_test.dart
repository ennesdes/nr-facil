import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nrfacil/core/theme/app_theme.dart';
import 'package:nrfacil/features/reader/views/widgets/reader_font_size_control.dart';

void main() {
  testWidgets('ReaderFontSizeControl atualiza o valor exibido ao mudar fontSize',
      (tester) async {
    final fontSize = 16.0.obs;

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ReaderFontSizeControl(
            fontSize: fontSize,
            onDecrease: () => fontSize.value = 14,
            onIncrease: () => fontSize.value = 18,
          ),
        ),
      ),
    );

    expect(find.text('16'), findsOneWidget);

    await tester.tap(find.text('A+'));
    await tester.pump();

    expect(find.text('18'), findsOneWidget);
    expect(find.text('16'), findsNothing);

    await tester.tap(find.text('A−'));
    await tester.pump();

    expect(find.text('14'), findsOneWidget);
    expect(find.text('18'), findsNothing);
  });
}
