import 'package:flutter_test/flutter_test.dart';
import 'package:nrfacil/core/models/reading_history_entry.dart';
import 'package:nrfacil/features/reader/utils/reader_scroll_restore.dart';

void main() {
  group('effectiveScrollRatioFromEntry', () {
    test('prioriza scrollRatio salvo', () {
      expect(
        effectiveScrollRatioFromEntry(scrollRatio: 0.87),
        0.87,
      );
    });

    test('calcula a partir de posição e extent', () {
      expect(
        effectiveScrollRatioFromEntry(
          scrollPosition: 800,
          scrollMaxExtent: 1000,
        ),
        0.8,
      );
    });

    test('ignora progressPercent isolado', () {
      expect(effectiveScrollRatioFromEntry(), 0);
    });
  });

  group('isScrollRatioRestoreComplete', () {
    test('exige extent estável e offset próximo do alvo', () {
      expect(
        isScrollRatioRestoreComplete(
          pixels: 830,
          maxScrollExtent: 1000,
          ratio: 0.83,
          stableExtentFrames: 2,
        ),
        isTrue,
      );
      expect(
        isScrollRatioRestoreComplete(
          pixels: 830,
          maxScrollExtent: 1000,
          ratio: 0.83,
          stableExtentFrames: 1,
        ),
        isFalse,
      );
    });
  });

  group('ReadingHistoryEntry.effectiveScrollRatio', () {
    test('expõe razão efetiva no modelo', () {
      final entry = ReadingHistoryEntry(
        nrId: 'nr-06',
        lastAccessedAt: DateTime(2026),
        scrollRatio: 0.75,
      );
      expect(entry.effectiveScrollRatio, 0.75);
      expect(entry.hasSavedReadingPosition, isTrue);
    });

    test('reconhece âncoras estruturais sem scrollRatio', () {
      final entry = ReadingHistoryEntry(
        nrId: 'nr-06',
        lastAccessedAt: DateTime(2026),
        lastSectionId: 'sec-25',
        lastBlockIndex: 1,
        progressPercent: 87,
      );
      expect(entry.effectiveScrollRatio, 0);
      expect(entry.hasSavedReadingPosition, isTrue);
    });
  });
}
