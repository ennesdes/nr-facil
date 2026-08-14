import 'package:flutter_test/flutter_test.dart';

import 'package:nrfacil/main.dart';

void main() {
  testWidgets('shows Hello World', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Hello World'), findsOneWidget);
  });
}
