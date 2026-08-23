import 'package:get/get.dart';
import 'package:nrfacil/core/services/content_service.dart';
import 'package:nrfacil/core/widgets/app_snackbar.dart';

/// Controller para HomePage — gerencia navegação entre abas.
///
/// Responsabilidades:
/// - Gerenciar seleção de aba (Favoritos/Todos)
/// - Determinar aba padrão (Favoritos se houver favoritos, senão Todos)
/// - Expor ContentService para as views
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
    _contentService.sync();
  }

  @override
  void onClose() {
    _syncErrorWorker?.dispose();
    super.onClose();
  }

  /// Mudar aba selecionada.
  void selectTab(int index) {
    selectedTab.value = index;
  }
}
