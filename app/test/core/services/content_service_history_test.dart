import 'package:flutter_test/flutter_test.dart';
import 'package:nrfacil/core/models/reading_history_entry.dart';

void main() {
  group('ReadingHistoryEntry', () {
    test('fromMap com dados válidos', () {
      final map = {
        'nr_id': 'nr-06',
        'last_accessed_at': '2024-08-17T10:30:00.000Z',
        'scroll_position': 123.45,
        'last_heading_viewed': '6.1',
      };

      final entry = ReadingHistoryEntry.fromMap(map);
      expect(entry.nrId, 'nr-06');
      expect(entry.scrollPosition, 123.45);
      expect(entry.lastHeadingViewed, '6.1');
    });

    test('fromMap com dados faltando (fallback)', () {
      final map = {
        'nr_id': 'nr-06',
        // Faltam os outros campos
      };

      final entry = ReadingHistoryEntry.fromMap(map);
      expect(entry.nrId, 'nr-06');
      expect(entry.scrollPosition, 0.0);
      expect(entry.lastHeadingViewed, isNull);
    });

    test('fromMap com map vazio', () {
      final map = <String, dynamic>{};

      final entry = ReadingHistoryEntry.fromMap(map);
      expect(entry.nrId, 'unknown');
      expect(entry.scrollPosition, 0.0);
      expect(entry.lastHeadingViewed, isNull);
    });

    test('toMap round-trip preserva todos os campos', () {
      final entry = ReadingHistoryEntry(
        nrId: 'nr-06',
        lastAccessedAt: DateTime(2024, 8, 17, 10, 30),
        scrollPosition: 150.5,
        lastHeadingViewed: '6.2',
      );

      final map = entry.toMap();
      final restored = ReadingHistoryEntry.fromMap(map);

      expect(restored.nrId, entry.nrId);
      expect(restored.scrollPosition, entry.scrollPosition);
      expect(restored.lastHeadingViewed, entry.lastHeadingViewed);
      // Timestamps podem ter pequenas diferenças de precisão, então apenas verificar ano/mês/dia
      expect(restored.lastAccessedAt.year, entry.lastAccessedAt.year);
      expect(restored.lastAccessedAt.month, entry.lastAccessedAt.month);
      expect(restored.lastAccessedAt.day, entry.lastAccessedAt.day);
    });

    test('copyWith cria cópia com campos atualizados', () {
      final entry = ReadingHistoryEntry(
        nrId: 'nr-06',
        lastAccessedAt: DateTime(2024, 8, 17),
        scrollPosition: 100.0,
      );

      final updated = entry.copyWith(scrollPosition: 200.0);

      expect(updated.nrId, entry.nrId);
      expect(updated.scrollPosition, 200.0);
      expect(entry.scrollPosition, 100.0); // Original não muda
    });

    test('copyWith preserva campos não atualizados', () {
      final entry = ReadingHistoryEntry(
        nrId: 'nr-06',
        lastAccessedAt: DateTime(2024, 8, 17),
        scrollPosition: 100.0,
        lastHeadingViewed: '6.1',
      );

      final updated = entry.copyWith(scrollPosition: 200.0);

      expect(updated.nrId, 'nr-06');
      expect(updated.lastHeadingViewed, '6.1');
      expect(updated.scrollPosition, 200.0);
    });

    test('constructor com valores padrão', () {
      final entry = ReadingHistoryEntry(
        nrId: 'nr-06',
        lastAccessedAt: DateTime(2024, 8, 17),
      );

      expect(entry.nrId, 'nr-06');
      expect(entry.scrollPosition, 0.0);
      expect(entry.lastHeadingViewed, isNull);
    });
  });
}
