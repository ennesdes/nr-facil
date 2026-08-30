import 'package:flutter_test/flutter_test.dart';
import 'package:nrfacil/core/models/app_meta.dart';

void main() {
  group('UpdateEntry & UpdateItem Models', () {
    test('UpdateEntry.fromJson com todos os campos', () {
      final json = {
        'nr_id': 'nr-06',
        'title': 'NR 06 - EPI',
        'portaria': 'Portaria nº 123/2024',
        'hash': 'hash_06_v2',
        'pdf_hash': 'pdf_hash_06',
        'summary': '2 itens alterados',
        'items': [
          {
            'item': '6.5',
            'tipo': 'novo',
            'resumo': 'Novo requisito adicionado',
          },
          {
            'item': '6.21',
            'tipo': 'alterado',
            'resumo': 'Texto atualizado',
          },
        ],
        'created_at': '2024-08-15T10:30:00.000Z',
      };

      final entry = UpdateEntry.fromJson(json);

      expect(entry.nrId, 'nr-06');
      expect(entry.title, 'NR 06 - EPI');
      expect(entry.portaria, 'Portaria nº 123/2024');
      expect(entry.hash, 'hash_06_v2');
      expect(entry.summary, '2 itens alterados');
      expect(entry.items.length, 2);
      expect(entry.items[0].item, '6.5');
      expect(entry.items[0].tipo, 'novo');
      expect(entry.items[1].tipo, 'alterado');
      expect(entry.createdAt, isNotNull);
    });

    test('UpdateEntry.fromJson com items vazio (schema legado)', () {
      final json = {
        'nr_id': 'nr-10',
        'title': 'NR 10 - Segurança em Eletricidade',
        'hash': 'hash_10',
        'summary': 'Atualizado',
      };

      final entry = UpdateEntry.fromJson(json);

      expect(entry.nrId, 'nr-10');
      expect(entry.items, isEmpty);
      expect(entry.summary, 'Atualizado');
    });

    test('UpdateEntry.fromJson sem items usa lista vazia como fallback', () {
      final json = {
        'nr_id': 'nr-15',
        'title': 'NR 15 - Atividades Insalubres',
        'hash': 'hash_15',
        'summary': 'Revisão completa',
        // items não incluído
      };

      final entry = UpdateEntry.fromJson(json);

      expect(entry.items, isEmpty);
    });

    test('UpdateEntry.fromJson com portaria null', () {
      final json = {
        'nr_id': 'nr-20',
        'title': 'NR 20 - Líquidos Inflamáveis',
        'hash': 'hash_20',
        'summary': 'Alteração menor',
        'portaria': null, // Explicitamente null
      };

      final entry = UpdateEntry.fromJson(json);

      expect(entry.portaria, isNull);
    });

    test('UpdateItem.fromJson com dados válidos', () {
      final json = {
        'item': '6.5',
        'tipo': 'novo',
        'resumo': 'Novo requisito adicionado',
      };

      final item = UpdateItem.fromJson(json);

      expect(item.item, '6.5');
      expect(item.tipo, 'novo');
      expect(item.resumo, 'Novo requisito adicionado');
    });

    test('UpdateItem.fromJson com tipos válidos', () {
      expect(
        UpdateItem.fromJson({
          'item': '6.1',
          'tipo': 'novo',
          'resumo': 'Test',
        }).tipo,
        'novo',
      );

      expect(
        UpdateItem.fromJson({
          'item': '6.2',
          'tipo': 'removido',
          'resumo': 'Test',
        }).tipo,
        'removido',
      );

      expect(
        UpdateItem.fromJson({
          'item': '6.3',
          'tipo': 'alterado',
          'resumo': 'Test',
        }).tipo,
        'alterado',
      );
    });

    test('UpdateEntry toJson/fromJson round-trip preserva dados', () {
      final original = UpdateEntry(
        nrId: 'nr-06',
        title: 'NR 06 - EPI',
        portaria: 'Portaria nº 123/2024',
        hash: 'hash_06',
        pdfHash: 'pdf_hash_06',
        summary: '2 itens',
        items: [
          UpdateItem(
            item: '6.5',
            tipo: 'novo',
            resumo: 'Novo',
          ),
        ],
        createdAt: DateTime(2024, 8, 15),
      );

      final json = original.toJson();
      final restored = UpdateEntry.fromJson(json);

      expect(restored.nrId, original.nrId);
      expect(restored.title, original.title);
      expect(restored.portaria, original.portaria);
      expect(restored.hash, original.hash);
      expect(restored.items.length, original.items.length);
    });

    test('AppMeta.fromJson carrega múltiplas entradas', () {
      final json = {
        'generated_at': '2024-08-15T10:00:00.000Z',
        'min_app_version': '1.2.0',
        'updates': [
          {
            'nr_id': 'nr-06',
            'title': 'NR 06',
            'hash': 'hash_06',
            'summary': 'Atualização 1',
          },
          {
            'nr_id': 'nr-10',
            'title': 'NR 10',
            'hash': 'hash_10',
            'summary': 'Atualização 2',
          },
        ],
      };

      final appMeta = AppMeta.fromJson(json);

      expect(appMeta.updates.length, 2);
      expect(appMeta.updates[0].nrId, 'nr-06');
      expect(appMeta.updates[1].nrId, 'nr-10');
      expect(appMeta.minAppVersion, '1.2.0');
    });

    test('Lógica de busca: última entrada de NR em AppMeta.updates', () {
      // Simular a lógica do ContentService.updateEntryFor()
      final updates = [
        UpdateEntry(
          nrId: 'nr-06',
          title: 'NR 06 v1',
          hash: 'hash_06_v1',
          summary: 'v1',
        ),
        UpdateEntry(
          nrId: 'nr-10',
          title: 'NR 10',
          hash: 'hash_10',
          summary: 'v1',
        ),
        UpdateEntry(
          nrId: 'nr-06',
          title: 'NR 06 v2',
          hash: 'hash_06_v2',
          summary: 'v2',
        ),
      ];

      // Buscar última entrada de nr-06
      UpdateEntry? lastNr06;
      for (var i = updates.length - 1; i >= 0; i--) {
        if (updates[i].nrId == 'nr-06') {
          lastNr06 = updates[i];
          break;
        }
      }

      expect(lastNr06, isNotNull);
      expect(lastNr06!.summary, 'v2'); // Última versão
    });
  });
}
