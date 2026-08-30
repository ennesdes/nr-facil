import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nrfacil/core/models/nr_structure.dart';

void main() {
  group('NrStructure', () {
    test('fromMap parseia seções e blocos tipados', () {
      final json = {
        'title': 'NR 06 - EPI',
        'preamble': {
          'blocks': [
            {'type': 'table', 'markdown': '|A|B|'},
          ],
        },
        'sections': [
          {
            'id': '61-objetivo',
            'number': '6.1',
            'title': 'Objetivo',
            'blocks': [
              {
                'type': 'item',
                'number': '6.1.1',
                'depth': 2,
                'text': 'O objetivo desta NR...',
              },
              {
                'type': 'list',
                'items': [
                  {'label': 'a', 'text': 'primeiro item'},
                ],
              },
            ],
          },
        ],
      };

      final structure = NrStructure.fromMap(json);

      expect(structure.title, 'NR 06 - EPI');
      expect(structure.preamble.blocks, hasLength(1));
      expect(structure.preamble.blocks.first, isA<NrTableBlock>());

      expect(structure.sections, hasLength(1));
      expect(structure.sections.first.displayTitle, '6.1 Objetivo');
      expect(structure.sections.first.blocks[0], isA<NrItemBlock>());
      expect(structure.sections.first.blocks[1], isA<NrListBlock>());
    });

    test('fromMap com JSON real de nr-06 (se existir no repo)', () {
      final file = File(
        '../../content/nr-06/structure.json',
      );
      if (!file.existsSync()) return;

      final map = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final structure = NrStructure.fromMap(map);

      expect(structure.title, contains('NR 06'));
      expect(structure.sections, isNotEmpty);
      expect(structure.sections.first.id, isNotEmpty);
    });
  });
}
