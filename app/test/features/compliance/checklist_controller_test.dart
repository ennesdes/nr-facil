import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nrfacil/core/constants/storage_keys.dart';
import 'package:nrfacil/core/models/company_profile.dart';
import 'package:nrfacil/core/models/compliance_item.dart';
import 'package:nrfacil/core/services/compliance_service.dart';
import 'package:nrfacil/features/compliance/controllers/checklist_controller.dart';

import 'fakes.dart';

void main() {
  setUpAll(() {
    // Habilitar teste mode do GetX para evitar erros de navegação
    Get.testMode = true;
  });

  group('ChecklistController', () {
    late FakeStorageService fakeStorageService;
    late FakeComplianceService fakeComplianceService;

    setUp(() {
      fakeStorageService = FakeStorageService();
      fakeStorageService.onInit();

      // Criar dataset com itens de teste
      final mockDataset = ComplianceDataset(
        atualizado_em: '21/09/2026',
        aviso: 'Aviso de teste',
        riskFactors: [
          RiskFactor(id: 'altura', label: 'Trabalho em altura'),
          RiskFactor(
            id: 'espaço-confinado',
            label: 'Espaço confinado',
          ),
          RiskFactor(id: 'químicos', label: 'Produtos químicos'),
        ],
        items: [
          ComplianceItem(
            nrId: 'nr-35',
            itemNumber: '35.2.1',
            titulo: 'EPIs para trabalho em altura',
            infracao: true,
            gradacao: 'I4',
            tipo: 'S',
            codigoInfracao: '123456',
            explicacao: 'Usar EPIs em trabalho em altura',
            responsavel: 'Empregador',
            riskFactors: ['altura'],
            readerAnchorId: 'sec-35-2',
          ),
          ComplianceItem(
            nrId: 'nr-33',
            itemNumber: '33.1.1',
            titulo: 'Sinalização de espaço confinado',
            infracao: true,
            gradacao: 'I3',
            tipo: 'S',
            codigoInfracao: '654321',
            explicacao: 'Sinalizar entrada de espaço confinado',
            responsavel: 'Empregador',
            riskFactors: ['espaço-confinado'],
            readerAnchorId: 'sec-33-1',
          ),
          ComplianceItem(
            nrId: 'nr-15',
            itemNumber: '15.8.2',
            titulo: 'Uso de EPIs químicos',
            infracao: true,
            gradacao: 'I2',
            tipo: 'S',
            codigoInfracao: '789012',
            explicacao: 'Usar EPIs ao manusear produtos químicos',
            responsavel: 'Empregador',
            riskFactors: ['químicos'],
            readerAnchorId: 'sec-15-8',
          ),
          ComplianceItem(
            nrId: 'nr-35',
            itemNumber: '35.2.2',
            titulo: 'Treinamento em altura',
            infracao: true,
            gradacao: 'I3',
            tipo: 'S',
            codigoInfracao: '111111',
            explicacao: 'Treinar trabalhadores em altura',
            responsavel: 'Empregador',
            riskFactors: ['altura'],
            readerAnchorId: 'sec-35-2-2',
          ),
        ],
      );

      fakeComplianceService = FakeComplianceService(
        mockDataset: mockDataset,
      );
      fakeComplianceService.onInit();
    });

    tearDown(() {
      fakeStorageService.clear();
    });

    test('carrega sem perfil retorna erro (loadError)', () async {
      final controller = ChecklistController(
        storageService: fakeStorageService,
        complianceService: fakeComplianceService,
      );

      await controller.onInit();

      expect(controller.loadError.value, isNotNull);
      expect(controller.loadError.value, contains('Perfil'));
      expect(controller.applicableItems, isEmpty);

      controller.onClose();
    });

    test('CA2: carrega itens aplicáveis baseado em riskFactors do perfil', () async {
      // Salvar perfil com um fator de risco
      final profile = CompanyProfile(
        id: 'default',
        porte: 'Até 10 funcionários',
        segmentoId: '',
        riskFactors: ['altura'],
      );
      await fakeStorageService.write(
        StorageKeys.companyProfile,
        profile.toMap(),
      );

      final controller = ChecklistController(
        storageService: fakeStorageService,
        complianceService: fakeComplianceService,
      );

      await controller.onInit();

      expect(controller.isLoading.value, isFalse);
      expect(controller.loadError.value, isNull);
      expect(controller.applicableItems.isNotEmpty, isTrue);

      // Todos os itens retornados devem ter 'altura' em riskFactors
      for (final item in controller.applicableItems) {
        expect(item.riskFactors.contains('altura'), isTrue);
      }

      controller.onClose();
    });

    test('CA2: perfil com múltiplos fatores retorna itens de todos', () async {
      // Salvar perfil com 2 fatores
      final profile = CompanyProfile(
        id: 'default',
        porte: 'Até 10 funcionários',
        segmentoId: '',
        riskFactors: ['altura', 'espaço-confinado'],
      );
      await fakeStorageService.write(
        StorageKeys.companyProfile,
        profile.toMap(),
      );

      final controller = ChecklistController(
        storageService: fakeStorageService,
        complianceService: fakeComplianceService,
      );

      await controller.onInit();

      expect(controller.applicableItems.length, 3); // 2 de altura + 1 de espaço-confinado

      // Cada item deve ter interseção com pelo menos um dos fatores
      for (final item in controller.applicableItems) {
        final hasMatch = item.riskFactors.any(
          (factor) => ['altura', 'espaço-confinado'].contains(factor),
        );
        expect(hasMatch, isTrue);
      }

      controller.onClose();
    });

    test('CA6: perfil sem riskFactors retorna lista vazia', () async {
      // Salvar perfil sem fatores de risco
      final profile = CompanyProfile(
        id: 'default',
        porte: 'Até 10 funcionários',
        segmentoId: '',
        riskFactors: [],
      );
      await fakeStorageService.write(
        StorageKeys.companyProfile,
        profile.toMap(),
      );

      final controller = ChecklistController(
        storageService: fakeStorageService,
        complianceService: fakeComplianceService,
      );

      await controller.onInit();

      // Sem fatores de risco, nenhum item aplicável
      expect(controller.applicableItems, isEmpty);
      expect(controller.loadError.value, isNull); // Mas não é um erro
      expect(controller.isLoading.value, isFalse);

      controller.onClose();
    });

    test('agrupa itens por NR corretamente', () async {
      final profile = CompanyProfile(
        id: 'default',
        porte: 'Até 10 funcionários',
        segmentoId: '',
        riskFactors: ['altura'],
      );
      await fakeStorageService.write(
        StorageKeys.companyProfile,
        profile.toMap(),
      );

      final controller = ChecklistController(
        storageService: fakeStorageService,
        complianceService: fakeComplianceService,
      );

      await controller.onInit();

      expect(controller.itemsByNr.isNotEmpty, isTrue);
      expect(controller.itemsByNr.keys, contains('nr-35'));

      final nr35Items = controller.itemsByNr['nr-35'];
      expect(nr35Items!.length, 2);
      expect(nr35Items.every((item) => item.nrId == 'nr-35'), isTrue);

      controller.onClose();
    });

    test('nrIds retorna lista de NRs em ordem', () async {
      final profile = CompanyProfile(
        id: 'default',
        porte: 'Até 10 funcionários',
        segmentoId: '',
        riskFactors: ['altura', 'espaço-confinado', 'químicos'],
      );
      await fakeStorageService.write(
        StorageKeys.companyProfile,
        profile.toMap(),
      );

      final controller = ChecklistController(
        storageService: fakeStorageService,
        complianceService: fakeComplianceService,
      );

      await controller.onInit();

      final nrIds = controller.nrIds;
      expect(nrIds.isNotEmpty, isTrue);
      expect(nrIds, isA<List<String>>());
      // Verificar que está ordenado
      expect(nrIds, orderedEquals(nrIds..sort()));

      controller.onClose();
    });

    test('CA4: toggleItemChecked alterna estado do item', () async {
      final profile = CompanyProfile(
        id: 'default',
        porte: 'Até 10 funcionários',
        segmentoId: '',
        riskFactors: ['altura'],
      );
      await fakeStorageService.write(
        StorageKeys.companyProfile,
        profile.toMap(),
      );

      final controller = ChecklistController(
        storageService: fakeStorageService,
        complianceService: fakeComplianceService,
      );

      await controller.onInit();

      final item = controller.applicableItems.first;
      expect(controller.isItemChecked(item), isFalse);

      await controller.toggleItemChecked(item);

      expect(controller.isItemChecked(item), isTrue);

      await controller.toggleItemChecked(item);

      expect(controller.isItemChecked(item), isFalse);

      controller.onClose();
    });

    test('CA4: estado verificado persiste no storage', () async {
      final profile = CompanyProfile(
        id: 'default',
        porte: 'Até 10 funcionários',
        segmentoId: '',
        riskFactors: ['altura'],
      );
      await fakeStorageService.write(
        StorageKeys.companyProfile,
        profile.toMap(),
      );

      final controller1 = ChecklistController(
        storageService: fakeStorageService,
        complianceService: fakeComplianceService,
      );

      await controller1.onInit();

      final item = controller1.applicableItems.first;
      await controller1.toggleItemChecked(item);
      expect(controller1.isItemChecked(item), isTrue);

      controller1.onClose();

      // Criar novo controller e verificar que estado persiste
      final controller2 = ChecklistController(
        storageService: fakeStorageService,
        complianceService: fakeComplianceService,
      );

      await controller2.onInit();

      expect(controller2.isItemChecked(item), isTrue);

      controller2.onClose();
    });

    test('checkedCount retorna número de itens verificados', () async {
      final profile = CompanyProfile(
        id: 'default',
        porte: 'Até 10 funcionários',
        segmentoId: '',
        riskFactors: ['altura'],
      );
      await fakeStorageService.write(
        StorageKeys.companyProfile,
        profile.toMap(),
      );

      final controller = ChecklistController(
        storageService: fakeStorageService,
        complianceService: fakeComplianceService,
      );

      await controller.onInit();

      expect(controller.checkedCount, 0);

      await controller.toggleItemChecked(controller.applicableItems[0]);
      expect(controller.checkedCount, 1);

      await controller.toggleItemChecked(controller.applicableItems[1]);
      expect(controller.checkedCount, 2);

      await controller.toggleItemChecked(controller.applicableItems[0]);
      expect(controller.checkedCount, 1);

      controller.onClose();
    });

    test('totalCount retorna número total de itens', () async {
      final profile = CompanyProfile(
        id: 'default',
        porte: 'Até 10 funcionários',
        segmentoId: '',
        riskFactors: ['altura'],
      );
      await fakeStorageService.write(
        StorageKeys.companyProfile,
        profile.toMap(),
      );

      final controller = ChecklistController(
        storageService: fakeStorageService,
        complianceService: fakeComplianceService,
      );

      await controller.onInit();

      expect(controller.totalCount, 2); // 2 itens com 'altura'

      controller.onClose();
    });

    test('completionPercentage calcula percentual correto', () async {
      final profile = CompanyProfile(
        id: 'default',
        porte: 'Até 10 funcionários',
        segmentoId: '',
        riskFactors: ['altura'],
      );
      await fakeStorageService.write(
        StorageKeys.companyProfile,
        profile.toMap(),
      );

      final controller = ChecklistController(
        storageService: fakeStorageService,
        complianceService: fakeComplianceService,
      );

      await controller.onInit();

      expect(controller.completionPercentage, 0);

      await controller.toggleItemChecked(controller.applicableItems[0]);
      expect(controller.completionPercentage, 50); // 1/2 = 50%

      await controller.toggleItemChecked(controller.applicableItems[1]);
      expect(controller.completionPercentage, 100); // 2/2 = 100%

      controller.onClose();
    });

    test('atualizadoEm retorna data do dataset', () async {
      final profile = CompanyProfile(
        id: 'default',
        porte: 'Até 10 funcionários',
        segmentoId: '',
        riskFactors: ['altura'],
      );
      await fakeStorageService.write(
        StorageKeys.companyProfile,
        profile.toMap(),
      );

      final controller = ChecklistController(
        storageService: fakeStorageService,
        complianceService: fakeComplianceService,
      );

      await controller.onInit();

      expect(controller.atualizadoEm, '21/09/2026');

      controller.onClose();
    });

    test('aviso retorna disclaimer do dataset', () async {
      final profile = CompanyProfile(
        id: 'default',
        porte: 'Até 10 funcionários',
        segmentoId: '',
        riskFactors: ['altura'],
      );
      await fakeStorageService.write(
        StorageKeys.companyProfile,
        profile.toMap(),
      );

      final controller = ChecklistController(
        storageService: fakeStorageService,
        complianceService: fakeComplianceService,
      );

      await controller.onInit();

      expect(controller.aviso, 'Aviso de teste');

      controller.onClose();
    });

    test('isLoading é false após carregar com sucesso', () async {
      final profile = CompanyProfile(
        id: 'default',
        porte: 'Até 10 funcionários',
        segmentoId: '',
        riskFactors: ['altura'],
      );
      await fakeStorageService.write(
        StorageKeys.companyProfile,
        profile.toMap(),
      );

      final controller = ChecklistController(
        storageService: fakeStorageService,
        complianceService: fakeComplianceService,
      );

      expect(controller.isLoading.value, isTrue);

      await controller.onInit();

      expect(controller.isLoading.value, isFalse);

      controller.onClose();
    });

    test('múltiplos toggles do mesmo item alternam corretamente', () async {
      final profile = CompanyProfile(
        id: 'default',
        porte: 'Até 10 funcionários',
        segmentoId: '',
        riskFactors: ['altura'],
      );
      await fakeStorageService.write(
        StorageKeys.companyProfile,
        profile.toMap(),
      );

      final controller = ChecklistController(
        storageService: fakeStorageService,
        complianceService: fakeComplianceService,
      );

      await controller.onInit();

      final item = controller.applicableItems.first;

      expect(controller.isItemChecked(item), isFalse);

      // Toggle 1: false → true
      await controller.toggleItemChecked(item);
      expect(controller.isItemChecked(item), isTrue);

      // Toggle 2: true → false
      await controller.toggleItemChecked(item);
      expect(controller.isItemChecked(item), isFalse);

      // Toggle 3: false → true
      await controller.toggleItemChecked(item);
      expect(controller.isItemChecked(item), isTrue);

      // Toggle 4: true → false
      await controller.toggleItemChecked(item);
      expect(controller.isItemChecked(item), isFalse);

      controller.onClose();
    });
  });
}
