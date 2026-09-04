import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nrfacil/core/models/manifest.dart';
import 'package:nrfacil/core/models/nr_structure.dart';
import 'package:nrfacil/features/reader/utils/preamble_info_utils.dart';

String _repoRoot() {
  final dir = Directory.current;
  if (dir.path.endsWith('/app')) {
    return dir.parent.path;
  }
  return dir.path;
}

NrPreamble _preambleFromFile(String nrId) {
  final path = '${_repoRoot()}/content/$nrId/structure.json';
  final json = jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
  final preambleMap = json['preamble'] as Map<String, dynamic>? ?? {};
  return NrPreamble.fromMap(preambleMap);
}

void main() {
  group('parsePreambleInfo', () {
    test('nr-06 extrai publicação original e alterações sem sumário', () {
      final info = parsePreambleInfo(_preambleFromFile('nr-06'));

      expect(info.originalPublication, isNotNull);
      expect(
        info.originalPublication!.portaria,
        contains('Portaria MTb'),
      );
      expect(info.originalPublication!.douDate, '06/07/78');
      expect(info.amendments.length, greaterThan(10));
      expect(info.amendments.first.portaria, contains('Portaria'));
      expect(info.redacaoNote, isNotNull);
      expect(info.redacaoNote!.toLowerCase(), contains('redação'));
    });

    test('nr-01 extrai publicação da tabela e alterações', () {
      final info = parsePreambleInfo(_preambleFromFile('nr-01'));

      expect(info.originalPublication, isNotNull);
      expect(info.originalPublication!.portaria, contains('Portaria MTb'));
      expect(info.originalPublication!.douDate, '06/07/78');
      expect(info.amendments.length, greaterThan(5));
    });

    test('nr-05 usa tabela para publicação, não nota de alteração do título', () {
      final info = parsePreambleInfo(_preambleFromFile('nr-05'));

      expect(info.originalPublication, isNotNull);
      expect(info.originalPublication!.portaria, contains('Portaria MTb'));
      expect(info.originalPublication!.portaria, isNot(contains('4.219')));
      expect(info.originalPublication!.portaria, isNot(contains(')_')));
      expect(info.amendments.length, 12);
    });

    test('nr-03 extrai publicação do parágrafo', () {
      final info = parsePreambleInfo(_preambleFromFile('nr-03'));

      expect(info.originalPublication, isNotNull);
      expect(info.originalPublication!.portaria, contains('Portaria MTb'));
      expect(info.amendments.length, 3);
    });

    test('fallback do manifest quando blocos vazios', () {
      final entry = ManifestEntry(
        id: 'nr-99',
        title: 'Teste',
        version: '1',
        hash: 'abc',
        pdfHash: 'def',
        updatedAt: DateTime(2024, 3, 22),
        portaria: 'Portaria MTE nº 342, de 21 de março de 2024',
        publicadoEm: '2024-03-22',
        url: 'https://example.com',
      );

      final info = parsePreambleInfo(
        NrPreamble(blocks: []),
        manifestEntry: entry,
      );

      expect(info.originalPublication, isNotNull);
      expect(info.originalPublication!.portaria, contains('Portaria MTE'));
      expect(info.originalPublication!.douDate, '22/03/24');
    });

    test('parágrafo com sumário não inclui conteúdo do sumário', () {
      final preamble = NrPreamble(
        blocks: [
          const NrParagraphBlock(
            text:
                'Portaria MTb nº 1, de 01 de janeiro de 2000 D.O.U. 02/01/00 '
                '# **SUMÁRIO** 6.1 Objetivo 6.2 Campo',
          ),
        ],
      );

      final info = parsePreambleInfo(preamble);

      expect(info.originalPublication, isNotNull);
      expect(info.originalPublication!.portaria, isNot(contains('Objetivo')));
      expect(info.amendments, isEmpty);
    });
  });

  group('preambleBlockIndexFor', () {
    test('mapeia seções lógicas aos índices originais', () {
      final preamble = _preambleFromFile('nr-06');
      final info = parsePreambleInfo(preamble);

      expect(
        preambleBlockIndexFor(
          preamble: preamble,
          info: info,
          logicalSection: 0,
        ),
        0,
      );
      expect(
        preambleBlockIndexFor(
          preamble: preamble,
          info: info,
          logicalSection: 1,
        ),
        1,
      );
      expect(
        preambleBlockIndexFor(
          preamble: preamble,
          info: info,
          logicalSection: 2,
        ),
        2,
      );
    });
  });
}
