import 'package:flutter_test/flutter_test.dart';
import 'package:nrfacil/core/utils/display_text_utils.dart';

void main() {
  test('formatNrTitleForDisplay converte CAPS para sentence case', () {
    expect(
      formatNrTitleForDisplay('DISPOSIÇÕES GERAIS E GERENCIAMENTO DE RISCOS'),
      'Disposições gerais e gerenciamento de riscos',
    );
  });

  test('formatNrTitleForDisplay preserva siglas conhecidas', () {
    expect(
      formatNrTitleForDisplay('FORNECIMENTO DE EPI AO TRABALHADOR'),
      'Fornecimento de EPI ao trabalhador',
    );
  });

  test('formatNrTitleForDisplay retorna vazio para string vazia', () {
    expect(formatNrTitleForDisplay(''), '');
    expect(formatNrTitleForDisplay('   '), '');
  });
}
