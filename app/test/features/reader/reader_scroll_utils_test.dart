import 'package:flutter_test/flutter_test.dart';
import 'package:nrfacil/features/reader/utils/reader_scroll_utils.dart';

void main() {
  group('matchRectInBlock', () {
    test('retorna retângulo no início para match no começo do texto', () {
      final rect = matchRectInBlock(
        maxWidth: 300,
        plainText: 'objetivo da norma',
        matchStart: 0,
        fontSize: 14,
      );

      expect(rect.top, closeTo(0, 1));
      expect(rect.height, 14 * 1.6);
    });

    test('desloca retângulo para baixo em texto multilinha', () {
      final line = 'palavra ' * 20;
      final text = '$line\nobjetivo';
      final rect = matchRectInBlock(
        maxWidth: 120,
        plainText: text,
        matchStart: text.indexOf('objetivo'),
        fontSize: 14,
      );

      expect(rect.top, greaterThan(0));
    });
  });
}
