import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nrfacil/core/utils/responsive_layout.dart';

void main() {
  testWidgets('readerHorizontalPadding centraliza em telas largas', (tester) async {
    late double padding;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(900, 1200)),
          child: Builder(
            builder: (context) {
              padding = ResponsiveLayout.readerHorizontalPadding(context);
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    expect(padding, greaterThan(20));
    expect(padding, (900 - kReaderContentMaxWidth) / 2);
  });

  testWidgets('drawerWidth limita largura em tablet', (tester) async {
    late double width;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(1000, 1200)),
          child: Builder(
            builder: (context) {
              width = ResponsiveLayout.drawerWidth(context);
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    expect(width, kDrawerMaxWidth);
  });

  testWidgets('isCompactWidth detecta telas estreitas', (tester) async {
    late bool compact;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(360, 640)),
          child: Builder(
            builder: (context) {
              compact = ResponsiveLayout.isCompactWidth(context);
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    expect(compact, isTrue);
  });
}
