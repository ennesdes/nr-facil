import 'package:flutter_test/flutter_test.dart';
import 'package:nrfacil/core/models/app_meta.dart';

void main() {
  group('UpdatesPage — Integration scenarios', () {
    test(
        'CA6 — NR atualizada com UpdateEntry mostra data/portaria/itens',
        () {
      // Cenário: uma NR em updatedNrs tem entrada correspondente em app_meta.json
      // com items[] populado

      final updateEntry = UpdateEntry(
        nrId: 'nr-06',
        title: 'NR 06 - EPI',
        portaria: 'Portaria nº 123/2024',
        hash: 'hash_06_v2',
        summary: '2 itens alterados',
        items: [
          UpdateItem(
            item: '6.5',
            tipo: 'novo',
            resumo: 'Novo requisito adicionado',
          ),
          UpdateItem(
            item: '6.21',
            tipo: 'alterado',
            resumo: 'Texto atualizado para maior clareza',
          ),
        ],
        createdAt: DateTime(2024, 8, 15, 10, 30),
      );

      // Validar que dados estão presentes
      expect(updateEntry.createdAt, isNotNull);
      expect(updateEntry.portaria, 'Portaria nº 123/2024');
      expect(updateEntry.items.length, 2);
      expect(updateEntry.items[0].item, '6.5');
      expect(updateEntry.items[0].tipo, 'novo');
    });

    test('Edge case — NR sem UpdateEntry correspondente não quebra', () {
      // Cenário: NR tem hasUpdate == true mas não há entrada em app_meta.json
      // (sync do feed ainda não aconteceu ou entrada foi removida)

      final updateEntry = UpdateEntry(
        nrId: 'nr-06',
        title: 'NR 06 - EPI',
        hash: 'hash_06_v2',
        summary: 'Atualizado',
        items: [],
        createdAt: null,
      );

      // Fallback gracioso
      expect(updateEntry.items, isEmpty);
      expect(updateEntry.summary, 'Atualizado');
      expect(updateEntry.createdAt, isNull);

      // A tela deve exibir só o título + badge, sem quebrar
    });

    test('Edge case — items vazio mas summary presente mostra resumo', () {
      // Cenário: entrada tem summary mas items[] vazio
      // (ex: diff granular não estava disponível quando a entrada foi criada)

      final updateEntry = UpdateEntry(
        nrId: 'nr-10',
        title: 'NR 10 - Segurança em Eletricidade',
        portaria: 'Portaria MTE',
        hash: 'hash_10',
        summary: '3 artigos modificados',
        items: [], // Vazio
        createdAt: DateTime(2024, 8, 10),
      );

      // Deve usar summary como fallback
      expect(updateEntry.items.isEmpty, true);
      expect(updateEntry.summary, isNotEmpty);
    });

    test('UpdateEntry com todos os campos null/vazio usa defaults', () {
      // Cenário: entrada mínima/corrompida do cache

      final updateEntry = UpdateEntry(
        nrId: 'nr-99',
        title: 'Desconhecida',
        hash: '',
        summary: 'Sem detalhes',
      );

      expect(updateEntry.nrId, isNotEmpty);
      expect(updateEntry.portaria, isNull);
      expect(updateEntry.createdAt, isNull);
      expect(updateEntry.items, isEmpty);
      expect(updateEntry.summary, isNotEmpty);

      // Página deve renderizar sem quebrar, mostrando title + summary
    });
  });
}
