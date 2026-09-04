import 'package:flutter_test/flutter_test.dart';
import 'package:nrfacil/features/reader/utils/item_citation_utils.dart';

void main() {
  test('formatItemCitation inclui NR, item e fonte', () {
    final citation = formatItemCitation(
      nrId: 'nr-06',
      itemNumber: '6.5.1',
      text: 'O empregador deve fornecer EPI.',
    );

    expect(citation, contains('NR-06 — Item 6.5.1'));
    expect(citation, contains('O empregador deve fornecer EPI.'));
    expect(citation, contains('Fonte: NR-06'));
  });
}
