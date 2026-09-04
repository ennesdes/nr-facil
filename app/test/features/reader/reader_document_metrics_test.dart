import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nrfacil/core/models/nr_structure.dart';
import 'package:nrfacil/features/reader/utils/reader_document_metrics.dart';

void main() {
  group('computeReadingProgressPercent (scroll fallback)', () {
    test('não infla progresso quando maxScrollExtent está subestimado', () {
      const estimated = 18586.0;
      const pixels = 15758.0;
      const underestimatedExtent = 17000.0;

      final naive = ((pixels / underestimatedExtent) * 100).round();
      final stable = computeReadingProgressPercent(
        scrollPixels: pixels,
        maxScrollExtent: underestimatedExtent,
        estimatedDocumentHeight: estimated,
      );

      expect(naive, greaterThan(90));
      expect(stable, lessThan(90));
      expect(stable, 85);
    });

    test('retorna 100 no final do scroll', () {
      expect(
        computeReadingProgressPercent(
          scrollPixels: 18580,
          maxScrollExtent: 18586,
          estimatedDocumentHeight: 18586,
        ),
        100,
      );
    });
  });

  group('computeStructureReadingProgressPercent', () {
    late NrStructure nr05;

    setUpAll(() {
      final repoRoot = Directory.current.path.endsWith('/app')
          ? Directory.current.parent
          : Directory.current;
      final file = File('${repoRoot.path}/content/nr-05/structure.json');
      nr05 = NrStructure.fromMap(
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
      );
    });

    test('item 5.9.3 fica abaixo de 80%', () {
      final percent = computeStructureReadingProgressPercent(
        structure: nr05,
        sectionId: '59-disposições-finais',
        blockIndex: 2,
        scrollPixels: 0,
        maxScrollExtent: 17000,
      );

      expect(percent, lessThan(80));
      expect(percent, greaterThan(70));
    });

    test('imagem do Quadro I tem progresso próximo ao item 5.9.3', () {
      final atItem = computeStructureReadingProgressPercent(
        structure: nr05,
        sectionId: '59-disposições-finais',
        blockIndex: 2,
        scrollPixels: 0,
        maxScrollExtent: 17000,
      );
      final atImage = computeStructureReadingProgressPercent(
        structure: nr05,
        sectionId: '59-disposições-finais',
        blockIndex: 5,
        scrollPixels: 0,
        maxScrollExtent: 17000,
      );

      expect(atImage - atItem, lessThanOrEqualTo(2));
      expect(atImage, lessThan(80));
    });

    test('Anexo I seção 1 Objetivo fica acima do Quadro I', () {
      final atImage = computeStructureReadingProgressPercent(
        structure: nr05,
        sectionId: '59-disposições-finais',
        blockIndex: 5,
        scrollPixels: 0,
        maxScrollExtent: 17000,
      );
      final atAnnex = computeStructureReadingProgressPercent(
        structure: nr05,
        sectionId: '1-objetivo',
        blockIndex: 0,
        scrollPixels: 0,
        maxScrollExtent: 17000,
      );

      expect(atAnnex, greaterThan(atImage));
      expect(atAnnex, lessThan(85));
    });

    test('retorna 100 no final do scroll', () {
      expect(
        computeStructureReadingProgressPercent(
          structure: nr05,
          sectionId: '3-disposições-gerais',
          blockIndex: 0,
          scrollPixels: 25000,
          maxScrollExtent: 25000,
        ),
        100,
      );
    });
  });
}
