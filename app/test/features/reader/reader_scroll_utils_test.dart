import 'package:flutter_test/flutter_test.dart';
import 'package:nrfacil/features/reader/utils/reader_scroll_utils.dart';

void main() {
  group('resolveScrollOffset', () {
    test('mantém posição quando maxExtent não mudou', () {
      expect(
        resolveScrollOffset(
          savedPosition: 800,
          savedMaxExtent: 1000,
          currentMaxExtent: 1000,
        ),
        800,
      );
    });

    test('escala proporcionalmente quando conteúdo cresceu', () {
      expect(
        resolveScrollOffset(
          savedPosition: 800,
          savedMaxExtent: 1000,
          currentMaxExtent: 4000,
        ),
        3200,
      );
    });

    test('retorna savedPosition quando currentMaxExtent é zero', () {
      expect(
        resolveScrollOffset(
          savedPosition: 400,
          savedMaxExtent: 1000,
          currentMaxExtent: 0,
        ),
        400,
      );
    });
  });
}
