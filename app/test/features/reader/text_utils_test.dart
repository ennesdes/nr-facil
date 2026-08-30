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
}
