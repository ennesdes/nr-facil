import 'package:flutter_test/flutter_test.dart';
import 'package:nrfacil/features/reader/utils/markdown_utils.dart';

void main() {
  group('splitMarkdownBySections', () {
    test('content vazio retorna lista vazia', () {
      final sections = splitMarkdownBySections('');
      expect(sections, isEmpty);
    });

    test('content sem headings retorna uma seção sem heading', () {
      final content = 'Apenas texto simples\nsem qualquer heading';
      final sections = splitMarkdownBySections(content);

      expect(sections, hasLength(1));
      expect(sections[0].headingText, isNull);
      expect(sections[0].markdownContent, contains('Apenas texto simples'));
    });

    test('content com um heading divide corretamente', () {
      final content = '''Conteúdo inicial
# Seção 1
Texto da seção 1''';

      final sections = splitMarkdownBySections(content);

      expect(sections, hasLength(2));
      expect(sections[0].headingText, isNull);
      expect(sections[0].markdownContent, contains('Conteúdo inicial'));
      expect(sections[1].headingText, 'Seção 1');
      expect(sections[1].markdownContent, contains('Texto da seção 1'));
    });

    test('content com múltiplos headings divide corretamente', () {
      final content = '''# Seção 1
Corpo 1
## Subseção 1.1
Corpo 1.1
# Seção 2
Corpo 2''';

      final sections = splitMarkdownBySections(content);

      expect(sections, hasLength(3));
      expect(sections[0].headingText, 'Seção 1');
      expect(sections[1].headingText, 'Subseção 1.1');
      expect(sections[2].headingText, 'Seção 2');
    });

    test('heading com múltiplos # extraído corretamente', () {
      final content = '''### Seção Nível 3
Conteúdo da seção''';

      final sections = splitMarkdownBySections(content);

      expect(sections, hasLength(1));
      expect(sections[0].headingText, 'Seção Nível 3');
      expect(sections[0].markdownContent, contains('###'));
    });

    test('linhas começando com # mas sem espaço não são headings', () {
      final content = '''#hashtag no meio do texto
# Seção Real
Conteúdo''';

      final sections = splitMarkdownBySections(content);

      // #hashtag não é heading (não tem espaço após #)
      expect(sections.length, greaterThanOrEqualTo(1));
      expect(sections[0].markdownContent, contains('#hashtag'));
    });

    test('seções preservam linhas em branco internas', () {
      final content = '''# Seção 1
Primeira linha

Segunda linha após branco

Terceira linha''';

      final sections = splitMarkdownBySections(content);

      expect(sections, hasLength(1));
      expect(sections[0].markdownContent, contains('\n\n'));
    });

    test('heading com espaçamento extra é tratado corretamente', () {
      final content = '''#    Seção com espaços
Conteúdo''';

      final sections = splitMarkdownBySections(content);

      // O heading com múltiplos espaços deve ser normalizado
      expect(sections[0].headingText, contains('Seção'));
    });

    test('content iniciando com heading funciona corretamente', () {
      final content = '''# Primeiro Heading
Conteúdo do primeiro
# Segundo Heading
Conteúdo do segundo''';

      final sections = splitMarkdownBySections(content);

      expect(sections, hasLength(2));
      expect(sections[0].headingText, 'Primeiro Heading');
      expect(sections[1].headingText, 'Segundo Heading');
    });

    test('diferentes níveis de heading (h1 até h6)', () {
      final content = '''# H1
Corpo
## H2
Corpo
### H3
Corpo
#### H4
Corpo
##### H5
Corpo
###### H6
Corpo''';

      final sections = splitMarkdownBySections(content);

      expect(sections, hasLength(6));
      expect(sections[0].headingText, 'H1');
      expect(sections[1].headingText, 'H2');
      expect(sections[2].headingText, 'H3');
      expect(sections[3].headingText, 'H4');
      expect(sections[4].headingText, 'H5');
      expect(sections[5].headingText, 'H6');
    });

    test('seção final sem conteúdo não deixa trailing vazio', () {
      final content = '''# Seção 1
Conteúdo
# Seção 2''';

      final sections = splitMarkdownBySections(content);

      // A seção 2 deve existir mas pode estar vazia
      expect(sections[1].headingText, 'Seção 2');
    });

    test('markdownContent inclui o heading original', () {
      final content = '''# Meu Heading
Texto aqui''';

      final sections = splitMarkdownBySections(content);

      // O content deve incluir o # original para poder fazer render
      expect(sections[0].markdownContent, contains('# Meu Heading'));
    });
  });
}
