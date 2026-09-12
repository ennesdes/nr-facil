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

  var syncSearchIndicesCallCount = 0;
  var prefetchFavoritesCallCount = 0;

  @override
  Future<bool> get forcedUpdateRequired async => _forcedUpdateRequired;

  @override
  Future<bool> sync() async => _syncResult;

  @override
  Future<bool> syncMetadata() async => _syncResult;

  @override
  Future<void> syncSearchIndices() async {
    syncSearchIndicesCallCount++;
  }

  @override
  Future<void> prefetchFavorites() async {
    prefetchFavoritesCallCount++;
  }

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
      homeController = HomeController(contentService: fakeContentService);
    });

    tearDown(() {
      Get.reset();
    });

    test('Inicializa com aba Normas quando não há favoritos', () async {
      fakeContentService.favoriteIds.clear();
      fakeContentService._forcedUpdateRequired = false;

      await homeController.onInit();

      expect(homeController.selectedTab.value, HomeController.tabNormas);
    });

    test('Inicializa com aba Favoritos quando há favoritos', () async {
      fakeContentService.favoriteIds.assignAll(['nr-06', 'nr-10']);
      fakeContentService._forcedUpdateRequired = false;

      await homeController.onInit();

      expect(homeController.selectedTab.value, HomeController.tabFavoritos);
    });

    test('_checkForcedUpdate com forcedUpdateRequired == true não deve lançar erro', () async {
      fakeContentService.favoriteIds.clear();
      fakeContentService._forcedUpdateRequired = true;

      await homeController.onInit();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(homeController.selectedTab.value, HomeController.tabNormas);
    });

    test('_checkForcedUpdate com forcedUpdateRequired == false não deve lançar erro', () async {
      fakeContentService.favoriteIds.clear();
      fakeContentService._forcedUpdateRequired = false;

      await homeController.onInit();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(homeController.selectedTab.value, HomeController.tabNormas);
    });

    test('startup não baixa índices de busca (adiado para aba Buscar)', () async {
      fakeContentService.favoriteIds.clear();
      fakeContentService._forcedUpdateRequired = false;

      await homeController.onInit();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(fakeContentService.syncSearchIndicesCallCount, 0);
    });

    test('selectTab na aba Buscar dispara sync de índices', () async {
      fakeContentService.favoriteIds.clear();
      await homeController.onInit();

      homeController.selectTab(HomeController.tabBuscar);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(fakeContentService.syncSearchIndicesCallCount, 1);
    });

    test('selectTab muda a aba selecionada', () {
      fakeContentService.favoriteIds.clear();
      fakeContentService._forcedUpdateRequired = false;

      homeController.selectTab(HomeController.tabFavoritos);
      expect(homeController.selectedTab.value, HomeController.tabFavoritos);

      homeController.selectTab(HomeController.tabBuscar);
      expect(homeController.selectedTab.value, HomeController.tabBuscar);
    });
  });
}
