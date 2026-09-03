import 'package:flutter_test/flutter_test.dart';
import 'package:nrfacil/features/reader/utils/text_utils.dart';

void main() {
  test('normalizeForSearch remove acentos', () {
    expect(
      normalizeForSearch('Campo de aplicação normativa'),
      contains('aplicacao'),
    );
    expect(normalizeForSearch('aplicacao'), 'aplicacao');
  });

  test('looksLikeMarkdownParagraph detecta headings e listas', () {
    expect(looksLikeMarkdownParagraph('# **SUMÁRIO**'), isTrue);
    expect(looksLikeMarkdownParagraph('- item da lista'), isTrue);
    expect(looksLikeMarkdownParagraph('Texto normativo simples.'), isFalse);
  });

  test('stripHtmlTags remove tags sem afetar negrito', () {
    expect(
      stripHtmlTags('<u>Quadro I</u> com **negrito**'),
      'Quadro I com **negrito**',
    );
  });

  test('findOccurrenceOffsets encontra múltiplas ocorrências', () {
    expect(
      findOccurrenceOffsets('EPI de proteção com EPI adequado', 'EPI'),
      [0, 20],
    );
    expect(findOccurrenceOffsets('sem match aqui', 'xyz'), isEmpty);
  });
}
