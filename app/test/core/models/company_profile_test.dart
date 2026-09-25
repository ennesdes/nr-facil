import 'package:flutter_test/flutter_test.dart';
import 'package:nrfacil/core/models/company_profile.dart';

void main() {
  group('CompanyProfile', () {
    test('factory empty cria perfil vazio com id "default"', () {
      final profile = CompanyProfile.empty();

      expect(profile.id, 'default');
      expect(profile.porte, isEmpty);
      expect(profile.segmentoId, isEmpty);
      expect(profile.riskFactors, isEmpty);
    });

    test('isComplete retorna false quando porte está vazio', () {
      final profile = CompanyProfile(
        id: 'default',
        porte: '',
        segmentoId: 'Indústria',
        riskFactors: ['fator-1'],
      );

      expect(profile.isComplete, isFalse);
    });

    test('isComplete retorna false quando segmentoId está vazio', () {
      final profile = CompanyProfile(
        id: 'default',
        porte: 'Até 10 funcionários',
        segmentoId: '',
        riskFactors: ['fator-1'],
      );

      expect(profile.isComplete, isFalse);
    });

    test(
      'isComplete retorna true quando porte e segmentoId estão preenchidos',
      () {
        final profile = CompanyProfile(
          id: 'default',
          porte: 'Até 10 funcionários',
          segmentoId: 'Indústria',
          riskFactors: ['fator-1', 'fator-2'],
        );

        expect(profile.isComplete, isTrue);
      },
    );

    test('isComplete retorna true mesmo sem fatores de risco', () {
      final profile = CompanyProfile(
        id: 'default',
        porte: 'Até 10 funcionários',
        segmentoId: 'Indústria',
        riskFactors: [],
      );

      expect(profile.isComplete, isTrue);
    });

    test('toMap/fromMap round-trip com dados completos', () {
      final original = CompanyProfile(
        id: 'default',
        porte: '11 a 50 funcionários',
        segmentoId: 'Comércio',
        riskFactors: ['fator-a', 'fator-b'],
      );

      final map = original.toMap();
      final restored = CompanyProfile.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.porte, original.porte);
      expect(restored.segmentoId, original.segmentoId);
      expect(restored.riskFactors, original.riskFactors);
    });

    test('fromMap com dados faltando retorna defaults', () {
      final map = {
        'id': 'default',
        // Faltam porte, segmento_id, risk_factors
      };

      final profile = CompanyProfile.fromMap(map);

      expect(profile.id, 'default');
      expect(profile.porte, isEmpty);
      expect(profile.segmentoId, isEmpty);
      expect(profile.riskFactors, isEmpty);
    });

    test('fromMap com risk_factors nulo retorna lista vazia', () {
      final map = {
        'id': 'default',
        'porte': 'Até 10 funcionários',
        'segmento_id': 'Serviços',
        'risk_factors': null,
      };

      final profile = CompanyProfile.fromMap(map);

      expect(profile.riskFactors, isEmpty);
    });

    test(
      'fromMap com risk_factors como List<dynamic> converte corretamente',
      () {
        final map = {
          'id': 'default',
          'porte': 'Até 10 funcionários',
          'segmento_id': 'Serviços',
          'risk_factors': ['fator-1', 'fator-2', 'fator-3'],
        };

        final profile = CompanyProfile.fromMap(map);

        expect(profile.riskFactors, ['fator-1', 'fator-2', 'fator-3']);
        expect(profile.riskFactors.length, 3);
      },
    );

    test('toMap/fromMap preserva ordem de fatores de risco', () {
      final original = CompanyProfile(
        id: 'default',
        porte: 'Até 10 funcionários',
        segmentoId: 'Indústria',
        riskFactors: ['altura', 'espaço-confinado', 'químicos'],
      );

      final map = original.toMap();
      final restored = CompanyProfile.fromMap(map);

      expect(restored.riskFactors, orderedEquals(original.riskFactors));
    });

    test('copyWith com alguns campos atualiza corretamente', () {
      final original = CompanyProfile(
        id: 'default',
        porte: 'Até 10 funcionários',
        segmentoId: 'Comércio',
        riskFactors: ['fator-1'],
      );

      final updated = original.copyWith(
        segmentoId: 'Indústria',
        riskFactors: ['fator-1', 'fator-2'],
      );

      expect(updated.id, original.id);
      expect(updated.porte, original.porte);
      expect(updated.segmentoId, 'Indústria');
      expect(updated.riskFactors, ['fator-1', 'fator-2']);
    });

    test('copyWith com id null mantém id original', () {
      final original = CompanyProfile(
        id: 'default',
        porte: 'Até 10 funcionários',
        segmentoId: 'Comércio',
        riskFactors: [],
      );

      final updated = original.copyWith(id: null);

      expect(updated.id, original.id);
    });

    test('copyWith com riskFactors vazio limpa a lista', () {
      final original = CompanyProfile(
        id: 'default',
        porte: 'Até 10 funcionários',
        segmentoId: 'Comércio',
        riskFactors: ['fator-1', 'fator-2'],
      );

      final updated = original.copyWith(riskFactors: []);

      expect(updated.riskFactors, isEmpty);
    });

    test('fromMap com map vazio retorna perfil vazio', () {
      final profile = CompanyProfile.fromMap({});

      expect(profile.id, 'default');
      expect(profile.porte, isEmpty);
      expect(profile.segmentoId, isEmpty);
      expect(profile.riskFactors, isEmpty);
    });

    test(
      'fromMap com dados malformados lança CompanyProfileParseException',
      () {
        final map = {
          'id': 123, // Esperado: string
        };

        expect(
          () => CompanyProfile.fromMap(map),
          throwsA(isA<CompanyProfileParseException>()),
        );
      },
    );

    test('toMap preserva tipos e estrutura para re-serialização', () {
      final original = CompanyProfile(
        id: 'default',
        porte: 'Até 10 funcionários',
        segmentoId: 'Indústria',
        riskFactors: ['fator-a', 'fator-b'],
      );

      final map1 = original.toMap();
      final restored = CompanyProfile.fromMap(map1);
      final map2 = restored.toMap();

      expect(map1, map2);
    });
  });

  group('CompanyProfileParseException', () {
    test('toString retorna mensagem formatada', () {
      final exception = CompanyProfileParseException(
        'Erro ao parsear: campo inválido',
      );

      expect(exception.toString(), contains('CompanyProfileParseException'));
      expect(exception.toString(), contains('campo inválido'));
    });
  });
}
