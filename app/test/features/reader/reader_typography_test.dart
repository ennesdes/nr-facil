import 'package:flutter_test/flutter_test.dart';
import 'package:nrfacil/features/reader/utils/reader_typography.dart';

void main() {
  test('formatSectionTitle formata número e título', () {
    expect(
      formatSectionTitle('6.1', 'OBJETIVO'),
      '6.1 Objetivo',
    );
    expect(formatSectionTitle('', 'TÍTULO'), 'Título');
    expect(formatSectionTitle('6.2', ''), '6.2');
  });
}
