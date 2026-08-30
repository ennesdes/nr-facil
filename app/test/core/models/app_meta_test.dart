import 'package:flutter_test/flutter_test.dart';
import 'package:nrfacil/core/models/app_meta.dart';

void main() {
  group('UpdateItem', () {
    test('fromJson com dados válidos', () {
      final json = {
        'item': '6.5',
        'tipo': 'alterado',
        'resumo': 'Equipamento de proteção contra radiação',
      };

      final item = UpdateItem.fromJson(json);
      expect(item.item, '6.5');
      expect(item.tipo, 'alterado');
      expect(item.resumo, 'Equipamento de proteção contra radiação');
    });

    test('fromJson com dados faltando (fallback)', () {
      final json = {
        'item': '6.21',
        // Faltam tipo e resumo
      };

      final item = UpdateItem.fromJson(json);
      expect(item.item, '6.21');
      expect(item.tipo, 'desconhecido');
      expect(item.resumo, 'Sem detalhes');
    });

    test('fromJson com map vazio', () {
      final json = <String, dynamic>{};

      final item = UpdateItem.fromJson(json);
      expect(item.item, 'desconhecido');
      expect(item.tipo, 'desconhecido');
      expect(item.resumo, 'Sem detalhes');
    });

    test('toJson round-trip preserva todos os campos', () {
      final item = UpdateItem(
        item: '6.5',
        tipo: 'novo',
        resumo: 'Teste resumo',
      );

      final json = item.toJson();
      final restored = UpdateItem.fromJson(json);

      expect(restored.item, item.item);
      expect(restored.tipo, item.tipo);
      expect(restored.resumo, item.resumo);
    });
  });

  group('UpdateEntry', () {
    test('fromJson com dados completos incluindo items', () {
      final json = {
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
            'resumo': 'Antes: …texto antigo…',
          },
          {
            'item': '6.21',
            'tipo': 'novo',
            'resumo': 'Equipamento de proteção contra radiação',
          },
        ],
        'created_at': '2026-08-30T12:00:00+00:00',
      };

      final entry = UpdateEntry.fromJson(json);
      expect(entry.nrId, 'nr-06');
      expect(entry.title, 'EQUIPAMENTO DE PROTEÇÃO INDIVIDUAL - EPI');
      expect(entry.portaria, 'Portaria MTE nº 509/2018');
      expect(entry.hash, 'abc123');
      expect(entry.pdfHash, 'def456');
      expect(entry.summary, '2 itens alterados');
      expect(entry.items.length, 2);
      expect(entry.items[0].item, '6.5');
      expect(entry.items[1].item, '6.21');
      expect(entry.createdAt, isNotNull);
    });

    test('fromJson sem items (schema legado) — items vira lista vazia', () {
      final json = {
        'nr_id': 'nr-06',
        'title': 'EQUIPAMENTO DE PROTEÇÃO INDIVIDUAL - EPI',
        'hash': 'abc123',
        'summary': 'Atualização disponível',
        // Sem items, sem created_at
      };

      final entry = UpdateEntry.fromJson(json);
      expect(entry.nrId, 'nr-06');
      expect(entry.items, isEmpty);
      expect(entry.createdAt, isNull);
    });

    test('fromJson com portaria/pdf_hash nulos', () {
      final json = {
        'nr_id': 'nr-06',
        'title': 'EQUIPAMENTO DE PROTEÇÃO INDIVIDUAL - EPI',
        'hash': 'abc123',
        'summary': 'Atualizado',
        'portaria': null,
        'pdf_hash': null,
      };

      final entry = UpdateEntry.fromJson(json);
      expect(entry.portaria, isNull);
      expect(entry.pdfHash, isNull);
    });

    test('fromJson com map vazio — usa defaults', () {
      final json = <String, dynamic>{};

      final entry = UpdateEntry.fromJson(json);
      expect(entry.nrId, 'unknown');
      expect(entry.title, 'Sem título');
      expect(entry.hash, '');
      expect(entry.items, isEmpty);
    });

    test('toJson round-trip preserva todos os campos', () {
      final entry = UpdateEntry(
        nrId: 'nr-06',
        title: 'EQUIPAMENTO DE PROTEÇÃO INDIVIDUAL - EPI',
        portaria: 'Portaria MTE nº 509/2018',
        hash: 'abc123',
        pdfHash: 'def456',
        summary: '2 itens alterados',
        items: [
          UpdateItem(
            item: '6.5',
            tipo: 'alterado',
            resumo: 'Antes: …texto antigo…',
          ),
        ],
        createdAt: DateTime(2026, 8, 30, 12),
      );

      final json = entry.toJson();
      final restored = UpdateEntry.fromJson(json);

      expect(restored.nrId, entry.nrId);
      expect(restored.title, entry.title);
      expect(restored.portaria, entry.portaria);
      expect(restored.hash, entry.hash);
      expect(restored.pdfHash, entry.pdfHash);
      expect(restored.summary, entry.summary);
      expect(restored.items.length, entry.items.length);
      expect(restored.createdAt?.year, entry.createdAt?.year);
    });
  });

  group('AppMeta', () {
    test('fromJson com dados completos', () {
      final json = {
        'generated_at': '2026-08-30T12:00:00+00:00',
        'min_app_version': '1.0.0',
        'updates': [
          {
            'nr_id': 'nr-06',
            'title': 'EQUIPAMENTO DE PROTEÇÃO INDIVIDUAL - EPI',
            'hash': 'abc123',
            'summary': '2 itens alterados',
            'items': [],
            'created_at': '2026-08-30T12:00:00+00:00',
          },
        ],
      };

      final appMeta = AppMeta.fromJson(json);
      expect(appMeta.generatedAt, isNotNull);
      expect(appMeta.minAppVersion, '1.0.0');
      expect(appMeta.updates.length, 1);
      expect(appMeta.updates[0].nrId, 'nr-06');
    });

    test('fromJson sem generated_at (nullable)', () {
      final json = {
        'min_app_version': '1.0.0',
        'updates': [],
        // Sem generated_at
      };

      final appMeta = AppMeta.fromJson(json);
      expect(appMeta.generatedAt, isNull);
      expect(appMeta.minAppVersion, '1.0.0');
      expect(appMeta.updates, isEmpty);
    });

    test('fromJson com min_app_version ausente — usa default', () {
      final json = {
        'updates': [],
        // Sem min_app_version
      };

      final appMeta = AppMeta.fromJson(json);
      expect(appMeta.minAppVersion, '0.0.0');
    });

    test('fromJson com updates vazio', () {
      final json = {
        'generated_at': '2026-08-30T12:00:00+00:00',
        'min_app_version': '1.0.0',
        'updates': [],
      };

      final appMeta = AppMeta.fromJson(json);
      expect(appMeta.updates, isEmpty);
    });

    test('toJson round-trip preserva todos os campos', () {
      final appMeta = AppMeta(
        generatedAt: DateTime(2026, 8, 30, 12),
        minAppVersion: '1.0.0',
        updates: [
          UpdateEntry(
            nrId: 'nr-06',
            title: 'EQUIPAMENTO DE PROTEÇÃO INDIVIDUAL - EPI',
            hash: 'abc123',
            summary: 'Atualizado',
            items: [],
          ),
        ],
      );

      final json = appMeta.toJson();
      final restored = AppMeta.fromJson(json);

      expect(restored.minAppVersion, appMeta.minAppVersion);
      expect(restored.updates.length, appMeta.updates.length);
      expect(restored.updates[0].nrId, appMeta.updates[0].nrId);
    });

    test('Tolerância a schema legado: entrada sem items', () {
      final json = {
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
    });
  });
}
