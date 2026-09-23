import 'dart:async';

import 'package:get/get.dart';
import 'package:nrfacil/core/constants/storage_keys.dart';
import 'package:nrfacil/core/services/content_service.dart';
import 'package:nrfacil/core/services/storage_service.dart';
import 'package:nrfacil/core/utils/user_messages.dart';
import 'package:nrfacil/core/widgets/app_snackbar.dart';
import 'package:nrfacil/features/compliance/compliance_copy.dart';
import 'package:nrfacil/features/compliance/controllers/checklist_controller.dart';
import 'package:nrfacil/features/compliance/controllers/company_profile_controller.dart';
import 'package:nrfacil/core/services/compliance_service.dart';
import 'package:nrfacil/features/compliance/views/company_profile_page.dart';
import 'package:nrfacil/features/search/controllers/search_screen_controller.dart';
import 'package:nrfacil/features/home/views/widgets/forced_update_dialog.dart';

/// Controller para HomePage — gerencia navegação entre abas.
class HomeController extends GetxController {
  static const int tabNormas = 0;
  static const int tabFavoritos = 1;
  static const int tabBuscar = 2;
  static const int tabChecklist = 3;

  HomeController({required this.contentService});

  final ContentService contentService;

  /// Índice da aba selecionada (0 = Normas, 1 = Favoritos, 2 = Buscar)
  final selectedTab = 0.obs;

  Worker? _syncErrorWorker;
  var _initialTabApplied = false;

  @override
  Future<void> onInit() async {
    super.onInit();

    _applyInitialTabIfNeeded();

    // Garante aba correta após ContentService carregar favoritos do storage.
    once(contentService.favoriteIds, (_) => _applyInitialTabIfNeeded());

    _syncErrorWorker = ever<String?>(contentService.lastError, (error) {
      if (error == null) return;
      // Empty state da aba Normas já cobre falha no boot sem cache.
      if (error == UserMessages.noNetworkNoLocal &&
          !contentService.hasManifest) {
        return;
      }
      AppSnackbar.showError(title: 'Sincronização', message: error);
    });

    unawaited(_runStartupSync());
  }

  void _applyInitialTabIfNeeded() {
    if (_initialTabApplied) return;
    _initialTabApplied = true;
    selectedTab.value = contentService.favoriteIds.isEmpty
        ? tabNormas
        : tabFavoritos;
  }

  String get tabTitle {
    switch (selectedTab.value) {
      case tabNormas:
        return 'Normas';
      case tabFavoritos:
        return 'Favoritos';
      case tabBuscar:
        return 'Buscar';
      case tabChecklist:
        return ComplianceCopy.screenTitle;
      default:
        return 'NR Fácil';
    }
  }

  bool get showContinuarLeitura => false;

  /// Abre a aba Buscar com termo pré-preenchido para busca full-text.
  void openSearchTab(String query) {
    selectTab(tabBuscar);
    if (!Get.isRegistered<SearchScreenController>()) return;
    unawaited(Get.find<SearchScreenController>().openWithQuery(query));
  }

  static const _prefetchFavoritesDelay = Duration(seconds: 2);

  Future<void> _runStartupSync() async {
    final ok = await contentService.syncMetadata();
    if (!ok) return;

    await _checkForcedUpdate();

    // Prefetch de favoritas só depois da UI estabilizar — boot leve na 1ª abertura.
    unawaited(
      Future<void>.delayed(_prefetchFavoritesDelay, () async {
        if (!isClosed) {
          await contentService.prefetchFavorites();
        }
      }),
    );
  }

  void _ensureSearchIndicesWhenNeeded(int tabIndex) {
    if (tabIndex != tabBuscar) return;
    unawaited(contentService.syncSearchIndices());
  }

  @override
  void onClose() {
    _syncErrorWorker?.dispose();
    super.onClose();
  }

  Future<void> _checkForcedUpdate() async {
    try {
      final updateRequired = await contentService.forcedUpdateRequired;
      if (updateRequired) {
        Get.dialog(const ForcedUpdateDialog(), barrierDismissible: false);
      }
    } catch (_) {
      // Falha ao verificar versão não deve bloquear o app
    }
  }

  /// Mudar aba selecionada.
  void selectTab(int index) {
    // Lógica especial para aba de Checklist
    if (index == tabChecklist) {
      _handleChecklistTabSelection();
      return;
    }

    selectedTab.value = index;
    _ensureSearchIndicesWhenNeeded(index);
  }

  /// Lidar com seleção da aba Checklist.
  /// Se não há perfil salvo, navega para tela de perfil.
  void _handleChecklistTabSelection() {
    final storageService = Get.find<StorageService>();
    final hasProfile =
        storageService.read(StorageKeys.companyProfile) != null;

    if (!hasProfile) {
      // Navegar para tela de perfil
      _navigateToCompanyProfile();
    } else {
      // Mostrar checklist
      selectedTab.value = tabChecklist;
    }
  }

  /// Navegar para tela de perfil da empresa.
  /// Ao voltar, se um perfil foi salvo nesse meio-tempo, troca para a aba
  /// Checklist (já recarregado); se o usuário cancelou (nenhum perfil salvo),
  /// permanece na aba anterior.
  void _navigateToCompanyProfile() {
    unawaited(
      Future.microtask(() async {
        CompanyProfileController.ensureRegistered();
        await Get.to(() => const CompanyProfilePage());

        final storageService = Get.find<StorageService>();
        final profileSaved =
            storageService.read(StorageKeys.companyProfile) != null;
        if (!profileSaved) return;

        if (Get.isRegistered<ChecklistController>()) {
          await Get.find<ChecklistController>().reload();
        } else {
          Get.put(
            ChecklistController(
              storageService: storageService,
              complianceService: Get.find<ComplianceService>(),
            ),
          );
        }
        selectedTab.value = tabChecklist;
      }),
    );
  }
}
