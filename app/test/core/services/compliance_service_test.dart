import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:nrfacil/core/models/compliance_item.dart';
import 'package:nrfacil/core/services/compliance_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _FakePathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String path;
  _FakePathProviderPlatform(this.path);

  @override
  Future<String?> getApplicationDocumentsPath() async => path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final storageDir = await Directory.systemTemp.createTemp(
      'nr_facil_compliance_storage_',
    );
    PathProviderPlatform.instance = _FakePathProviderPlatform(storageDir.path);
    await GetStorage.init();
  });

  group('ComplianceService', () {
    test('carregar compliance.json do bundle com sucesso', () async {
      final service = ComplianceService();
      await service.onInit();

      expect(service.isLoaded.value, isTrue);
      expect(service.loadError.value, isNull);
      expect(service.dataset.items.isNotEmpty, isTrue);
    });

    test('atualizadoEm retorna data do dataset', () async {
      final service = ComplianceService();
      await service.onInit();

      final atualizadoEm = service.atualizadoEm;
      expect(atualizadoEm, isNotEmpty);
      expect(atualizadoEm, contains('/'));
    });

    test('aviso contém texto de disclaimer', () async {
      final service = ComplianceService();
      await service.onInit();

      final aviso = service.aviso;
      expect(aviso, isNotEmpty);
      expect(aviso.toLowerCase(), contains('curado'));
    });

    test('getRiskFactors retorna lista de fatores de risco', () async {
      final service = ComplianceService();
      await service.onInit();

      final factors = service.getRiskFactors();
      expect(factors.isNotEmpty, isTrue);
      expect(factors.map((f) => f.id), contains('empregados_clt'));
    });

    test('getItemsByNr retorna itens de uma NR específica', () async {
      final service = ComplianceService();
      await service.onInit();

      final items = service.getItemsByNr('nr-05');
      expect(items.isNotEmpty, isTrue);
      expect(items.every((item) => item.nrId.toLowerCase() == 'nr-05'), isTrue);
    });

    test('getItemsByNr retorna lista vazia para NR não cadastrada', () async {
      final service = ComplianceService();
      await service.onInit();

      final items = service.getItemsByNr('nr-99');
      expect(items, isEmpty);
    });

    test('getItemsByNr é case-insensitive', () async {
      final service = ComplianceService();
      await service.onInit();

      final items1 = service.getItemsByNr('nr-05');
      final items2 = service.getItemsByNr('NR-05');
      final items3 = service.getItemsByNr('Nr-05');

      expect(items1.length, items2.length);
      expect(items1.length, items3.length);
    });

    test('getApplicableItems com fatores que batem retorna itens', () async {
      final service = ComplianceService();
      await service.onInit();

      final items = service.getApplicableItems('', ['empregados_clt']);
      expect(items.isNotEmpty, isTrue);
      expect(
        items.any((item) => item.riskFactors.contains('empregados_clt')),
        isTrue,
      );
    });

    test(
      'getApplicableItems com fatores vazios retorna lista vazia (CA6)',
      () async {
        final service = ComplianceService();
        await service.onInit();

        final items = service.getApplicableItems('', []);
        expect(items, isEmpty);
      },
    );

    test(
      'getApplicableItems com fator inexistente retorna lista vazia',
      () async {
        final service = ComplianceService();
        await service.onInit();

        final items = service.getApplicableItems('', ['fator-inexistente']);
        expect(items, isEmpty);
      },
    );

    test(
      'getApplicableItems com múltiplos fatores retorna interseção',
      () async {
        final service = ComplianceService();
        await service.onInit();

        final allFactors = service.getRiskFactors();
        final factorIds = allFactors.map((f) => f.id).toList();

        if (factorIds.length >= 2) {
          final items = service.getApplicableItems('', [
            factorIds[0],
            factorIds[1],
          ]);
          // Itens devem ter interseção com pelo menos um dos fatores
          expect(
            items.every(
              (item) =>
                  item.riskFactors.contains(factorIds[0]) ||
                  item.riskFactors.contains(factorIds[1]),
            ),
            isTrue,
          );
        }
      },
    );

    test('getItem por nrId e itemNumber retorna item específico', () async {
      final service = ComplianceService();
      await service.onInit();

      final item = service.getItem('nr-05', '5.2.1, 5.8.1, 5.8.1.1');
      expect(item, isNotNull);
      expect(item!.nrId, 'nr-05');
      expect(item.itemNumber, '5.2.1, 5.8.1, 5.8.1.1');
    });

    test('getItem com nrId/itemNumber inexistente retorna null', () async {
      final service = ComplianceService();
      await service.onInit();

      final item = service.getItem('nr-99', '99.9.9');
      expect(item, isNull);
    });

    test('getItem é case-insensitive para nrId', () async {
      final service = ComplianceService();
      await service.onInit();

      final item1 = service.getItem('nr-05', '5.2.1, 5.8.1, 5.8.1.1');
      final item2 = service.getItem('NR-05', '5.2.1, 5.8.1, 5.8.1.1');

      expect(item1, isNotNull);
      expect(item2, isNotNull);
      expect(item1!.titulo, item2!.titulo);
    });

    test('itemStorageKey gera chave única para item', () {
      final key1 = ComplianceService.itemStorageKey('nr-05', '5.2.1');
      final key2 = ComplianceService.itemStorageKey('nr-05', '5.3.1');
      final key3 = ComplianceService.itemStorageKey('nr-06', '5.2.1');

      expect(key1, isNotEmpty);
      expect(key1, contains('nr-05'));
      expect(key1, contains('5.2.1'));
      expect(key1, isNot(key2));
      expect(key1, isNot(key3));
    });

    test('dataset com estrutura válida carrega sem erros', () async {
      final service = ComplianceService();
      await service.onInit();

      expect(service.dataset.atualizado_em, isNotEmpty);
      expect(service.dataset.riskFactors.isNotEmpty, isTrue);
      expect(service.dataset.items.isNotEmpty, isTrue);
    });

    test('cada item de riskFactors tem id e label', () async {
      final service = ComplianceService();
      await service.onInit();

      for (final factor in service.getRiskFactors()) {
        expect(factor.id, isNotEmpty);
        expect(factor.label, isNotEmpty);
      }
    });

    test('cada item de conformidade tem nrId obrigatório', () async {
      final service = ComplianceService();
      await service.onInit();

      for (final item in service.dataset.items) {
        expect(item.nrId, isNotEmpty);
      }
    });

    test(
      'getApplicableItems agrupa corretamente por riskFactors do perfil',
      () async {
        final service = ComplianceService();
        await service.onInit();

        // Pegar o primeiro fator de risco disponível
        final factors = service.getRiskFactors();
        if (factors.isNotEmpty) {
          final firstFactorId = factors[0].id;
          final items = service.getApplicableItems('', [firstFactorId]);

          // Todos os itens retornados devem ter esse fator
          expect(
            items.every((item) => item.riskFactors.contains(firstFactorId)),
            isTrue,
          );
        }
      },
    );

    test('getSegments retorna os segmentos do dataset real', () async {
      final service = ComplianceService();
      await service.onInit();

      final segments = service.getSegments();
      expect(segments.isNotEmpty, isTrue);
      expect(segments.map((s) => s.id), contains('industria'));
    });

    test('compliance.json tem estrutura mínima válida', () async {
      final service = ComplianceService();
      await service.onInit();

      // Verificar que dataset foi carregado corretamente
      expect(service.dataset.atualizado_em, isNotEmpty);
      expect(service.dataset.riskFactors.isNotEmpty, isTrue);
      expect(service.dataset.items.isNotEmpty, isTrue);

      // Verificar que items têm campos obrigatórios
      for (final item in service.dataset.items) {
        expect(item.nrId.isNotEmpty, isTrue);
        expect(item.itemNumber.isNotEmpty, isTrue);
        expect(item.titulo.isNotEmpty, isTrue);
        expect(item.explicacao.isNotEmpty, isTrue);
        expect(item.responsavel.isNotEmpty, isTrue);
      }
    });
  });

  group('getApplicableItems — segmento + fator de risco (Fase 1)', () {
    late ComplianceService service;

    setUp(() {
      service = ComplianceService();
      service.dataset = ComplianceDataset(
        atualizado_em: '22/09/2026',
        aviso: 'Aviso de teste',
        riskFactors: [
          RiskFactor(id: 'trabalho_em_altura', label: 'Trabalho em altura'),
        ],
        segments: [
          Segment(
            id: 'industria',
            label: 'Indústria',
            nrIdsBase: ['nr-01', 'nr-12'],
          ),
          Segment(id: 'comercio', label: 'Comércio', nrIdsBase: ['nr-01']),
        ],
        items: [
          ComplianceItem(
            nrId: 'nr-01',
            itemNumber: '1.4.1',
            titulo: 'Deveres gerais',
            infracao: true,
            explicacao: '',
            responsavel: '',
            riskFactors: [],
            readerAnchorId: '',
          ),
          ComplianceItem(
            nrId: 'nr-12',
            itemNumber: '12.1.7',
            titulo: 'Proteção em máquinas',
            infracao: true,
            explicacao: '',
            responsavel: '',
            riskFactors: [],
            readerAnchorId: '',
          ),
          ComplianceItem(
            nrId: 'nr-35',
            itemNumber: '35.3.1',
            titulo: 'Trabalho em altura',
            infracao: true,
            explicacao: '',
            responsavel: '',
            riskFactors: ['trabalho_em_altura'],
            readerAnchorId: '',
          ),
        ],
      );
    });

    test('segmento sozinho retorna os itens do nr_ids_base', () {
      final items = service.getApplicableItems('industria', []);

      expect(items.length, 2);
      expect(items.map((i) => i.nrId), containsAll(['nr-01', 'nr-12']));
    });

    test('fator de risco sozinho (sem bater segmento) ainda retorna os itens daquele fator', () {
      final items = service.getApplicableItems('', ['trabalho_em_altura']);

      expect(items.length, 1);
      expect(items.single.nrId, 'nr-35');
    });

    test('item que bate segmento E fator de risco aparece uma vez só (sem duplicar)', () {
      // nr-01 está no segmento "comercio" — soma com o fator de risco, sem duplicar
      final items = service.getApplicableItems('comercio', [
        'trabalho_em_altura',
      ]);

      final nr01Matches = items.where((i) => i.nrId == 'nr-01').length;
      expect(nr01Matches, 1);
      expect(items.map((i) => i.nrId), containsAll(['nr-01', 'nr-35']));
      expect(items.length, 2);
    });

    test('nenhum segmento nem fator de risco selecionado retorna lista vazia (CA6)', () {
      final items = service.getApplicableItems('', []);
      expect(items, isEmpty);
    });

    test('segmentoId inválido (sem correspondência) não quebra e ignora a base de segmento', () {
      final items = service.getApplicableItems('segmento-inexistente', []);
      expect(items, isEmpty);
    });
  });

  group('getApplicableItems — dataset completo (Fase 8)', () {
    late ComplianceService service;

    setUp(() async {
      service = ComplianceService();
      await service.onInit();
    });

    test('dataset tem 32 itens curados', () {
      expect(service.dataset.items.length, 32);
    });

    test('CA5 — itens legados permanecem acessíveis por fator de risco', () {
      final cipa = service.getItem('nr-05', '5.2.1, 5.8.1, 5.8.1.1');
      expect(cipa, isNotNull);

      final items = service.getApplicableItems('', ['empregados_clt']);
      final nrIds = items.map((i) => i.nrId).toSet();
      expect(nrIds, containsAll(['nr-01', 'nr-05', 'nr-07', 'nr-17']));
    });

    void expectUniversalBase(String segmentoId) {
      final items = service.getApplicableItems(segmentoId, []);
      final nrIds = items.map((i) => i.nrId).toSet();
      expect(nrIds, contains('nr-01'));
      expect(nrIds, contains('nr-05'));
      expect(nrIds, contains('nr-07'));
      expect(nrIds, contains('nr-24'));
      expect(
        items.where((i) => i.nrId == 'nr-24').length,
        greaterThanOrEqualTo(2),
      );
    }

    test('cada segmento inclui NRs universais e NR-24 sem fatores', () {
      for (final id in [
        'comercio',
        'industria',
        'construcao_civil',
        'servicos_escritorio',
        'saude',
        'transporte_logistica',
      ]) {
        expectUniversalBase(id);
      }
    });

    test('industria inclui NR-11, NR-12 e NR-15', () {
      final nrIds = service
          .getApplicableItems('industria', [])
          .map((i) => i.nrId)
          .toSet();
      expect(nrIds, containsAll(['nr-11', 'nr-12', 'nr-15']));
    });

    test('construcao_civil inclui NR-18 e NR-35', () {
      final nrIds = service
          .getApplicableItems('construcao_civil', [])
          .map((i) => i.nrId)
          .toSet();
      expect(nrIds, containsAll(['nr-18', 'nr-35']));
    });

    test('saude inclui NR-32', () {
      final nrIds = service
          .getApplicableItems('saude', [])
          .map((i) => i.nrId)
          .toSet();
      expect(nrIds, contains('nr-32'));
    });

    test('transporte_logistica inclui NR-11 e NR-16', () {
      final nrIds = service
          .getApplicableItems('transporte_logistica', [])
          .map((i) => i.nrId)
          .toSet();
      expect(nrIds, containsAll(['nr-11', 'nr-16']));
    });

    test('comercio e servicos_escritorio incluem os três itens de NR-17', () {
      for (final segmento in ['comercio', 'servicos_escritorio']) {
        final nr17 = service
            .getApplicableItems(segmento, [])
            .where((i) => i.nrId == 'nr-17')
            .toList();
        expect(nr17.length, 3);
      }
    });

    test('CA2 — fator trabalho_em_altura soma NR-35 fora do nr_ids_base do segmento', () {
      final items = service.getApplicableItems('servicos_escritorio', [
        'trabalho_em_altura',
      ]);
      expect(items.any((i) => i.nrId == 'nr-35'), isTrue);
    });

    test(
      'CA3 — construcao_civil + trabalho_em_altura não duplica item NR-35',
      () {
        final items = service.getApplicableItems('construcao_civil', [
          'trabalho_em_altura',
        ]);
        final matches3531 = items.where((i) => i.itemNumber == '35.3.1').length;
        expect(matches3531, 1);
      },
    );

    test('cada item tem código, gradação e tipo NR-28', () {
      for (final item in service.dataset.items) {
        expect(item.codigoInfracao, isNotNull);
        expect(item.codigoInfracao!.isNotEmpty, isTrue);
        expect(item.gradacao, isNotNull);
        expect(item.tipo, isNotNull);
      }
    });
  });

  group('RiskFactor', () {
    test('toMap/fromMap round-trip', () {
      final factor = RiskFactor(id: 'test-factor', label: 'Test Factor Label');

      final map = factor.toMap();
      final restored = RiskFactor.fromMap(map);

      expect(restored.id, factor.id);
      expect(restored.label, factor.label);
    });

    test('fromMap com dados faltando retorna defaults', () {
      final factor = RiskFactor.fromMap({});

      expect(factor.id, isEmpty);
      expect(factor.label, isEmpty);
    });
  });

  group('ComplianceDataset', () {
    test('fromMap com dados completos carrega corretamente', () {
      final map = {
        'atualizado_em': '21/09/2026',
        'aviso': 'Conteúdo curado',
        'risk_factors': [
          {'id': 'fator-1', 'label': 'Fator 1'},
        ],
        'items': [
          {
            'nr_id': 'nr-05',
            'item_number': '5.2.1',
            'titulo': 'Test',
            'infracao': true,
            'explicacao': 'Explicação',
            'responsavel': 'Responsável',
            'risk_factors': ['fator-1'],
            'reader_anchor_id': 'sec-5-2',
          },
        ],
      };

      final dataset = ComplianceDataset.fromMap(map);

      expect(dataset.atualizado_em, '21/09/2026');
      expect(dataset.aviso, 'Conteúdo curado');
      expect(dataset.riskFactors.length, 1);
      expect(dataset.items.length, 1);
    });

    test('fromMap com dados faltando usa defaults', () {
      final dataset = ComplianceDataset.fromMap({});

      expect(dataset.atualizado_em, 'desconhecida');
      expect(dataset.aviso, isEmpty);
      expect(dataset.riskFactors, isEmpty);
      expect(dataset.items, isEmpty);
    });

    test('toMap/fromMap round-trip', () {
      final original = ComplianceDataset(
        atualizado_em: '21/09/2026',
        aviso: 'Aviso de teste',
        riskFactors: [RiskFactor(id: 'fator-1', label: 'Fator 1')],
        items: [],
      );

      final map = original.toMap();
      final restored = ComplianceDataset.fromMap(map);

      expect(restored.atualizado_em, original.atualizado_em);
      expect(restored.aviso, original.aviso);
      expect(restored.riskFactors.length, original.riskFactors.length);
      expect(restored.items.length, original.items.length);
    });
  });
}
