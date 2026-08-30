import 'dart:async';

import 'package:get/get.dart';
import 'package:nrfacil/core/services/content_service.dart';
import 'package:nrfacil/core/widgets/app_snackbar.dart';
import 'package:nrfacil/features/home/views/widgets/forced_update_dialog.dart';

/// Controller para HomePage — gerencia navegação entre abas.
///
/// Responsabilidades:
/// - Gerenciar seleção de aba (Favoritos/Todos)
/// - Determinar aba padrão (Favoritos se houver favoritos, senão Todos)
/// - Expor ContentService para as views
/// - Verificar se atualização obrigatória é necessária (min_app_version)
class HomeController extends GetxController {
  final ContentService _contentService;

  HomeController({required this._contentService});

  /// Índice da aba selecionada (0 = Favoritos, 1 = Todos)
  final selectedTab = 0.obs;

  ContentService get contentService => _contentService;

  Worker? _syncErrorWorker;

  @override
  Future<void> onInit() async {
    super.onInit();

    // Determinar aba padrão
    // Se houver favoritos, iniciar em Favoritos (0)
    // Senão, iniciar em Todos (1)
    if (_contentService.favoriteIds.isEmpty) {
      selectedTab.value = 1; // Todos
    } else {
      selectedTab.value = 0; // Favoritos
    }

    // Avisar (sem bloquear) se a sincronização falhar — o app continua
    // usável offline com o cache local existente.
    _syncErrorWorker = ever<String?>(_contentService.lastError, (error) {
      if (error != null) {
        AppSnackbar.showError(title: 'Sincronização', message: error);
      }
    });

    // Sincronizar manifest remoto em background — não bloqueia a UI,
    // que já renderiza com o cache local existente (offline-first).
    // Após sync completar, verificar se atualização obrigatória é necessária.
    unawaited(
      _contentService.sync().then((_) => _checkForcedUpdate()),
    );
  }

  @override
  void onClose() {
    _syncErrorWorker?.dispose();
    super.onClose();
  }

  /// Verificar se atualização obrigatória é necessária e exibir diálogo.
  ///
  /// Chamado após sync() completar (com sucesso ou não).
  /// Se [forcedUpdateRequired] retornar true, exibe um diálogo bloqueante.
  Future<void> _checkForcedUpdate() async {
    try {
      final updateRequired = await _contentService.forcedUpdateRequired;
      if (updateRequired) {
        // Exibir diálogo bloqueante não dispensável
        Get.dialog(
          const ForcedUpdateDialog(),
          barrierDismissible: false,
        );
      }
    } catch (e) {
      // Falha ao verificar versão não deve bloquear o app
      // Logar aviso e continuar
    }
  }

  /// Mudar aba selecionada.
  void selectTab(int index) {
    selectedTab.value = index;
  }
}
