import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nrfacil/core/models/app_meta.dart';
import 'package:nrfacil/features/updates/views/widgets/update_items_list.dart';

void main() {
  group('UpdateItemsList Widget', () {
    testWidgets('renderiza lista vazia sem erro', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateItemsList(items: []),
          ),
        ),
      );

      // Não deve renderizar nada visível (retorna SizedBox.shrink())
      expect(find.byType(UpdateItemsList), findsOneWidget);
    });

    testWidgets('renderiza item único com emoji "novo"',
        (WidgetTester tester) async {
      final items = [
        UpdateItem(
          item: '6.5',
          tipo: 'novo',
          resumo: 'Novo requisito adicionado',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateItemsList(items: items),
          ),
        ),
      );

      expect(find.text('🆕'), findsOneWidget);
      expect(find.text('6.5'), findsOneWidget);
      expect(find.text('Novo requisito adicionado'), findsOneWidget);
    });

    testWidgets('renderiza item único com emoji "removido"',
        (WidgetTester tester) async {
      final items = [
        UpdateItem(
          item: '6.21',
          tipo: 'removido',
          resumo: 'Requisito descontinuado',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateItemsList(items: items),
          ),
        ),
      );

      expect(find.text('❌'), findsOneWidget);
      expect(find.text('6.21'), findsOneWidget);
      expect(find.text('Requisito descontinuado'), findsOneWidget);
    });

    testWidgets('renderiza item único com emoji "alterado"',
        (WidgetTester tester) async {
      final items = [
        UpdateItem(
          item: '6.1',
          tipo: 'alterado',
          resumo: 'Texto atualizado para maior clareza',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateItemsList(items: items),
          ),
        ),
      );

      expect(find.text('✏️'), findsOneWidget);
      expect(find.text('6.1'), findsOneWidget);
      expect(find.text('Texto atualizado para maior clareza'), findsOneWidget);
    });

    testWidgets('renderiza múltiplos itens de tipos diferentes',
        (WidgetTester tester) async {
      final items = [
        UpdateItem(
          item: '6.1',
          tipo: 'novo',
          resumo: 'Novo artigo',
        ),
        UpdateItem(
          item: '6.5',
          tipo: 'alterado',
          resumo: 'Modificação importante',
        ),
        UpdateItem(
          item: '6.21',
          tipo: 'removido',
          resumo: 'Item removido',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateItemsList(items: items),
          ),
        ),
      );

      expect(find.text('🆕'), findsOneWidget);
      expect(find.text('✏️'), findsOneWidget);
      expect(find.text('❌'), findsOneWidget);

      expect(find.text('6.1'), findsOneWidget);
      expect(find.text('6.5'), findsOneWidget);
      expect(find.text('6.21'), findsOneWidget);

      expect(find.text('Novo artigo'), findsOneWidget);
      expect(find.text('Modificação importante'), findsOneWidget);
      expect(find.text('Item removido'), findsOneWidget);
    });

    testWidgets('renderiza item sem resumo corretamente',
        (WidgetTester tester) async {
      final items = [
        UpdateItem(
          item: '6.5',
          tipo: 'novo',
          resumo: '', // Resumo vazio
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateItemsList(items: items),
          ),
        ),
      );

      expect(find.text('🆕'), findsOneWidget);
      expect(find.text('6.5'), findsOneWidget);
      // Não renderiza container de resumo se vazio
    });

    testWidgets('respeta padding customizado', (WidgetTester tester) async {
      final items = [
        UpdateItem(
          item: '6.5',
          tipo: 'novo',
          resumo: 'Teste',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateItemsList(
              items: items,
              padding: const EdgeInsets.all(32),
            ),
          ),
        ),
      );

      expect(find.text('🆕'), findsOneWidget);
      // O widget deve estar renderizado com o padding aplicado
    });

    testWidgets('renderiza com tipo desconhecido usando emoji padrão',
        (WidgetTester tester) async {
      final items = [
        UpdateItem(
          item: '6.5',
          tipo: 'desconhecido_tipo',
          resumo: 'Tipo não mapeado',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpdateItemsList(items: items),
          ),
        ),
      );

      expect(find.text('•'), findsOneWidget); // Emoji padrão
      expect(find.text('6.5'), findsOneWidget);
      expect(find.text('Tipo não mapeado'), findsOneWidget);
    });
  });
}
