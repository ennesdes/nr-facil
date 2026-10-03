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

    test('fromMap desduplica ids de seção repetidos (anexos)', () {
      final structure = NrStructure.fromMap({
        'sections': [
          {'id': '1-objetivo', 'title': 'Anexo I'},
          {'id': '1-objetivo-2', 'title': 'Id real que colide com o sufixo'},
          {'id': '1-objetivo', 'title': 'Anexo II'},
          {'id': '1-objetivo', 'title': 'Anexo III'},
          {'title': 'Sem id'},
          {'title': 'Sem id'},
        ],
      });

      final ids = structure.sections.map((s) => s.id).toList();
      expect(ids, [
        '1-objetivo',
        '1-objetivo-2',
        '1-objetivo-3',
        '1-objetivo-4',
        '',
        '-2',
      ]);
      expect(ids.toSet(), hasLength(ids.length));
      expect(structure.sections[2].title, 'Anexo II');
    });

    test('ids de seção são únicos em todo o conteúdo real', () {
      final dir = Directory('../content');
      if (!dir.existsSync()) return;

      for (final file in dir
          .listSync()
          .whereType<Directory>()
          .map((d) => File('${d.path}/structure.json'))
          .where((f) => f.existsSync())) {
        final map = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        final ids = NrStructure.fromMap(map).sections.map((s) => s.id);
        expect(ids.toSet(), hasLength(ids.length), reason: file.path);
      }
    });

    test('fromMap com JSON real de nr-06 (se existir no repo)', () {
      final file = File('../../content/nr-06/structure.json');
      if (!file.existsSync()) return;

      final map = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final structure = NrStructure.fromMap(map);

      expect(structure.title, contains('NR 06'));
      expect(structure.sections, isNotEmpty);
      expect(structure.sections.first.id, isNotEmpty);
    });
  });
}
