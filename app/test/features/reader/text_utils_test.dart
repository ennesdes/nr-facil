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

  test('parseInlineMarkdownSegments interpreta negrito e notas', () {
    final segments = parseInlineMarkdownSegments(
      '**28.1** Texto _(nota)_ com **fiscal**ização',
    );

    expect(segments.length, 4);
    expect(segments[0].text, '28.1');
    expect(segments[0].isBold, isTrue);
    expect(segments[1].text, ' Texto nota com ');
    expect(segments[2].text, 'fiscal');
    expect(segments[2].isBold, isTrue);
    expect(segments[3].text, 'ização');
  });

  test('extractMarkdownSnippet preserva negrito no trecho', () {
    final snippet = extractMarkdownSnippet(
      'Introdução longa. **28.1** fiscalização da NR e mais texto normativo.',
      query: 'fiscal',
      context: 10,
    );

    expect(snippet, contains('**28.1**'));
    expect(snippet, isNot(contains('**fiscal**')));
    expect(stripInlineMarkup(snippet).toLowerCase(), contains('fiscal'));
  });
}
