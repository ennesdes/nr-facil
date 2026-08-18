import 'package:get/get.dart';
import 'package:nrfacil/core/services/content_service.dart';

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
  }

  /// Mudar aba selecionada.
  void selectTab(int index) {
    selectedTab.value = index;
  }
}
