import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nrfacil/core/services/content_service.dart';
import 'package:nrfacil/features/home/controllers/home_controller.dart';

/// Mock simples de ContentService para testes
class FakeContentService implements ContentService {
  @override
  final favoriteIds = <String>[].obs;

  @override
  final lastError = Rxn<String>();

  @override
  final manifest = Rxn();

  @override
  final appMeta = Rxn();

  @override
  final isSyncing = false.obs;

  @override
  final lastSyncedAt = Rxn<DateTime>();

  @override
  final unreadUpdatesCount = 0.obs;

  /// Controlar o resultado de forcedUpdateRequired nos testes
  bool _forcedUpdateRequired = false;

  /// Controlar o resultado de sync nos testes
  final bool _syncResult = true;

  @override
  Future<bool> get forcedUpdateRequired async => _forcedUpdateRequired;

  @override
  Future<bool> sync() async => _syncResult;

  @override
  Future<void> onClose() async {}

  @override
  Future<void> onInit() async {}

  // Não implementar os outros métodos — esse é um fake mínimo
  @override
  noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

void main() {
  group('HomeController', () {
    late FakeContentService fakeContentService;
    late HomeController homeController;

    setUp(() {
      Get.testMode = true;
      fakeContentService = FakeContentService();
      homeController =
          HomeController(contentService: fakeContentService);
    });

    tearDown(() {
      Get.reset();
    });

    test('Inicializa com aba Todos quando não há favoritos', () async {
      // Setup
      fakeContentService.favoriteIds.clear();
      fakeContentService._forcedUpdateRequired = false;

      // Execute
      await homeController.onInit();

      // Verify
      expect(homeController.selectedTab.value, 1); // Todos
    });

    test('Inicializa com aba Favoritos quando há favoritos', () async {
      // Setup
      fakeContentService.favoriteIds.assignAll(['nr-06', 'nr-10']);
      fakeContentService._forcedUpdateRequired = false;

      // Execute
      await homeController.onInit();

      // Verify
      expect(homeController.selectedTab.value, 0); // Favoritos
    });

    test('_checkForcedUpdate com forcedUpdateRequired == true não deve lançar erro',
        () async {
      // Setup
      fakeContentService.favoriteIds.clear();
      fakeContentService._forcedUpdateRequired = true;

      // Execute: onInit chama _checkForcedUpdate (via unawaited após sync)
      // Deve completar sem erro mesmo com forcedUpdateRequired == true
      await homeController.onInit();

      // Esperar um pouco para a corrotina completar
      await Future.delayed(const Duration(milliseconds: 100));

      // Verify: não deve lançar erro
      expect(homeController.selectedTab.value, 1);
    });

    test('_checkForcedUpdate com forcedUpdateRequired == false não deve lançar erro',
        () async {
      // Setup
      fakeContentService.favoriteIds.clear();
      fakeContentService._forcedUpdateRequired = false;

      // Execute: onInit chama _checkForcedUpdate (via unawaited após sync)
      // Deve completar sem erro mesmo com forcedUpdateRequired == false
      await homeController.onInit();

      // Esperar um pouco para a corrotina completar
      await Future.delayed(const Duration(milliseconds: 100));

      // Verify: não deve lançar erro
      expect(homeController.selectedTab.value, 1);
    });

    test('selectTab muda a aba selecionada', () {
      // Setup
      fakeContentService.favoriteIds.clear();
      fakeContentService._forcedUpdateRequired = false;

      // Execute
      homeController.selectTab(0);

      // Verify
      expect(homeController.selectedTab.value, 0);

      // Execute
      homeController.selectTab(1);

      // Verify
      expect(homeController.selectedTab.value, 1);
    });
  });
}
