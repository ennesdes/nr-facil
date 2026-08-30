import 'package:flutter_test/flutter_test.dart';
import 'package:nrfacil/features/reader/utils/markdown_highlight_utils.dart';

void main() {
  group('injectMarkdownHighlights', () {
    test('retorna markdown original sem query', () {
      const markdown = '# **1.1 Objetivo**\nTexto normativo.';
      expect(injectMarkdownHighlights(markdown, null), markdown);
      expect(injectMarkdownHighlights(markdown, ''), markdown);
    });

    test('destaca termo em parágrafo preservando negrito', () {
      const markdown = 'O **objetivo** desta norma é claro.';
      final result = injectMarkdownHighlights(markdown, 'objetivo');

      expect(result, contains('**'));
      expect(result, contains('${searchHighlightOpen}objetivo$searchHighlightClose'));
    });

    test('destaca termo em heading', () {
      const markdown = '# 1.1 Objetivo';
      final result = injectMarkdownHighlights(markdown, 'objetivo');

      expect(result, startsWith('# '));
      expect(result, contains('${searchHighlightOpen}Objetivo$searchHighlightClose'));
    });

    test('destaca termo em célula de tabela', () {
      const markdown = '|Portaria MTP|06/07/78|';
      final result = injectMarkdownHighlights(markdown, 'portaria');

      expect(result, contains('${searchHighlightOpen}Portaria$searchHighlightClose'));
      expect(result.split('|').length, markdown.split('|').length);
    });

    test('busca ignora acentos', () {
      const markdown = 'Campo de aplicação normativa';
      final result = injectMarkdownHighlights(markdown, 'aplicacao');

      expect(result, contains('${searchHighlightOpen}aplicação$searchHighlightClose'));
    });
  });
}
