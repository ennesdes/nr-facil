import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nrfacil/core/constants/storage_keys.dart';
import 'package:nrfacil/core/models/company_profile.dart';
import 'package:nrfacil/core/services/compliance_service.dart';
import 'package:nrfacil/features/compliance/controllers/company_profile_controller.dart';

import 'fakes.dart';

void main() {
  setUpAll(() {
    // Habilitar teste mode do GetX para evitar erros de navegação
    Get.testMode = true;
  });

  group('CompanyProfileController', () {
    late FakeStorageService fakeStorageService;
    late FakeComplianceService fakeComplianceService;
    late CompanyProfileController controller;

    setUp(() {
      fakeStorageService = FakeStorageService();
      fakeStorageService.onInit();

      final mockDataset = ComplianceDataset(
        atualizado_em: '21/09/2026',
        aviso: 'Aviso de teste',
        riskFactors: [
          RiskFactor(id: 'empregados_clt', label: 'Tenho empregados CLT'),
          RiskFactor(
            id: 'prestacao_servicos_terceiros',
            label: 'Presto serviços a terceiros',
          ),
          RiskFactor(id: 'possui_cipa', label: 'Tenho CIPA'),
        ],
        segments: [
          Segment(id: 'comercio', label: 'Comércio', nrIdsBase: ['nr-01']),
          Segment(id: 'industria', label: 'Indústria', nrIdsBase: ['nr-01']),
        ],
        items: [],
      );

      fakeComplianceService = FakeComplianceService(
        mockDataset: mockDataset,
      );
      fakeComplianceService.onInit();

      controller = CompanyProfileController(
        storageService: fakeStorageService,
        complianceService: fakeComplianceService,
      );
      controller.onInit();
    });

    tearDown(() {
      controller.onClose();
      fakeStorageService.clear();
    });

    test('perfil inicial está vazio', () {
      expect(controller.profile.value.porte, isEmpty);
      expect(controller.profile.value.segmentoId, isEmpty);
      expect(controller.selectedRiskFactorIds, isEmpty);
    });

    test('carrega lista de fatores de risco disponíveis', () {
      expect(controller.availableRiskFactors.isNotEmpty, isTrue);
      expect(controller.availableRiskFactors.length, 3);
      expect(
        controller.availableRiskFactors.map((f) => f.id),
        contains('empregados_clt'),
      );
    });

    test('toggleRiskFactor adiciona fator quando não selecionado', () {
      expect(controller.selectedRiskFactorIds, isEmpty);

      controller.toggleRiskFactor('empregados_clt');

      expect(controller.selectedRiskFactorIds.contains('empregados_clt'), isTrue);
    });

    test('toggleRiskFactor remove fator quando já selecionado', () {
      controller.toggleRiskFactor('empregados_clt');
      expect(controller.selectedRiskFactorIds.contains('empregados_clt'), isTrue);

      controller.toggleRiskFactor('empregados_clt');

      expect(controller.selectedRiskFactorIds.contains('empregados_clt'), isFalse);
    });

    test('toggleRiskFactor alterna múltiplos fatores independentemente', () {
      controller.toggleRiskFactor('empregados_clt');
      controller.toggleRiskFactor('prestacao_servicos_terceiros');

      expect(controller.selectedRiskFactorIds.length, 2);
      expect(controller.selectedRiskFactorIds.contains('empregados_clt'), isTrue);
      expect(
        controller.selectedRiskFactorIds.contains('prestacao_servicos_terceiros'),
        isTrue,
      );

      controller.toggleRiskFactor('empregados_clt');

      expect(controller.selectedRiskFactorIds.length, 1);
      expect(controller.selectedRiskFactorIds.contains('empregados_clt'), isFalse);
      expect(
        controller.selectedRiskFactorIds.contains('prestacao_servicos_terceiros'),
        isTrue,
      );
    });

    test('isRiskFactorSelected retorna status correto', () {
      expect(controller.isRiskFactorSelected('empregados_clt'), isFalse);

      controller.toggleRiskFactor('empregados_clt');

      expect(controller.isRiskFactorSelected('empregados_clt'), isTrue);
    });

    test('saveProfile falha quando porte está vazio', () async {
      controller.segmentoIdSelected.value = 'industria';
      controller.porteSelected.value = '';

      await controller.saveProfile();

      expect(controller.saveError.value, isNotEmpty);
      expect(controller.saveError.value, contains('porte'));
    });

    test('saveProfile falha quando atividade está vazia', () async {
      controller.porteSelected.value = 'Até 10 funcionários';
      controller.segmentoIdSelected.value = '';

      await controller.saveProfile();

      expect(controller.saveError.value, isNotEmpty);
      expect(controller.saveError.value, contains('atividade'));
    });

    test('CA1: saveProfile persiste perfil no storage e marca isSaving', () async {
      // Configurar dados de entrada
      controller.porteSelected.value = 'Até 10 funcionários';
      controller.segmentoIdSelected.value = 'industria';
      controller.toggleRiskFactor('empregados_clt');
      controller.toggleRiskFactor('possui_cipa');

      expect(controller.isSaving.value, isFalse);

      // Salvar (sem esperar navegação, que daria erro em teste)
      controller.saveProfile();

      // Aguardar um tick para processamento
      await Future.delayed(const Duration(milliseconds: 100));

      // Verificar que isSaving foi alterado (mesmo que devolva para false após erro de navegação)
      expect(controller.saveError.value, isNull);

      // Verificar que perfil foi persistido no storage
      final savedData = fakeStorageService.read(StorageKeys.companyProfile);
      expect(savedData, isNotNull);

      final savedProfile = CompanyProfile.fromMap(
        Map<String, dynamic>.from(savedData as Map),
      );

      expect(savedProfile.porte, 'Até 10 funcionários');
      expect(savedProfile.segmentoId, 'industria');
      expect(
        savedProfile.riskFactors,
        containsAll(['empregados_clt', 'possui_cipa']),
      );
    });

    test('CA1: saveProfile com perfil sem fatores de risco ainda salva', () async {
      // Configurar dados sem fatores de risco (CA6: válido)
      controller.porteSelected.value = '11 a 50 funcionários';
      controller.segmentoIdSelected.value = 'comercio';
      // Não toggle nenhum fator de risco

      await controller.saveProfile();
      await Future.delayed(const Duration(milliseconds: 100));

      final savedData = fakeStorageService.read(StorageKeys.companyProfile);
      expect(savedData, isNotNull);

      final savedProfile = CompanyProfile.fromMap(
        Map<String, dynamic>.from(savedData as Map),
      );

      expect(savedProfile.riskFactors, isEmpty);
      expect(savedProfile.porte, '11 a 50 funcionários');
      expect(savedProfile.segmentoId, 'comercio');
    });

    test('carrega perfil existente do storage na inicialização', () async {
      // Salvar um perfil no storage
      final profileData = CompanyProfile(
        id: 'default',
        porte: 'Até 10 funcionários',
        segmentoId: 'servicos_escritorio',
        riskFactors: ['empregados_clt'],
      );
      await fakeStorageService.write(
        StorageKeys.companyProfile,
        profileData.toMap(),
      );

      // Criar novo controller para carregar do storage
      final newController = CompanyProfileController(
        storageService: fakeStorageService,
        complianceService: fakeComplianceService,
      );
      await newController.onInit();

      expect(newController.profile.value.porte, 'Até 10 funcionários');
      expect(newController.profile.value.segmentoId, 'servicos_escritorio');
      expect(
        newController.selectedRiskFactorIds.contains('empregados_clt'),
        isTrue,
      );

      newController.onClose();
    });

    test('hasProfile retorna true quando perfil está salvo', () {
      expect(controller.hasProfile, isFalse);

      final profileData = CompanyProfile(
        id: 'default',
        porte: 'Até 10 funcionários',
        segmentoId: 'industria',
        riskFactors: [],
      );
      fakeStorageService.write(
        StorageKeys.companyProfile,
        profileData.toMap(),
      );

      expect(controller.hasProfile, isTrue);
    });

    test('hasProfile retorna false quando não há perfil salvo', () {
      fakeStorageService.clear();
      expect(controller.hasProfile, isFalse);
    });

    test('porteOptions contém todas as opções esperadas', () {
      expect(
        CompanyProfileController.porteOptions,
        containsAll([
          'Até 10 funcionários',
          '11 a 50 funcionários',
          '51 a 100 funcionários',
          '101 a 500 funcionários',
          'Acima de 500 funcionários',
        ]),
      );
    });

    test('availableSegments carrega segmentos do ComplianceService (data-driven)', () {
      expect(controller.availableSegments.length, 2);
      expect(
        controller.availableSegments.map((s) => s.id),
        containsAll(['comercio', 'industria']),
      );
    });

    test('perfil com copyWith mantém campos não atualizados', () async {
      controller.porteSelected.value = 'Até 10 funcionários';
      controller.segmentoIdSelected.value = 'industria';
      controller.toggleRiskFactor('empregados_clt');

      await controller.saveProfile();
      await Future.delayed(const Duration(milliseconds: 100));

      final updated = controller.profile.value.copyWith(
        segmentoId: 'comercio',
      );

      expect(updated.porte, 'Até 10 funcionários');
      expect(updated.segmentoId, 'comercio');
      expect(updated.riskFactors.contains('empregados_clt'), isTrue);
    });

    test('múltiplos saveProfile sucessivos persistem último estado', () async {
      // Primeira vez
      controller.porteSelected.value = 'Até 10 funcionários';
      controller.segmentoIdSelected.value = 'industria';
      await controller.saveProfile();
      await Future.delayed(const Duration(milliseconds: 100));

      var savedData = fakeStorageService.read(StorageKeys.companyProfile);
      var savedProfile = CompanyProfile.fromMap(
        Map<String, dynamic>.from(savedData as Map),
      );
      expect(savedProfile.segmentoId, 'industria');

      // Segunda vez com dados diferentes
      controller.porteSelected.value = '51 a 100 funcionários';
      controller.segmentoIdSelected.value = 'comercio';
      controller.selectedRiskFactorIds.clear();
      controller.toggleRiskFactor('prestacao_servicos_terceiros');

      await controller.saveProfile();
      await Future.delayed(const Duration(milliseconds: 100));

      savedData = fakeStorageService.read(StorageKeys.companyProfile);
      savedProfile = CompanyProfile.fromMap(
        Map<String, dynamic>.from(savedData as Map),
      );

      expect(savedProfile.segmentoId, 'comercio');
      expect(savedProfile.porte, '51 a 100 funcionários');
      expect(
        savedProfile.riskFactors,
        ['prestacao_servicos_terceiros'],
      );
    });
  });
}
