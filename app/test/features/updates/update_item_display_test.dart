import 'package:flutter_test/flutter_test.dart';
import 'package:nrfacil/core/models/app_meta.dart';
import 'package:nrfacil/features/updates/utils/update_item_display.dart';

void main() {
  group('UpdateItemDisplay', () {
    test('alterado exibe parágrafo integral em antes/depois', () {
      final display = UpdateItemDisplay.fromUpdateItem(
        UpdateItem(
          item: '5.7.2',
          tipo: 'alterado',
          resumo: '',
          antes: 'O empregador deve garantir a implementação de medidas de proteção coletiva, de caráter administrativo ou de organização do # trabalho.',
          depois: 'O empregador deve garantir a implementação de medidas de proteção coletiva, de caráter administrativo ou de organização do trabalho.',
        ),
      );

      expect(display.antes, hasLength(1));
      expect(display.depois, hasLength(1));
      expect(display.antes.first, contains('# trabalho'));
      expect(display.depois.first, isNot(contains('# trabalho')));
      expect(display.antes.first, contains('proteção coletiva'));
    });

    test('alterado legado parseia resumo combinado como bloco único', () {
      final display = UpdateItemDisplay.fromUpdateItem(
        UpdateItem(
          item: '33.6.5',
          tipo: 'alterado',
          resumo: 'antes: …1331400… → depois: …133140- 0…',
        ),
      );

      expect(display.antes.single, '1331400');
      expect(display.depois.single, '133140- 0');
    });

    test('novo mantém texto integral', () {
      final display = UpdateItemDisplay.fromUpdateItem(
        UpdateItem(
          item: '6.21',
          tipo: 'novo',
          resumo: 'Equipamento de proteção contra radiação ionizante.',
        ),
      );

      expect(display.conteudo.single, contains('radiação ionizante'));
    });

    test('fullTextBullets não divide por pipe', () {
      expect(fullTextBullets('Coluna A | Coluna B | Coluna C'), [
        'Coluna A | Coluna B | Coluna C',
      ]);
    });
  });
}
