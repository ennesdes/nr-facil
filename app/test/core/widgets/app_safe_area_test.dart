import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nrfacil/core/widgets/app_safe_area.dart';

void main() {
  group('AppBottomSheetBody', () {
    testWidgets('aplica inset inferior do sistema', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              viewPadding: EdgeInsets.only(bottom: 48),
            ),
            child: Scaffold(
              body: AppBottomSheetBody(
                child: const SizedBox(width: 200, height: 100),
              ),
            ),
          ),
        ),
      );

      final padding = tester.widget<Padding>(
        find.descendant(
          of: find.byType(AppBottomSheetBody),
          matching: find.byType(Padding),
        ),
      );
      expect(padding.padding, const EdgeInsets.only(bottom: 48));
    });

    testWidgets('prioriza teclado quando respondToKeyboard é true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              viewPadding: EdgeInsets.only(bottom: 48),
              viewInsets: EdgeInsets.only(bottom: 320),
            ),
            child: AppBottomSheetBody(
              respondToKeyboard: true,
              child: const SizedBox(width: 200, height: 100),
            ),
          ),
        ),
      );

      final padding = tester.widget<Padding>(
        find.descendant(
          of: find.byType(AppBottomSheetBody),
          matching: find.byType(Padding),
        ),
      );
      expect(padding.padding, const EdgeInsets.only(bottom: 320));
    });
  });
}
