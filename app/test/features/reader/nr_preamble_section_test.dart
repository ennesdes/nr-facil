import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nrfacil/core/models/nr_structure.dart';
import 'package:nrfacil/core/theme/app_theme.dart';
import 'package:nrfacil/features/reader/utils/preamble_info_utils.dart';
import 'package:nrfacil/features/reader/views/widgets/nr_preamble_section.dart';

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
  testWidgets('NrPreambleSection inicia colapsado', (tester) async {
    final preamble = NrPreamble(
      blocks: [
        const NrParagraphBlock(
          text:
              'Portaria MTb nº 3.214, de 08 de junho de 1978 D.O.U. 06/07/78',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: NrPreambleSection(
            preamble: preamble,
            nrEntry: null,
            fontSize: 14,
            nrId: 'nr-06',
            isExpanded: false,
            blockKeyFor: (_, _) => GlobalKey(),
          ),
        ),
      ),
    );

    expect(find.text('Publicação e histórico'), findsOneWidget);
    expect(find.text('Publicação original'), findsNothing);

    await tester.tap(find.text('Publicação e histórico'));
    await tester.pumpAndSettle();

    expect(find.text('Publicação original'), findsOneWidget);
    expect(find.textContaining('Portaria MTb'), findsOneWidget);
  });

  testWidgets('não exibe sumário do preâmbulo', (tester) async {
    final preamble = NrPreamble(
      blocks: [
        const NrParagraphBlock(
          text:
              'Portaria MTb nº 1, de 01 de janeiro de 2000 D.O.U. 02/01/00',
        ),
        NrTableBlock(
          markdown: '| Alterações | D.O.U. |\n| --- | --- |\n'
              '| Portaria SSMT nº 2, de 01 de fevereiro de 2001 | 02/02/01 |',
        ),
        const NrParagraphBlock(
          text: '# **SUMÁRIO** 6.1 Objetivo 6.2 Campo de aplicação',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: NrPreambleSection(
            preamble: preamble,
            nrEntry: null,
            fontSize: 14,
            nrId: 'nr-06',
            isExpanded: true,
            blockKeyFor: (_, _) => GlobalKey(),
          ),
        ),
      ),
    );

    expect(find.text('SUMÁRIO'), findsNothing);
    expect(find.textContaining('Objetivo'), findsNothing);
    expect(find.textContaining('Campo de aplicação'), findsNothing);
    expect(find.text('Última alteração'), findsOneWidget);
  });

  testWidgets('nr-06 prioriza última alteração no subtítulo', (tester) async {
    final preamble = _preambleFromFile('nr-06');
    final info = parsePreambleInfo(preamble);
    final latest = info.latestAmendment!;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: NrPreambleSection(
            preamble: preamble,
            nrEntry: null,
            fontSize: 14,
            nrId: 'nr-06',
            isExpanded: false,
            blockKeyFor: (_, _) => GlobalKey(),
          ),
        ),
      ),
    );

    expect(
      find.text(
        'Última alteração em ${latest.douDate} · ${info.amendments.length} no total',
      ),
      findsOneWidget,
    );
  });

  testWidgets('nr-06 expandido mostra última alteração e publicação original', (tester) async {
    final preamble = _preambleFromFile('nr-06');
    final info = parsePreambleInfo(preamble);
    final latest = info.latestAmendment!;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: NrPreambleSection(
              preamble: preamble,
              nrEntry: null,
              fontSize: 14,
              nrId: 'nr-06',
              isExpanded: true,
              blockKeyFor: (_, _) => GlobalKey(),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Última alteração'), findsOneWidget);
    expect(find.text('Publicação original'), findsOneWidget);
    expect(find.textContaining('D.O.U. ${latest.douDate}'), findsOneWidget);
    expect(find.textContaining('D.O.U. 06/07/78'), findsOneWidget);
    expect(
      find.textContaining('Portaria MTb nº 3.214'),
      findsOneWidget,
    );
    expect(find.textContaining(latest.portaria), findsOneWidget);
  });
}
