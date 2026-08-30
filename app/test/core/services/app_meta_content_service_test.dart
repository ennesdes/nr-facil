import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nrfacil/core/models/app_meta.dart';
import 'package:nrfacil/core/services/content_service.dart';

void main() {
  group('ContentService - AppMeta', () {
    late ContentService contentService;

    setUp(() {
      // Inicializar GetX
      Get.testMode = true;
      contentService = ContentService();
    });

    tearDown(() {
      Get.reset();
    });

    test('fromJson caminho feliz: app_meta com items[] é parseado corretamente',
        () {
      final json = {
        'generated_at': '2026-08-30T12:00:00+00:00',
        'min_app_version': '1.0.0',
        'updates': [
          {
            'nr_id': 'nr-06',
            'title': 'EQUIPAMENTO DE PROTEÇÃO INDIVIDUAL - EPI',
            'portaria': 'Portaria MTE nº 509/2018',
            'hash': 'abc123',
            'pdf_hash': 'def456',
            'summary': '2 itens alterados',
            'items': [
              {
                'item': '6.5',
                'tipo': 'alterado',
                'resumo': 'Antes: …texto antigo… → depois: …texto novo…'
              },
              {
                'item': '6.21',
                'tipo': 'novo',
                'resumo': 'Equipamento de proteção contra radiação'
              },
            ],
            'created_at': '2026-08-30T12:00:00+00:00',
          },
        ],
      };

      final appMeta = AppMeta.fromJson(json);

      expect(appMeta.minAppVersion, '1.0.0');
      expect(appMeta.updates.length, 1);

      final entry = appMeta.updates[0];
      expect(entry.nrId, 'nr-06');
      expect(entry.title, 'EQUIPAMENTO DE PROTEÇÃO INDIVIDUAL - EPI');
      expect(entry.portaria, 'Portaria MTE nº 509/2018');
      expect(entry.summary, '2 itens alterados');
      expect(entry.items.length, 2);
      expect(entry.items[0].tipo, 'alterado');
      expect(entry.items[1].tipo, 'novo');
    });

    test('Edge case: entrada sem items (schema legado) não quebra', () {
      final json = {
        'generated_at': '2026-08-30T12:00:00+00:00',
        'min_app_version': '1.0.0',
        'updates': [
          {
            'nr_id': 'nr-06',
            'title': 'EQUIPAMENTO DE PROTEÇÃO INDIVIDUAL - EPI',
            'hash': 'abc123',
            'summary': 'Atualizado',
            // Sem items (schema legado)
          },
        ],
      };

      final appMeta = AppMeta.fromJson(json);

      expect(appMeta.updates[0].items, isEmpty);
      expect(appMeta.updates[0].nrId, 'nr-06');
    });

    test('ContentService.updateEntryFor: busca entrada correta da NR', () {
      final appMeta = AppMeta(
        generatedAt: DateTime.now(),
        minAppVersion: '1.0.0',
        updates: [
          UpdateEntry(
            nrId: 'nr-06',
            title: 'EQUIPAMENTO DE PROTEÇÃO INDIVIDUAL - EPI',
            hash: 'abc123',
            summary: '2 itens alterados',
            items: [
              UpdateItem(
                item: '6.5',
                tipo: 'alterado',
                resumo: 'Alterado',
              ),
            ],
            createdAt: DateTime(2026, 8, 30, 12),
          ),
          UpdateEntry(
            nrId: 'nr-10',
            title: 'SEGURANÇA EM MÁQUINAS',
            hash: 'def456',
            summary: '1 item novo',
            items: [],
            createdAt: DateTime(2026, 8, 31, 10),
          ),
        ],
      );

      contentService.appMeta.value = appMeta;

      final entry06 = contentService.updateEntryFor('nr-06');
      expect(entry06, isNotNull);
      expect(entry06!.nrId, 'nr-06');
      expect(entry06.items.length, 1);

      final entry10 = contentService.updateEntryFor('nr-10');
      expect(entry10, isNotNull);
      expect(entry10!.nrId, 'nr-10');

      final entryNotFound = contentService.updateEntryFor('nr-99');
      expect(entryNotFound, isNull);
    });

    test('ContentService.updateEntryFor: retorna null se appMeta não foi baixado',
        () {
      contentService.appMeta.value = null;

      final entry = contentService.updateEntryFor('nr-06');
      expect(entry, isNull);
    });

    test(
        'ContentService.updateEntryFor: ordena por createdAt e retorna a mais recente',
        () {
      final appMeta = AppMeta(
        generatedAt: DateTime.now(),
        minAppVersion: '1.0.0',
        updates: [
          UpdateEntry(
            nrId: 'nr-06',
            title: 'NR-06 v1',
            hash: 'hash1',
            summary: 'Versão 1',
            items: [],
            createdAt: DateTime(2026, 8, 29), // Mais antiga
          ),
          UpdateEntry(
            nrId: 'nr-06',
            title: 'NR-06 v2',
            hash: 'hash2',
            summary: 'Versão 2',
            items: [],
            createdAt: DateTime(2026, 8, 30), // Mais recente
          ),
        ],
      );

      contentService.appMeta.value = appMeta;

      final entry = contentService.updateEntryFor('nr-06');
      expect(entry, isNotNull);
      expect(entry!.summary, 'Versão 2'); // Deve retornar a mais recente
    });
  });
}
