import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nrfacil/core/models/nr_structure.dart';
import 'package:nrfacil/core/theme/app_theme.dart';
import 'package:nrfacil/features/reader/views/widgets/reader_drawer.dart';

void main() {
  testWidgets('ReaderDrawer destaca item atual e mostra posição', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ReaderDrawer(
            structure: NrStructure(
              title: 'NR 06',
              preamble: NrPreamble(blocks: []),
              sections: [
                NrSection(
                  id: '65-equip',
                  number: '6.5',
                  title: 'Equipamentos',
                  blocks: const [
                    NrItemBlock(
                      number: '6.5.1',
                      depth: 2,
                      text: 'Texto do item',
                    ),
                  ],
                ),
              ],
            ),
            legacyIndex: null,
            currentSectionId: '65-equip',
            currentItemNumber: '6.5.1',
            currentPositionLabel: '6.5.1',
            progressPercent: 42,
            onNavigate: (_) {},
            onNavigateToItem: (_) {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('6.5.1'), findsWidgets);
    expect(find.text('Você está em'), findsOneWidget);
    expect(find.text('42%'), findsOneWidget);
    expect(find.byIcon(Icons.my_location), findsOneWidget);
  });
}
