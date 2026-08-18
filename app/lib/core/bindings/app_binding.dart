import 'package:get/get.dart';

import '../../features/home/controllers/home_controller.dart';
import '../services/content_service.dart';
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
    // StorageService — gerencia GetStorage local
    Get.put<StorageService>(
      StorageService(),
      permanent: true,
    );

    // ContentService — sincroniza e cache de NRs
    Get.put<ContentService>(
      ContentService(),
      permanent: true,
    );

    // HomeController — navegação entre abas Favoritos/Todos
    Get.put<HomeController>(
      HomeController(contentService: Get.find()),
      permanent: true,
    );
  }
}
