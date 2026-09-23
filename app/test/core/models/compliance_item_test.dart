import 'package:flutter_test/flutter_test.dart';
import 'package:nrfacil/core/models/compliance_item.dart';

void main() {
  test('toShareText inclui código NR-28 e título', () {
    final item = ComplianceItem(
      nrId: 'nr-05',
      itemNumber: '5.2.1',
      titulo: 'Constituir a CIPA',
      infracao: true,
      gradacao: 'I4',
      tipo: 'S',
      codigoInfracao: '205113-3',
      explicacao: 'Texto explicativo.',
      responsavel: 'Empregador / RH',
      riskFactors: ['empregados_clt'],
      readerAnchorId: 'anchor',
    );

    final text = item.toShareText();
    expect(text, contains('NR-05'));
    expect(text, contains('Constituir a CIPA'));
    expect(text, contains('205113-3'));
    expect(text, contains('NR-28'));
  });
}
