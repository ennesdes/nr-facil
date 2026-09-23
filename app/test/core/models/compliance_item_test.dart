import 'package:flutter_test/flutter_test.dart';
import 'package:nrfacil/core/models/compliance_item.dart';

void main() {
  group('ComplianceItem', () {
    test('toMap/fromMap round-trip com dados completos', () {
      final original = ComplianceItem(
        nrId: 'nr-05',
        itemNumber: '5.2.1',
        titulo: 'Constituir a CIPA',
        infracao: true,
        gradacao: 'I4',
        tipo: 'S',
        codigoInfracao: '205113-3',
        explicacao: 'Toda organização com empregados regidos pela CLT deve constituir CIPA.',
        responsavel: 'Empregador / RH',
        riskFactors: ['empregados_clt'],
        readerAnchorId: '52-campo-de-aplicação',
      );

      final map = original.toMap();
      final restored = ComplianceItem.fromMap(map);

      expect(restored.nrId, original.nrId);
      expect(restored.itemNumber, original.itemNumber);
      expect(restored.titulo, original.titulo);
      expect(restored.infracao, original.infracao);
      expect(restored.gradacao, original.gradacao);
      expect(restored.tipo, original.tipo);
      expect(restored.codigoInfracao, original.codigoInfracao);
      expect(restored.explicacao, original.explicacao);
      expect(restored.responsavel, original.responsavel);
      expect(restored.riskFactors, original.riskFactors);
      expect(restored.readerAnchorId, original.readerAnchorId);
    });

    test('fromMap com campos opcionais nulos não quebra serialização', () {
      final map = {
        'nr_id': 'nr-06',
        'item_number': '6.5',
        'titulo': 'Item de teste',
        'infracao': false,
        'gradacao': null,
        'tipo': null,
        'codigo_infracao': null,
        'explicacao': 'Explicação do item',
        'responsavel': 'Responsável',
        'risk_factors': ['fator-1'],
        'reader_anchor_id': 'ancora-1',
      };

      final item = ComplianceItem.fromMap(map);

      expect(item.gradacao, isNull);
      expect(item.tipo, isNull);
      expect(item.codigoInfracao, isNull);
      expect(item.titulo, 'Item de teste');
    });

    test('fromMap com campos faltando retorna defaults', () {
      final map = {
        'nr_id': 'nr-05',
        // Faltam vários campos
      };

      final item = ComplianceItem.fromMap(map);

      expect(item.nrId, 'nr-05');
      expect(item.itemNumber, '');
      expect(item.titulo, 'Sem título');
      expect(item.infracao, isFalse);
      expect(item.gradacao, isNull);
      expect(item.explicacao, '');
      expect(item.responsavel, '');
      expect(item.riskFactors, isEmpty);
      expect(item.readerAnchorId, '');
    });

    test('fromMap com map vazio retorna item com defaults', () {
      final item = ComplianceItem.fromMap({});

      expect(item.nrId, 'unknown');
      expect(item.itemNumber, '');
      expect(item.titulo, 'Sem título');
      expect(item.infracao, isFalse);
      expect(item.explicacao, '');
      expect(item.responsavel, '');
      expect(item.riskFactors, isEmpty);
    });

    test('fromMap com risk_factors como List<dynamic> converte corretamente', () {
      final map = {
        'nr_id': 'nr-05',
        'item_number': '5.2.1',
        'titulo': 'Test',
        'infracao': true,
        'explicacao': 'Explicação',
        'responsavel': 'Responsável',
        'risk_factors': ['fator-1', 'fator-2', 'fator-3'],
        'reader_anchor_id': 'ancora',
      };

      final item = ComplianceItem.fromMap(map);

      expect(item.riskFactors, ['fator-1', 'fator-2', 'fator-3']);
      expect(item.riskFactors.length, 3);
    });

    test('fromMap com risk_factors nulo retorna lista vazia', () {
      final map = {
        'nr_id': 'nr-05',
        'item_number': '5.2.1',
        'titulo': 'Test',
        'infracao': true,
        'explicacao': 'Explicação',
        'responsavel': 'Responsável',
        'risk_factors': null,
        'reader_anchor_id': 'ancora',
      };

      final item = ComplianceItem.fromMap(map);

      expect(item.riskFactors, isEmpty);
    });

    test('gradacaoLabel mapeia I1-I4 corretamente', () {
      expect(
        ComplianceItem(
          nrId: 'nr-05',
          itemNumber: '5.2.1',
          titulo: 'Test',
          infracao: true,
          gradacao: 'I1',
          explicacao: '',
          responsavel: '',
          riskFactors: [],
          readerAnchorId: '',
        ).gradacaoLabel,
        'I1 - Leve',
      );

      expect(
        ComplianceItem(
          nrId: 'nr-05',
          itemNumber: '5.2.1',
          titulo: 'Test',
          infracao: true,
          gradacao: 'I4',
          explicacao: '',
          responsavel: '',
          riskFactors: [],
          readerAnchorId: '',
        ).gradacaoLabel,
        'I4 - Gravíssima',
      );
    });

    test('gradacaoLabel retorna null quando gradacao é null', () {
      final item = ComplianceItem(
        nrId: 'nr-05',
        itemNumber: '5.2.1',
        titulo: 'Test',
        infracao: false,
        explicacao: '',
        responsavel: '',
        riskFactors: [],
        readerAnchorId: '',
      );

      expect(item.gradacaoLabel, isNull);
    });

    test('tipoLabel mapeia S e M corretamente', () {
      expect(
        ComplianceItem(
          nrId: 'nr-05',
          itemNumber: '5.2.1',
          titulo: 'Test',
          infracao: true,
          tipo: 'S',
          explicacao: '',
          responsavel: '',
          riskFactors: [],
          readerAnchorId: '',
        ).tipoLabel,
        'Segurança do Trabalho',
      );

      expect(
        ComplianceItem(
          nrId: 'nr-05',
          itemNumber: '5.2.1',
          titulo: 'Test',
          infracao: true,
          tipo: 'M',
          explicacao: '',
          responsavel: '',
          riskFactors: [],
          readerAnchorId: '',
        ).tipoLabel,
        'Medicina do Trabalho',
      );
    });

    test('tipoLabel retorna null quando tipo é null', () {
      final item = ComplianceItem(
        nrId: 'nr-05',
        itemNumber: '5.2.1',
        titulo: 'Test',
        infracao: false,
        explicacao: '',
        responsavel: '',
        riskFactors: [],
        readerAnchorId: '',
      );

      expect(item.tipoLabel, isNull);
    });

    test('toMap/fromMap preserva item com múltiplos riskFactors', () {
      final original = ComplianceItem(
        nrId: 'nr-28',
        itemNumber: '28.1',
        titulo: 'Infrações detectadas',
        infracao: true,
        gradacao: 'I3',
        tipo: 'S',
        codigoInfracao: '123456',
        explicacao: 'Descrição longa',
        responsavel: 'Responsável',
        riskFactors: ['fator-a', 'fator-b', 'fator-c'],
        readerAnchorId: 'ancora-multifator',
      );

      final map = original.toMap();
      final restored = ComplianceItem.fromMap(map);

      expect(restored.riskFactors.length, 3);
      expect(restored.riskFactors, orderedEquals(original.riskFactors));
    });

    test('fromMap com dados malformados lança ComplianceItemParseException', () {
      final map = {
        'nr_id': 123, // Esperado: string
      };

      expect(
        () => ComplianceItem.fromMap(map),
        throwsA(isA<ComplianceItemParseException>()),
      );
    });

    test('toMap preserva tipos e estrutura para re-serialização', () {
      final original = ComplianceItem(
        nrId: 'nr-05',
        itemNumber: '5.2.1, 5.8.1',
        titulo: 'Constituir CIPA',
        infracao: true,
        gradacao: 'I4',
        tipo: 'S',
        codigoInfracao: '205113-3',
        explicacao: 'Explicação detalhada',
        responsavel: 'Empregador',
        riskFactors: ['fator-1'],
        readerAnchorId: 'sec-5-2',
      );

      final map1 = original.toMap();
      final restored = ComplianceItem.fromMap(map1);
      final map2 = restored.toMap();

      expect(map1, map2);
    });
  });

  group('ComplianceItemParseException', () {
    test('toString retorna mensagem formatada', () {
      final exception = ComplianceItemParseException(
        'Erro ao parsear: tipo inválido',
      );

      expect(
        exception.toString(),
        contains('ComplianceItemParseException'),
      );
      expect(
        exception.toString(),
        contains('tipo inválido'),
      );
    });
  });
}
