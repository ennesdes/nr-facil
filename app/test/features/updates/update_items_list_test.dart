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
        home: Scaffold(body: child),
      );
    }

    testWidgets('renderiza lista vazia sem erro', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(const UpdateItemsList(items: [])));
      expect(find.byType(UpdateItemsList), findsOneWidget);
    });

    testWidgets('renderiza item tipo novo com ícone semântico',
        (WidgetTester tester) async {
      final items = [
        UpdateItem(
          item: '6.5',
          tipo: 'novo',
          resumo: 'Novo requisito adicionado',
        ),
      ];

      await tester.pumpWidget(wrap(UpdateItemsList(items: items)));

      expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
      expect(find.text('6.5'), findsOneWidget);
      expect(find.text('Novo requisito adicionado'), findsOneWidget);
    });

    testWidgets('renderiza item tipo removido com ícone semântico',
        (WidgetTester tester) async {
      final items = [
        UpdateItem(
          item: '6.21',
          tipo: 'removido',
          resumo: 'Requisito descontinuado',
        ),
      ];

      await tester.pumpWidget(wrap(UpdateItemsList(items: items)));

      expect(find.byIcon(Icons.remove_circle_outline), findsOneWidget);
      expect(find.text('6.21'), findsOneWidget);
      expect(find.text('Requisito descontinuado'), findsOneWidget);
    });

    testWidgets('renderiza item tipo alterado com ícone semântico',
        (WidgetTester tester) async {
      final items = [
        UpdateItem(
          item: '6.1',
          tipo: 'alterado',
          resumo: 'Texto atualizado para maior clareza',
        ),
      ];

      await tester.pumpWidget(wrap(UpdateItemsList(items: items)));

      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      expect(find.text('6.1'), findsOneWidget);
      expect(find.text('Texto atualizado para maior clareza'), findsOneWidget);
    });

    testWidgets('renderiza múltiplos itens de tipos diferentes',
        (WidgetTester tester) async {
      final items = [
        UpdateItem(item: '6.1', tipo: 'novo', resumo: 'Novo artigo'),
        UpdateItem(item: '6.5', tipo: 'alterado', resumo: 'Modificação importante'),
        UpdateItem(item: '6.21', tipo: 'removido', resumo: 'Item removido'),
      ];

      await tester.pumpWidget(wrap(UpdateItemsList(items: items)));

      expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      expect(find.byIcon(Icons.remove_circle_outline), findsOneWidget);
      expect(find.text('6.1'), findsOneWidget);
      expect(find.text('6.5'), findsOneWidget);
      expect(find.text('6.21'), findsOneWidget);
    });

    testWidgets('renderiza item sem resumo corretamente',
        (WidgetTester tester) async {
      final items = [
        UpdateItem(item: '6.5', tipo: 'novo', resumo: ''),
      ];

      await tester.pumpWidget(wrap(UpdateItemsList(items: items)));

      expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
      expect(find.text('6.5'), findsOneWidget);
    });

    testWidgets('respeta padding customizado', (WidgetTester tester) async {
      final items = [
        UpdateItem(item: '6.5', tipo: 'novo', resumo: 'Teste'),
      ];

      await tester.pumpWidget(
        wrap(
          UpdateItemsList(
            items: items,
            padding: const EdgeInsets.all(32),
          ),
        ),
      );

      expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
    });

    testWidgets('renderiza tipo desconhecido com ícone padrão',
        (WidgetTester tester) async {
      final items = [
        UpdateItem(
          item: '6.5',
          tipo: 'desconhecido_tipo',
          resumo: 'Tipo não mapeado',
        ),
      ];

      await tester.pumpWidget(wrap(UpdateItemsList(items: items)));

      expect(find.byIcon(Icons.circle), findsOneWidget);
      expect(find.text('6.5'), findsOneWidget);
      expect(find.text('Tipo não mapeado'), findsOneWidget);
    });
  });
}
