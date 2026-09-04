import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nrfacil/core/utils/view_padding.dart';

void main() {
  group('ViewPadding', () {
    testWidgets('ensureSystemPadding copia viewPadding para padding', (tester) async {
      late MediaQueryData result;

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              viewPadding: EdgeInsets.only(bottom: 48),
              padding: EdgeInsets.zero,
            ),
            child: Builder(
              builder: (context) {
                result = ViewPadding.ensureSystemPadding(MediaQuery.of(context));
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(result.padding.bottom, 48);
      expect(result.viewPadding.bottom, 48);
    });

    testWidgets('bottomOf retorna inset inferior do sistema', (tester) async {
      late double bottom;

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              viewPadding: EdgeInsets.only(bottom: 32),
            ),
            child: Builder(
              builder: (context) {
                bottom = ViewPadding.bottomOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(bottom, 32);
    });
  });
}
