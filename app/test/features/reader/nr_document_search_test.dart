import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nrfacil/core/models/nr_structure.dart';
import 'package:nrfacil/features/reader/utils/nr_document_search.dart';

void main() {
  group('searchInNrDocument', () {
    final structure = NrStructure(
      title: 'NR 06 - EQUIPAMENTOS DE PROTEÇÃO INDIVIDUAL',
      preamble: NrPreamble(blocks: []),
      sections: [
        NrSection(
          id: '61-objetivo',
          number: '6.1',
          title: 'Objetivo',
          blocks: [
            const NrItemBlock(
              number: '6.1.1',
              depth: 2,
              text: 'fornecer EPI gratuitamente ao trabalhador',
            ),
          ],
        ),
        NrSection(
          id: '65-responsabilidades',
          number: '6.5',
          title: 'Responsabilidades da organização',
          blocks: [],
        ),
      ],
    );

    test('encontra texto em bloco', () {
      final results = searchInNrDocument(structure, 'EPI');
      expect(results, hasLength(1));
      expect(results.first.sectionId, '61-objetivo');
      expect(results.first.blockIndex, 0);
      expect(results.first.matchStart, greaterThanOrEqualTo(0));
    });

    test('conta cada ocorrência no mesmo bloco', () {
      final withRepeats = NrStructure(
        title: 'NR 06',
        preamble: NrPreamble(blocks: []),
        sections: [
          NrSection(
            id: '61-epi',
            number: '6.1',
            title: 'EPI',
            blocks: [
              const NrItemBlock(
                number: '6.1.1',
                depth: 2,
                text: 'fornecer EPI e substituir EPI danificado',
              ),
            ],
          ),
        ],
      );

      final results = searchInNrDocument(withRepeats, 'EPI');
      expect(results, hasLength(3));
      expect(results.where((h) => h.blockIndex == -1), hasLength(1));
      expect(results.where((h) => h.blockIndex == 0), hasLength(2));
    });

    test('encontra título de seção no índice', () {
      final results = searchInNrDocument(structure, 'objetivo');
      expect(results.any((h) => h.blockIndex == -1), isTrue);
      expect(
        results.any((h) => h.label.contains('Objetivo')),
        isTrue,
      );
    });

    test('encontra seção pelo número', () {
      final results = searchInNrDocument(structure, '6.5');
      expect(results.any((h) => h.sectionId == '65-responsabilidades'), isTrue);
    });

    test('encontra título da NR', () {
      final results = searchInNrDocument(structure, 'equipamentos');
      expect(results.any((h) => h.sectionId == 'meta'), isTrue);
    });

    test('encontra texto sem acento quando original tem acento', () {
      final withAccent = NrStructure(
        title: 'NR 06',
        preamble: NrPreamble(blocks: []),
        sections: [
          NrSection(
            id: '61-aplicacao',
            number: '6.1',
            title: 'Aplicação',
            blocks: [
              const NrItemBlock(
                number: '6.1.1',
                depth: 2,
                text: 'Campo de aplicação normativa',
              ),
            ],
          ),
        ],
      );
      final results = searchInNrDocument(withAccent, 'aplicacao');
      expect(results, isNotEmpty);
    });

    test('encontra SESMT na NR-05 (structure.json real)', () {
      final file = File('../content/nr-05/structure.json');
      if (!file.existsSync()) return;

      final structure = NrStructure.fromMap(
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
      );
      final results = searchInNrDocument(structure, 'sesmt');
      expect(results, isNotEmpty);
    });

    test('encontra SESMT no markdown da NR-05', () {
      final structureFile = File('../content/nr-05/structure.json');
      final mdFile = File('../content/nr-05/nr-05.md');
      if (!mdFile.existsSync()) return;

      NrStructure? structure;
      if (structureFile.existsSync()) {
        structure = NrStructure.fromMap(
          jsonDecode(structureFile.readAsStringSync()) as Map<String, dynamic>,
        );
      }

      final results = searchInMarkdownContent(
        mdFile.readAsStringSync(),
        structure,
        'SESMT',
      );
      expect(results, isNotEmpty);
    });
  });
}
