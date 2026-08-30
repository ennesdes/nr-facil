import 'package:flutter_test/flutter_test.dart';
import 'package:nrfacil/core/models/manifest.dart';
import 'package:nrfacil/core/utils/nr_id_utils.dart';

void main() {
  group('nr_id_utils', () {
    test('parseNrNumber extrai número do id', () {
      expect(parseNrNumber('nr-06'), 6);
      expect(parseNrNumber('nr-29'), 29);
    });

    test('formatNrLabel formata id', () {
      expect(formatNrLabel('nr-06'), 'NR-06');
      expect(formatNrLabel('nr-17'), 'NR-17');
    });
  });

  group('ManifestEntry ordenação', () {
    test('compareByNumber ordena por número da NR', () {
      final entries = [
        ManifestEntry(
          id: 'nr-29',
          title: 'B',
          version: '1',
          hash: 'a',
          pdfHash: 'a',
          updatedAt: DateTime.now(),
          url: 'https://example.com',
        ),
        ManifestEntry(
          id: 'nr-01',
          title: 'A',
          version: '1',
          hash: 'a',
          pdfHash: 'a',
          updatedAt: DateTime.now(),
          url: 'https://example.com',
        ),
        ManifestEntry(
          id: 'nr-06',
          title: 'C',
          version: '1',
          hash: 'a',
          pdfHash: 'a',
          updatedAt: DateTime.now(),
          url: 'https://example.com',
        ),
      ];

      entries.sort(ManifestEntry.compareByNumber);

      expect(entries.map((e) => e.id), ['nr-01', 'nr-06', 'nr-29']);
    });
  });
}
