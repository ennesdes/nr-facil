import 'package:get/get.dart';
import 'package:nrfacil/core/services/content_service.dart';
import 'package:nrfacil/features/updates/controllers/updates_controller.dart';

/// Binding para injetar dependências da tela de Atualizações.
///
/// Registra:
/// - UpdatesController (lazyPut — criado sob demanda)
class UpdatesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UpdatesController>(
      () => UpdatesController(
        contentService: Get.find<ContentService>(),
      ),
    );
  }
}
