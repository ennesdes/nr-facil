import 'package:get/get.dart';

import '../../features/ads/services/ads_service.dart';
import '../../features/home/controllers/home_controller.dart';
import '../../features/home/controllers/normas_controller.dart';
import '../../features/search/controllers/search_screen_controller.dart';
import '../controllers/theme_controller.dart';
import '../services/content_service.dart';
import '../services/search_service.dart';
import '../services/storage_service.dart';

/// AppBinding — injeção de dependência global para serviços principais.
///
/// Inicia serviços na sequência correta:
/// 1. GetStorage (inicializa storage local)
/// 2. StorageService (encapsula GetStorage)
/// 3. ContentService (usa StorageService para persist)
///
/// Uso em main():
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await GetStorage.init();
///   runApp(
///     GetMaterialApp(
///       initialBinding: AppBinding(),
///       // ...
///     ),
///   );
/// }
/// ```
class AppBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ThemeController>()) {
      Get.put<ThemeController>(
        ThemeController(),
        permanent: true,
      );
    }

    // StorageService — gerencia GetStorage local
    Get.put<StorageService>(
      StorageService(),
      permanent: true,
    );

    Get.put<AdsService>(
      AdsService(storage: Get.find()),
      permanent: true,
    );

    // ContentService — sincroniza e cache de NRs
    Get.put<ContentService>(
      ContentService(),
      permanent: true,
    );

    // SearchService — busca full-text em chunks
    Get.put<SearchService>(
      SearchService(contentService: Get.find()),
      permanent: true,
    );

    // SearchScreenController — busca full-text na aba Buscar
    Get.put<SearchScreenController>(
      SearchScreenController(searchService: Get.find()),
      permanent: true,
    );

    // HomeController — navegação entre abas Normas/Favoritos/Buscar
    Get.put<HomeController>(
      HomeController(contentService: Get.find()),
      permanent: true,
    );

    Get.put<NormasController>(
      NormasController(contentService: Get.find()),
      permanent: true,
    );
  }
}
