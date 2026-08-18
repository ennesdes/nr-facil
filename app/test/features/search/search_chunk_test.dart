import 'package:flutter_test/flutter_test.dart';
import 'package:nrfacil/core/models/search_chunk.dart';

void main() {
  group('SearchChunk', () {
    test('fromMap com dados válidos', () {
      final map = {
        'id': 'chunk-0',
        'text': 'Este é um texto de teste',
        'heading': 'Seção 1',
        'char_offset': 100,
      };

      final chunk = SearchChunk.fromMap(map);

      expect(chunk.id, 'chunk-0');
      expect(chunk.text, 'Este é um texto de teste');
      expect(chunk.heading, 'Seção 1');
      expect(chunk.charOffset, 100);
    });

    test('fromMap com dados faltando (fallback para defaults)', () {
      final map = {
        'id': 'chunk-1',
        'text': 'Algum texto',
      };

      final chunk = SearchChunk.fromMap(map);

      expect(chunk.id, 'chunk-1');
      expect(chunk.text, 'Algum texto');
      expect(chunk.heading, '');
      expect(chunk.charOffset, 0);
    });

    test('fromMap com map vazio', () {
      final chunk = SearchChunk.fromMap({});

      expect(chunk.id, '');
      expect(chunk.text, '');
      expect(chunk.heading, '');
      expect(chunk.charOffset, 0);
    });

    test('fromMap com null values', () {
      final map = {
        'id': null,
        'text': null,
        'heading': null,
        'char_offset': null,
      };

      final chunk = SearchChunk.fromMap(map);

      expect(chunk.id, '');
      expect(chunk.text, '');
      expect(chunk.heading, '');
      expect(chunk.charOffset, 0);
    });

    test('toMap preserva valores', () {
      final chunk = SearchChunk(
        id: 'chunk-5',
        text: 'Texto para teste',
        heading: 'Seção 5',
        charOffset: 250,
      );

      final map = chunk.toMap();

      expect(map['id'], 'chunk-5');
      expect(map['text'], 'Texto para teste');
      expect(map['heading'], 'Seção 5');
      expect(map['char_offset'], 250);
    });

    test('toMap/fromMap round-trip', () {
      final original = SearchChunk(
        id: 'chunk-10',
        text: 'Conteúdo de teste com acentuação',
        heading: 'Seção com Acentuação',
        charOffset: 500,
      );

      final map = original.toMap();
      final restored = SearchChunk.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.text, original.text);
      expect(restored.heading, original.heading);
      expect(restored.charOffset, original.charOffset);
    });

    test('fromMap com tipos incorretos (casts defensivos)', () {
      final map = {
        'id': 123, // int em vez de string
        'text': ['lista'], // list em vez de string
        'heading': true, // bool em vez de string
        'char_offset': '250', // string em vez de int
      };

      // Não deve lançar exceção, deve usar defensivos
      expect(
        () => SearchChunk.fromMap(map),
        returnsNormally,
      );
    });
  });
}
