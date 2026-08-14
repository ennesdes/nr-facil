import 'package:get/get.dart';
import 'package:nrfacil/core/services/content_service.dart';
import 'package:nrfacil/features/reader/controllers/nr_reader_controller.dart';

/// Binding para injetar dependências do leitor de NRs.
///
/// Registra:
/// - NRReaderController (lazyPut — criado sob demanda)
class ReaderBinding extends Bindings {
  final String nrId;

  ReaderBinding({required this.nrId});

  @override
  void dependencies() {
    Get.lazyPut<NRReaderController>(
      () => NRReaderController(
        nrId: nrId,
        contentService: Get.find<ContentService>(),
      ),
    );
  }
}
