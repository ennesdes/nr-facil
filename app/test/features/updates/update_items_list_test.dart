import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nrfacil/core/models/app_meta.dart';
import 'package:nrfacil/core/theme/app_theme.dart';
import 'package:nrfacil/features/updates/views/widgets/update_items_list.dart';

void main() {
  group('UpdateItemsList Widget', () {
    Widget wrap(Widget child) {
      return MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      );
    }

    testWidgets('renderiza lista vazia sem erro', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(const UpdateItemsList(items: [])));
      expect(find.byType(UpdateItemsList), findsOneWidget);
    });

    testWidgets('renderiza item tipo novo com bloco Adicionado', (
      WidgetTester tester,
    ) async {
      final items = [
        UpdateItem(
          item: '6.5',
          tipo: 'novo',
          resumo: 'Novo requisito adicionado com texto completo.',
        ),
      ];

      await tester.pumpWidget(wrap(UpdateItemsList(items: items)));

      expect(find.text('Item 6.5'), findsOneWidget);
      expect(find.text('Adicionado:'), findsOneWidget);
      expect(
        find.text('Novo requisito adicionado com texto completo.'),
        findsOneWidget,
      );
    });

    testWidgets('renderiza item alterado com parágrafos Antes e Depois', (
      WidgetTester tester,
    ) async {
      final items = [
        UpdateItem(
          item: '6.1',
          tipo: 'alterado',
          resumo: '',
          antes: 'Texto completo do item antes da alteração normativa.',
          depois: 'Texto completo do item depois da alteração normativa.',
        ),
      ];

      await tester.pumpWidget(wrap(UpdateItemsList(items: items)));

      expect(find.text('Antes:'), findsOneWidget);
      expect(find.text('Depois:'), findsOneWidget);
      expect(
        find.text('Texto completo do item antes da alteração normativa.'),
        findsOneWidget,
      );
      expect(
        find.text('Texto completo do item depois da alteração normativa.'),
        findsOneWidget,
      );
      expect(find.textContaining('→'), findsNothing);
    });

    testWidgets('renderiza item de tabela com blocos Antes e Depois', (
      WidgetTester tester,
    ) async {
      final items = [
        UpdateItem(
          item: '3.4',
          tipo: 'alterado',
          resumo: '',
          kind: 'tabela',
          tabela: const UpdateTableChange(
            label: 'Tabela da página 12',
            antesAsset: 'assets/pages/page-012-table-00.png',
            depoisAsset: 'assets/pages/page-012-table-01.png',
          ),
        ),
      ];

      await tester.pumpWidget(
        wrap(
          UpdateItemsList(items: items, nrId: 'nr-03', contentRef: 'abc123'),
        ),
      );

      expect(find.text('Tabela alterada'), findsOneWidget);
      expect(find.text('Tabela da página 12'), findsOneWidget);
      expect(find.text('Antes:'), findsOneWidget);
      expect(find.text('Depois:'), findsOneWidget);
    });

    testWidgets('renderiza múltiplos itens', (WidgetTester tester) async {
      final items = [
        UpdateItem(item: '6.1', tipo: 'novo', resumo: 'Novo artigo'),
        UpdateItem(
          item: '6.5',
          tipo: 'alterado',
          resumo: '',
          antes: 'Antes',
          depois: 'Depois',
        ),
      ];

      await tester.pumpWidget(wrap(UpdateItemsList(items: items)));

      expect(find.text('Item 6.1'), findsOneWidget);
      expect(find.text('Item 6.5'), findsOneWidget);
    });
  });
}
